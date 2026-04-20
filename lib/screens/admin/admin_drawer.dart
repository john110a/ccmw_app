import 'package:flutter/material.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Text(
              'Admin Menu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/admin-dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('User Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/user-management');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('System Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/system-settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reports'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reports');
            },
          ),
          // In admin_drawer.dart, add:
          ListTile(
            leading: const Icon(Icons.search, color: Colors.grey),
            title: const Text('Detect Duplicates'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/detect-duplicates');
            },
          ),
          // Add this to your admin drawer items
          ListTile(
            leading: const Icon(Icons.notifications_active, color: Colors.grey),
            title: const Text('Duplicate Alerts'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/duplicate-notifications');
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
