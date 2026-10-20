import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_notifications/diti_notifications.dart';
import '../../../core/di/notification_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionService = ref.watch(notificationPermissionServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Diagnostics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<NotificationPermissionStatus>(
            future: permissionService.checkStatus(),
            builder: (context, snapshot) {
              final status = snapshot.data;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications),
                          const SizedBox(width: 12),
                          const Text('Notifications: '),
                          const Spacer(),
                          Text(status?.notificationsEnabled == true ? 'Enabled' : 'Disabled'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.alarm),
                          const SizedBox(width: 12),
                          const Text('Exact Alarms: '),
                          const Spacer(),
                          Text(status?.exactAlarmsAllowed == true ? 'Allowed' : 'Disallowed'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('About Diti', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              title: Text('Version'),
              subtitle: Text('0.1.0 (Phase 4A)'),
            ),
          ),
        ],
      ),
    );
  }
}
