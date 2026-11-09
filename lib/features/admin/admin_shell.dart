import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../state/auth_controller.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  int get _index => location.startsWith('/admin/products') ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    return Theme(
      data: AppTheme.admin(Theme.of(context)),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: Color(0xFF60A5FA)),
                const SizedBox(width: 6),
                Text(
                  _index == 0 ? 'iShop Admin' : 'Products',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Open storefront',
                icon: const Icon(Icons.storefront_outlined),
                onPressed: () => context.go('/'),
              ),
              PopupMenuButton<String>(
                tooltip: 'Account',
                icon: const Icon(Icons.account_circle_outlined),
                onSelected: (value) async {
                  if (value == 'logout') {
                    await context.read<AuthController>().logout();
                    if (context.mounted) {
                      context.go('/');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signed out')),
                      );
                    }
                  }
                },
                itemBuilder: (_) => [
                  if (user != null)
                    PopupMenuItem(
                      enabled: false,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(user.fullName),
                        subtitle: Text(user.email),
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout),
                      title: Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) =>
                context.go(i == 0 ? '/admin' : '/admin/products'),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Products',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
