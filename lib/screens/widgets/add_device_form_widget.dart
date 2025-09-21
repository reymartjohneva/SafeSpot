import 'package:flutter/material.dart';

class AddDeviceFormWidget extends StatelessWidget {
  final TextEditingController deviceIdController;
  final TextEditingController deviceNameController;
  final bool isAddingDevice;
  final VoidCallback onAddDevice;

  const AddDeviceFormWidget({
    Key? key,
    required this.deviceIdController,
    required this.deviceNameController,
    required this.isAddingDevice,
    required this.onAddDevice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black87, // Match navbar color
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A50), // Orange accent color
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8A50).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Add New Device',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Device ID Field
          TextFormField(
            controller: deviceIdController,
            enabled: !isAddingDevice,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Device ID',
              labelStyle: TextStyle(color: Colors.grey.shade400),
              hintText: 'Enter unique device identifier',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(
                Icons.perm_device_information,
                color: Colors.grey.shade400,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade600),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF8A50), width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              filled: true,
              fillColor: Colors.grey.shade900.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          
          // Device Name Field
          TextFormField(
            controller: deviceNameController,
            enabled: !isAddingDevice,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Device Name',
              labelStyle: TextStyle(color: Colors.grey.shade400),
              hintText: 'Enter a friendly name for this device',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(
                Icons.label,
                color: Colors.grey.shade400,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade600),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF8A50), width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              filled: true,
              fillColor: Colors.grey.shade900.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          
          // Add Device Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isAddingDevice ? null : onAddDevice,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: const Color(0xFFFF8A50), // Orange button
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade700,
                elevation: 8,
                shadowColor: const Color(0xFFFF8A50).withOpacity(0.3),
              ),
              child: isAddingDevice
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Adding Device...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Add Device',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}