import 'package:flutter/material.dart';
import '../services/firebase_sync_service.dart';
import '../screens/firebase_sync_screen.dart';

/// A compact widget showing Firebase sync status
/// Can be placed in app bar, drawer, or anywhere
class FirebaseSyncStatusWidget extends StatefulWidget {
  final bool compact;

  const FirebaseSyncStatusWidget({super.key, this.compact = false});

  @override
  State<FirebaseSyncStatusWidget> createState() =>
      _FirebaseSyncStatusWidgetState();
}

class _FirebaseSyncStatusWidgetState extends State<FirebaseSyncStatusWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactView();
    }
    return _buildFullView();
  }

  Widget _buildCompactView() {
    final isSyncing = FirebaseSyncService.isSyncing;

    return IconButton(
      icon:
          isSyncing
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              )
              : const Icon(Icons.cloud_sync),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FirebaseSyncScreen()),
        );
      },
      tooltip: isSyncing ? 'Syncing...' : 'Open Firebase Sync',
    );
  }

  Widget _buildFullView() {
    final isSyncing = FirebaseSyncService.isSyncing;
    final lastSync = FirebaseSyncService.lastSyncTime;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FirebaseSyncScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (isSyncing)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.cloud_done, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase Sync',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isSyncing
                          ? 'Syncing...'
                          : lastSync != null
                          ? 'Last synced: ${_formatTime(lastSync)}'
                          : 'Never synced',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

/// Quick action button for manual sync
class QuickSyncButton extends StatefulWidget {
  final VoidCallback? onSyncComplete;

  const QuickSyncButton({super.key, this.onSyncComplete});

  @override
  State<QuickSyncButton> createState() => _QuickSyncButtonState();
}

class _QuickSyncButtonState extends State<QuickSyncButton> {
  bool _syncing = false;

  Future<void> _sync() async {
    if (_syncing) return;

    setState(() => _syncing = true);

    try {
      final result = await FirebaseSyncService.syncData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? 'Synced ${result.recordsInserted} records'
                  : 'Sync failed',
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FirebaseSyncScreen(),
                  ),
                );
              },
            ),
          ),
        );

        widget.onSyncComplete?.call();
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _syncing ? null : _sync,
      child:
          _syncing
              ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              )
              : const Icon(Icons.sync),
    );
  }
}

/// Badge showing sync status in drawer or menu
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final isSyncing = FirebaseSyncService.isSyncing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSyncing ? Colors.blue : Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSyncing)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            const Icon(Icons.check, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            isSyncing ? 'Syncing' : 'Synced',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
