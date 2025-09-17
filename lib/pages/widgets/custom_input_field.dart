import 'package:flutter/material.dart';

class CustomInputField extends StatefulWidget {
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
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;
  late Animation<double> _shadowAnimation;
  
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    
    _focusController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeInOut,
    ));
    
    _borderColorAnimation = ColorTween(
      begin: Colors.white.withOpacity(0.3),
      end: Colors.brown.shade400,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeInOut,
    ));
    
    _shadowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.label.isNotEmpty) ...[
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isFocused 
                        ? Colors.brown.shade300
                        : Colors.white.withOpacity(0.9),
                  ),
                  child: Text(widget.label),
                ),
                const SizedBox(height: 8),
              ],
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(_isFocused ? 0.2 : 0.1),
                      Colors.white.withOpacity(_isFocused ? 0.15 : 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _borderColorAnimation.value ?? Colors.white.withOpacity(0.3),
                    width: _isFocused ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    if (_isFocused)
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.2 * _shadowAnimation.value),
                        blurRadius: 15 * _shadowAnimation.value,
                        offset: const Offset(0, 5),
                        spreadRadius: 2 * _shadowAnimation.value,
                      ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Focus(
                  onFocusChange: (hasFocus) {
                    setState(() {
                      _isFocused = hasFocus;
                    });
                    if (hasFocus) {
                      _focusController.forward();
                    } else {
                      _focusController.reverse();
                    }
                  },
                  child: TextField(
                    controller: widget.controller,
                    keyboardType: widget.keyboardType,
                    obscureText: widget.obscureText,
                    enabled: widget.enabled,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          widget.icon,
                          color: _isFocused 
                              ? Colors.brown.shade300
                              : Colors.white.withOpacity(0.7),
                          size: 22,
                        ),
                      ),
                      suffixIcon: widget.isPasswordField
                          ? AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(scale: animation, child: child);
                              },
                              child: IconButton(
                                key: ValueKey(widget.obscureText),
                                icon: Icon(
                                  widget.obscureText ? Icons.visibility_off : Icons.visibility,
                                  color: _isFocused 
                                      ? Colors.brown.shade300
                                      : Colors.white.withOpacity(0.7),
                                  size: 22,
                                ),
                                onPressed: widget.enabled ? widget.onToggleVisibility : null,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      hintText: widget.hintText ?? 'Enter your ${widget.label.toLowerCase()}',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}