import 'package:flutter/material.dart';
import 'registration_custom_input_field.dart';
import 'create_account_button.dart';

class RegistrationForm extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isLoading;
  final VoidCallback onRegister;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;

  const RegistrationForm({
    Key? key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.mobileController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isLoading,
    required this.onRegister,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Join us text
          const Center(
            child: Text(
              'Join SafeSpot!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Full name section
          Text(
            'Full Name',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),

          // First name and Last name row
          Row(
            children: [
              Expanded(
                child: CustomInputField(
                  controller: firstNameController,
                  label: '',
                  icon: Icons.person_outline,
                  hintText: 'First name',
                  enabled: !isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomInputField(
                  controller: lastNameController,
                  label: '',
                  icon: Icons.person_outline,
                  hintText: 'Last name',
                  enabled: !isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Email field
          CustomInputField(
            controller: emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
          ),
          const SizedBox(height: 20),

          // Mobile field
          CustomInputField(
            controller: mobileController,
            label: 'Mobile Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            enabled: !isLoading,
          ),
          const SizedBox(height: 20),

          // Password field
          CustomInputField.password(
            controller: passwordController,
            label: 'Password',
            obscureText: obscurePassword,
            enabled: !isLoading,
            onToggleVisibility: onTogglePasswordVisibility,
          ),
          const SizedBox(height: 20),

          // Confirm Password field
          CustomInputField.password(
            controller: confirmPasswordController,
            label: 'Confirm Password',
            obscureText: obscureConfirmPassword,
            enabled: !isLoading,
            onToggleVisibility: onToggleConfirmPasswordVisibility,
          ),
          const SizedBox(height: 30),

          // Create Account button
          CreateAccountButton(
            isLoading: isLoading,
            onPressed: onRegister,
          ),
        ],
      ),
    );
  }
}