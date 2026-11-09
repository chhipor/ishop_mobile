import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';

class AccountMenu extends StatelessWidget {
  const AccountMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;

    if (!auth.isLoggedIn || user == null) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: TextButton.icon(
          onPressed: () => context.push('/login'),
          icon: const Icon(Icons.person_outline),
          label: const Text('Login'),
        ),
      );
    }

    return PopupMenuButton<_AccountAction>(
      tooltip: 'Account',
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      onSelected: (action) async {
        switch (action) {
          case _AccountAction.orders:
            context.push('/orders');
          case _AccountAction.admin:
            context.go('/admin');
          case _AccountAction.logout:
            await context.read<AuthController>().logout();
            if (context.mounted) {
              context.go('/');
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Signed out')));
            }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(user.fullName.isEmpty ? user.email : user.fullName),
            subtitle: Text(user.email),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _AccountAction.orders,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.receipt_long_outlined),
            title: Text('My orders'),
          ),
        ),
        if (auth.isAdmin)
          const PopupMenuItem(
            value: _AccountAction.admin,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.dashboard_outlined),
              title: Text('Admin dashboard'),
            ),
          ),
        const PopupMenuItem(
          value: _AccountAction.logout,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Logout'),
          ),
        ),
      ],
    );
  }
}

enum _AccountAction { orders, admin, logout }
