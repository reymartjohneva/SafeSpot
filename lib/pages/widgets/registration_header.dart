import 'package:flutter/material.dart';

class RegistrationHeader extends StatefulWidget {
  const RegistrationHeader({Key? key}) : super(key: key);

  @override
  State<RegistrationHeader> createState() => _RegistrationHeaderState();
}

class _RegistrationHeaderState extends State<RegistrationHeader>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _rotateController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));
    
    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      child: Column(
        children: [
          // Enhanced logo with multiple animation effects
          AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _rotateAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Transform.rotate(
                  angle: _rotateAnimation.value * 0.08,
                  child: Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.brown.shade300,
                          Colors.brown.shade600,
                          Colors.brown.shade800,
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.brown.withOpacity(0.4),
                          blurRadius: 25,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: Colors.brown.withOpacity(0.2),
                          blurRadius: 35,
                          spreadRadius: 12,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(45),
                      child: Image.asset(
                        'assets/app1_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.brown.shade400,
                                  Colors.brown.shade600,
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 45,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // App name with enhanced shadow and gradient
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.white,
                Colors.brown.shade200,
                Colors.white,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds),
            child: Text(
              'SafeSpot',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                  Shadow(
                    color: Colors.brown.withOpacity(0.3),
                    offset: const Offset(0, 0),
                    blurRadius: 15,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Enhanced tagline with typing animation effect
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 2200),
            builder: (context, value, child) {
              final text = 'Create Your SafeSpot Account';
              final displayText = text.substring(0, (text.length * value).round());
              
              return Text(
                displayText,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.8,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}