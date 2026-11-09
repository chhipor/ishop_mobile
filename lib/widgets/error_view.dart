import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../core/config.dart';
import '../data/models/api_error.dart';

class ErrorInfo {
  const ErrorInfo({
    required this.icon,
    required this.title,
    required this.message,
    this.needsLogin = false,
    this.retryable = true,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool needsLogin;
  final bool retryable;

  factory ErrorInfo.from(Object error, {bool publicRequest = false}) {
    if (error is! ApiException) {
      return ErrorInfo(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: 'Unexpected data from the server. ($error)',
      );
    }
    if (publicRequest && (error.statusCode == 401 || error.statusCode == 403)) {
      return ErrorInfo(
        icon: Icons.settings_ethernet,
        title: 'Backend configuration problem',
        message:
            'The gateway rejected a public request (HTTP ${error.statusCode}). '
            'Product endpoints should be reachable without signing in — '
            'check the gateway security configuration.',
      );
    }
    switch (error.kind) {
      case ApiErrorKind.network:
        return ErrorInfo(
          icon: Icons.wifi_off_rounded,
          title: 'Can\'t reach iShop',
          message: '${error.message}\n\nAPI: ${AppConfig.apiBaseUrl}',
        );
      case ApiErrorKind.sessionExpired:
      case ApiErrorKind.unauthorized:
        return const ErrorInfo(
          icon: Icons.lock_clock_outlined,
          title: 'Please sign in again',
          message: 'Your session has expired.',
          needsLogin: true,
          retryable: false,
        );
      case ApiErrorKind.forbidden:
        return const ErrorInfo(
          icon: Icons.block,
          title: 'Access denied',
          message: 'Your account doesn\'t have permission to view this.',
          retryable: false,
        );
      case ApiErrorKind.notFound:
        return ErrorInfo(
          icon: Icons.search_off,
          title: 'Not found',
          message: error.message,
        );
      case ApiErrorKind.server:
        return ErrorInfo(
          icon: Icons.cloud_off_outlined,
          title: 'Server error',
          message: '${error.message} (HTTP ${error.statusCode})',
        );
      case ApiErrorKind.badRequest:
      case ApiErrorKind.conflict:
      case ApiErrorKind.unknown:
        return ErrorInfo(
          icon: Icons.error_outline,
          title: 'Request failed',
          message: error.message,
        );
    }
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.publicRequest = false,
    this.compact = false,
  });

  final Object error;
  final VoidCallback? onRetry;
  final bool publicRequest;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final info = ErrorInfo.from(error, publicRequest: publicRequest);
    final theme = Theme.of(context);

    Widget? action;
    if (info.needsLogin) {
      action = FilledButton.icon(
        onPressed: () {
          final from = GoRouterState.of(context).uri.toString();
          context.go('/login?from=${Uri.encodeComponent(from)}');
        },
        icon: const Icon(Icons.login),
        label: const Text('Sign in'),
      );
    } else if (info.retryable && onRetry != null) {
      action = compact
          ? OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            )
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            );
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.dangerBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(info.icon, color: AppColors.danger, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    info.message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (action != null) ...[const SizedBox(height: 8), action],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.dangerBg,
                shape: BoxShape.circle,
              ),
              child: Icon(info.icon, size: 36, color: AppColors.danger),
            ),
            const SizedBox(height: 18),
            Text(
              info.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              info.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 22), action],
          ],
        ),
      ),
    );
  }
}
