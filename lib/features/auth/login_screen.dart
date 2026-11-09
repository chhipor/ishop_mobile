import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/validators.dart';
import '../../data/models/api_error.dart';
import '../../state/auth_controller.dart';
import '../../widgets/error_view.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _devEmail = 'admin@local.test';
  static const _devPassword = 'Admin@1234!';

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscure = true;
  bool _submitting = false;
  String? _formError;
  Map<String, String> _fieldErrors = const {};
  bool _showExpiredNotice = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    _showExpiredNotice = auth.sessionExpired;
    auth.acknowledgeSessionExpired();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _formError = null;
      _fieldErrors = const {};
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final auth = context.read<AuthController>();
      final from = GoRouterState.of(context).uri.queryParameters['from'];
      await auth.login(_email.text, _password.text);
      if (mounted) context.go(postLoginLocation(auth, from));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.statusCode == 401) {
          _formError = 'Invalid email or password';
        } else if (e.statusCode == 400 && e.fieldErrors.isNotEmpty) {
          _fieldErrors = e.fieldErrors;
          _formError = null;
        } else {
          _formError = ErrorInfo.from(e).message;
        }
      });
      if (e.fieldErrors.isNotEmpty) _formKey.currentState!.validate();
    } catch (e) {
      if (mounted) setState(() => _formError = ErrorInfo.from(e).message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _fillDevCredentials() {
    _email.text = _devEmail;
    _password.text = _devPassword;
    setState(() {
      _formError = null;
      _fieldErrors = const {};
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to store',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.bolt,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Sign in to iShop',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Shop, track your orders, or manage the store',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_showExpiredNotice) ...[
                        const _Banner(
                          icon: Icons.lock_clock_outlined,
                          text:
                              'Your session has expired. Please sign in again.',
                          color: AppColors.warning,
                          background: AppColors.warningBg,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_formError != null) ...[
                        _Banner(
                          icon: Icons.error_outline,
                          text: _formError!,
                          color: AppColors.danger,
                          background: AppColors.dangerBg,
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _email,
                        enabled: !_submitting,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (v) =>
                            _fieldErrors['email'] ?? Validators.email(v),
                        onChanged: (_) {
                          if (_fieldErrors.containsKey('email')) {
                            setState(
                              () =>
                                  _fieldErrors = {..._fieldErrors}
                                    ..remove('email'),
                            );
                          }
                        },
                        onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        focusNode: _passwordFocus,
                        enabled: !_submitting,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? 'Show password'
                                : 'Hide password',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                            _fieldErrors['password'] ?? Validators.password(v),
                        onChanged: (_) {
                          if (_fieldErrors.containsKey('password')) {
                            setState(
                              () =>
                                  _fieldErrors = {..._fieldErrors}
                                    ..remove('password'),
                            );
                          }
                        },
                        onFieldSubmitted: (_) {
                          if (!_submitting) _submit();
                        },
                      ),
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  semanticsLabel: 'Signing in',
                                ),
                              )
                            : const Text('Sign in'),
                      ),
                      const SizedBox(height: 24),
                      _DevHint(
                        email: _devEmail,
                        password: _devPassword,
                        onUse: _submitting ? null : _fillDevCredentials,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevHint extends StatelessWidget {
  const _DevHint({
    required this.email,
    required this.password,
    required this.onUse,
  });

  final String email;
  final String password;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.infoBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Local dev: $email / $password',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.info),
            ),
          ),
          TextButton(onPressed: onUse, child: const Text('Use')),
        ],
      ),
    );
  }
}
