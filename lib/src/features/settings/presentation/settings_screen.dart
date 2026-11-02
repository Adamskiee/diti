import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_notifications/diti_notifications.dart';
import '../../../core/di/app_info_providers.dart';
import '../../../core/di/notification_providers.dart';
import '../../../core/di/tracker_provider.dart';
import 'controllers/settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  late Future<NotificationPermissionStatus> _statusFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _statusFuture = _fetchStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<NotificationPermissionStatus> _fetchStatus() async {
    final status =
        await ref.read(notificationPermissionServiceProvider).checkStatus();
    debugPrint('[SettingsScreen] checkStatus resolved: $status');
    return status;
  }

  void _refresh() {
    setState(() {
      _statusFuture = _fetchStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: _refresh,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Permissions',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<NotificationPermissionStatus>(
            future: _statusFuture,
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
                          Text(status?.notificationsEnabled == true
                              ? 'Enabled'
                              : 'Disabled'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.alarm),
                          const SizedBox(width: 12),
                          const Text('Exact Alarms: '),
                          const Spacer(),
                          Text(status?.exactAlarmsAllowed == true
                              ? 'Allowed'
                              : 'Disallowed'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Activity Tracking',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Continuous Background Tracking'),
              subtitle: const Text(
                'Track active window history (rolling 24 hours) to include app usage when recovering untimed sessions.',
              ),
              value: ref.watch(continuousTrackingEnabledProvider),
              onChanged: (val) {
                ref
                    .read(continuousTrackingEnabledProvider.notifier)
                    .toggle(val);
                final tracker = ref.read(continuousActivityTrackerProvider);
                if (val) {
                  tracker.start();
                } else {
                  tracker.stop();
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text('About Diti',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Version'),
              subtitle: ref.watch(appVersionProvider).when(
                    data: (version) => Text(version),
                    loading: () => const Text('Loading...'),
                    error: (_, __) => const Text('Unknown'),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
