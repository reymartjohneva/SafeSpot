import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final bool isPasswordField;

  const CustomInputField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hintText,
    this.keyboardType,
    this.enabled = true,
    this.obscureText = false,
    this.onToggleVisibility,
    this.isPasswordField = false,
  }) : super(key: key);

  const CustomInputField.password({
    Key? key,
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.enabled,
    required this.onToggleVisibility,
    this.hintText,
  }) : icon = Icons.lock_outline,
       keyboardType = null,
       isPasswordField = true,
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: enabled,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
              suffixIcon: isPasswordField
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      onPressed: enabled ? onToggleVisibility : null,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              hintText: hintText ?? 'Enter your ${label.toLowerCase()}',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
        ),
      ],
    );
  }
}