import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_spot/screens/emergency_components/emergency_card.dart';
import 'package:safe_spot/screens/emergency_components/section_header.dart';
import 'package:safe_spot/screens/emergency_components/quick_tips_card.dart';
import 'package:safe_spot/screens/emergency_components/emergency_app_bar.dart';
import 'package:safe_spot/screens/emergency_components/call_handler.dart';
import 'package:safe_spot/screens/app_guide_screen.dart';

class EmergencyHotlinesScreen extends StatefulWidget {
  const EmergencyHotlinesScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyHotlinesScreen> createState() =>
      _EmergencyHotlinesScreenState();
}

class _EmergencyHotlinesScreenState extends State<EmergencyHotlinesScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 25, 24, 24),
      body: CustomScrollView(
        slivers: [
          EmergencyAppBar(fadeAnimation: _fadeAnimation),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _buildAppGuideButton(),
                        const SizedBox(height: 24),
                        _buildCriticalSection(),
                        const SizedBox(height: 32),
                        _buildGovernmentSection(),
                        const SizedBox(height: 32),
                        const QuickTipsCard(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppGuideButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF8A50).withOpacity(0.15),
            const Color(0xFFFF6B35).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF8A50).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AppGuideScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF9800)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How to Use SafeSpot',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Learn about features & safety tips',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFFF8A50),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCriticalSection() {
    return Column(
      children: [
        const SectionHeader(
          title: 'Critical Emergency',
          icon: Icons.warning_amber_rounded,
        ),
        const SizedBox(height: 16),
        EmergencyCard(
          icon: Icons.local_police,
          title: 'Philippine National Police',
          subtitle: 'PNP Emergency Response',
          number: '09641132441',
          description: 'Immediate police assistance and crime reporting',
          color: const Color(0xFF2196F3),
          isPrimary: true,
          onTap: () => CallHandler.makePhoneCall(context, '09641132441'),
        ),
        const SizedBox(height: 12),
        EmergencyCard(
          icon: Icons.local_fire_department,
          title: 'Bureau of Fire Protection',
          subtitle: 'BFP Emergency Response',
          number: '09177726300',
          description: 'Fire emergencies and rescue operations',
          color: const Color(0xFFE53935),
          isPrimary: true,
          onTap: () => CallHandler.makePhoneCall(context, '09177726300'),
        ),
        const SizedBox(height: 12),
        EmergencyCard(
          icon: Icons.local_hospital,
          title: 'Emergency Medical Services',
          subtitle: 'Medical Emergency',
          number: '911',
          description: 'Medical emergency and ambulance services',
          color: const Color(0xFF43A047),
          isPrimary: true,
          onTap: () => CallHandler.makePhoneCall(context, '911'),
        ),
      ],
    );
  }

  Widget _buildGovernmentSection() {
    return Column(
      children: [
        const SectionHeader(
          title: 'Government Services',
          icon: Icons.account_balance,
        ),
        const SizedBox(height: 16),
        EmergencyCard(
          icon: Icons.phone_in_talk,
          title: 'Government Hotline',
          subtitle: 'DILG Emergency Response',
          number: '8888',
          description: 'General government emergency assistance',
          color: const Color(0xFF8E24AA),
          onTap: () => CallHandler.makePhoneCall(context, '8888'),
        ),
        const SizedBox(height: 12),
        EmergencyCard(
          icon: Icons.warning,
          title: 'Disaster Risk Reduction',
          subtitle: 'NDRRMC Emergency Response',
          number: '(02) 8911-5061',
          description: 'Natural disaster and emergency coordination',
          color: const Color(0xFFFF8A50),
          onTap: () => CallHandler.makePhoneCall(context, '(02) 8911-5061'),
        ),
        const SizedBox(height: 12),
        EmergencyCard(
          icon: Icons.directions_boat,
          title: 'Coast Guard Emergency',
          subtitle: 'PCG Search and Rescue',
          number: '(02) 8527-8481',
          description: 'Maritime emergencies and water rescue',
          color: const Color(0xFF039BE5),
          onTap: () => CallHandler.makePhoneCall(context, '(02) 8527-8481'),
        ),
      ],
    );
  }
}
