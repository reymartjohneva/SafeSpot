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
    final isRealtime = FirebaseSyncService.isRealtimeActive;

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
              : Icon(
                isRealtime ? Icons.cloud_sync : Icons.cloud_done,
                color: isRealtime ? Colors.blue : Colors.green,
              ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FirebaseSyncScreen()),
        );
      },
      tooltip:
          isSyncing
              ? 'Syncing...'
              : isRealtime
              ? 'Continuous sync active (2s)'
              : 'Open Firebase Sync',
    );
  }

  Widget _buildFullView() {
    final isSyncing = FirebaseSyncService.isSyncing;
    final lastSync = FirebaseSyncService.lastSyncTime;
    final isRealtime = FirebaseSyncService.isRealtimeActive;
    final realtimeEvents = FirebaseSyncService.realtimeEventsProcessed;

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
                Icon(
                  isRealtime ? Icons.sync : Icons.cloud_done,
                  color: isRealtime ? Colors.blue : Colors.green,
                  size: 24,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Firebase Sync',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (isRealtime) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      isSyncing
                          ? 'Syncing...'
                          : isRealtime
                          ? 'Realtime active • $realtimeEvents migrated'
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
    final isRealtime = FirebaseSyncService.isRealtimeActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isSyncing
                ? Colors.orange
                : isRealtime
                ? Colors.blue
                : Colors.green,
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
            Icon(
              isRealtime ? Icons.sync : Icons.check,
              size: 12,
              color: Colors.white,
            ),
          const SizedBox(width: 4),
          Text(
            isSyncing
                ? 'Syncing'
                : isRealtime
                ? 'Live'
                : 'Synced',
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
