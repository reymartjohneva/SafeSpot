import 'package:flutter/material.dart';
import 'package:safe_spot/services/device_service.dart';

class EmptyChildrenState extends StatelessWidget {
  final List<Device> userDevices;
  final VoidCallback onAddChild;

  const EmptyChildrenState({
    super.key,
    required this.userDevices,
    required this.onAddChild,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.child_friendly,
              size: 64,
              color: Color(0xFFB0B0B0),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Children Added Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            userDevices.isEmpty 
                ? 'Add devices first to register children information'
                : 'Add information about the children using your tracked devices',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFB0B0B0),
            ),
            textAlign: TextAlign.center,
          ),
          if (userDevices.isNotEmpty) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAddChild,
              icon: const Icon(Icons.add),
              label: const Text('Add Child Information'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: const Color(0xFFFF8A50),
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: const Color(0xFFFF8A50).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
