import 'package:flutter/material.dart';
import '../services/firebase_sync_service.dart';
import 'package:intl/intl.dart';

class FirebaseSyncScreen extends StatefulWidget {
  const FirebaseSyncScreen({super.key});

  @override
  State<FirebaseSyncScreen> createState() => _FirebaseSyncScreenState();
}

class _FirebaseSyncScreenState extends State<FirebaseSyncScreen> {
  bool _isAutoSyncEnabled = false;
  bool _isRealtimeSyncEnabled = true; // Enabled by default
  SyncResult? _lastSyncResult;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkSyncStatus();
  }

  @override
  void dispose() {
    // Don't stop auto-sync on dispose, let it run in background
    super.dispose();
  }

  void _checkSyncStatus() {
    setState(() {
      _isSyncing = FirebaseSyncService.isSyncing;
      _isRealtimeSyncEnabled = FirebaseSyncService.isRealtimeActive;
    });
  }

  Future<void> _manualSync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await FirebaseSyncService.syncData();
      setState(() {
        _lastSyncResult = result;
        _isSyncing = false;
      });

      if (mounted) {
        _showSyncResultDialog(result);
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleAutoSync(bool enabled) {
    setState(() {
      _isAutoSyncEnabled = enabled;
    });

    if (enabled) {
      FirebaseSyncService.startAutoSync(interval: const Duration(minutes: 5));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-sync enabled (every 5 minutes)'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      FirebaseSyncService.stopAutoSync();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-sync disabled'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _toggleRealtimeSync(bool enabled) {
    setState(() {
      _isRealtimeSyncEnabled = enabled;
    });

    if (enabled) {
      FirebaseSyncService.startRealtimeSync();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Realtime sync enabled (instant migration)'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      FirebaseSyncService.stopRealtimeSync();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Realtime sync disabled'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showSyncResultDialog(SyncResult result) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: result.success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(result.success ? 'Sync Complete' : 'Sync Failed'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(result.message),
                  const SizedBox(height: 16),
                  _buildResultRow(
                    'Records Processed:',
                    result.recordsProcessed.toString(),
                  ),
                  _buildResultRow(
                    'Records Inserted:',
                    result.recordsInserted.toString(),
                    color: Colors.green,
                  ),
                  _buildResultRow(
                    'Records Skipped:',
                    result.recordsSkipped.toString(),
                    color: Colors.orange,
                  ),
                  if (result.errors.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Errors:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...result.errors.map(
                      (error) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $error',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildResultRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastSync = FirebaseSyncService.lastSyncTime;
    final realtimeEvents = FirebaseSyncService.realtimeEventsProcessed;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Sync'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isSyncing ? Icons.sync : Icons.cloud_done,
                          color: _isSyncing ? Colors.blue : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text('Sync Status', style: theme.textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatusRow(
                      'Current Status:',
                      _isSyncing ? 'Syncing...' : 'Idle',
                      color: _isSyncing ? Colors.blue : Colors.grey,
                    ),
                    _buildStatusRow(
                      'Realtime Sync:',
                      _isRealtimeSyncEnabled ? 'Active' : 'Disabled',
                      color: _isRealtimeSyncEnabled ? Colors.blue : Colors.grey,
                    ),
                    if (_isRealtimeSyncEnabled)
                      _buildStatusRow(
                        'Records Migrated:',
                        realtimeEvents.toString(),
                        color: Colors.green,
                      ),
                    _buildStatusRow(
                      'Auto-Sync:',
                      _isAutoSyncEnabled ? 'Enabled' : 'Disabled',
                      color: _isAutoSyncEnabled ? Colors.green : Colors.grey,
                    ),
                    if (lastSync != null)
                      _buildStatusRow(
                        'Last Sync:',
                        DateFormat('MMM dd, yyyy HH:mm:ss').format(lastSync),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Realtime Sync Control (NEW)
            Card(
              child: SwitchListTile(
                title: const Text('Continuous Realtime Sync (Recommended)'),
                subtitle: const Text(
                  'Constantly checks for new data every 2 seconds',
                ),
                value: _isRealtimeSyncEnabled,
                onChanged: _isSyncing ? null : _toggleRealtimeSync,
                secondary: const Icon(Icons.bolt),
              ),
            ),
            const SizedBox(height: 8),

            // Auto-Sync Control
            Card(
              child: SwitchListTile(
                title: const Text('Periodic Auto-Sync (Fallback)'),
                subtitle: const Text('Backup sync every 5 minutes'),
                value: _isAutoSyncEnabled,
                onChanged: _isSyncing ? null : _toggleAutoSync,
                secondary: const Icon(Icons.schedule),
              ),
            ),
            const SizedBox(height: 16),

            // Manual Sync Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _manualSync,
                icon:
                    _isSyncing
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.sync),
                label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Last Sync Result
            if (_lastSyncResult != null) ...[
              const Text(
                'Last Sync Result',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _lastSyncResult!.success
                                ? Icons.check_circle
                                : Icons.error,
                            color:
                                _lastSyncResult!.success
                                    ? Colors.green
                                    : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lastSyncResult!.message,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildResultRow(
                        'Processed:',
                        _lastSyncResult!.recordsProcessed.toString(),
                      ),
                      _buildResultRow(
                        'Inserted:',
                        _lastSyncResult!.recordsInserted.toString(),
                        color: Colors.green,
                      ),
                      _buildResultRow(
                        'Skipped:',
                        _lastSyncResult!.recordsSkipped.toString(),
                        color: Colors.orange,
                      ),
                      if (_lastSyncResult!.errors.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed:
                              () => _showSyncResultDialog(_lastSyncResult!),
                          icon: const Icon(Icons.error_outline, size: 18),
                          label: Text(
                            'View ${_lastSyncResult!.errors.length} errors',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Information Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'About Firebase Sync',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Firebase Queue Mode: Data is instantly migrated then auto-deleted from Firebase. '
                      'Firebase acts as a temporary queue, not a permanent database.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Continuous Sync: Checks every 2 seconds\n'
                      '• Instant migration (max 2 second delay)\n'
                      '• Auto-cleanup: Deletes from Firebase after migration\n'
                      '• No duplicate checking needed (queue mode)\n'
                      '• Firebase stays clean and fast\n'
                      '• Periodic backup sync every 5 minutes',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
