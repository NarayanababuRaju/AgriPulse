import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/color_palette.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import 'widgets/weather_card.dart';
import 'widgets/action_card.dart';
import 'widgets/recent_activity_list.dart';

/// FarmerDashboardScreen - The main home screen for the farmer
/// 
/// Displays:
/// 1. Greeting & Profile
/// 2. Weather Summary (WeatherCard) with Shimmer Loading
/// 3. Quick Actions Grid (ActionCard)
/// 4. Recent Activity (RecentActivityList)
class FarmerDashboardScreen extends ConsumerStatefulWidget {
  /// Whether to simulate an initial loading delay (for polish)
  final bool simulateLoading;

  const FarmerDashboardScreen({
    super.key,
    this.simulateLoading = true,
  });

  @override
  ConsumerState<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends ConsumerState<FarmerDashboardScreen> {
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    // Initialize loading state based on config
    _isLoading = widget.simulateLoading;

    if (_isLoading) {
      // Simulate network delay for polish
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access authenticated user data
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return Scaffold(
      backgroundColor: ColorPalette.offWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================
                // HEADER SECTION
                // ============================================
                // ============================================
                // HEADER SECTION
                // ============================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello,", // Changed from Namaste
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: ColorPalette.textSecondary,
                          ),
                        ),
                        Text(
                          user?.name ?? "Raju", // Fallback changed to Raju
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    // Profile/Logout Button
                    _buildProfileButton(context, ref),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // ============================================
                // WEATHER HERO CARD
                // ============================================
                // Pass _isLoading state to card
                WeatherCard(
                  isLoading: _isLoading,
                  condition: "Sunny", // Demonstrate dynamic config
                  temperature: 28,
                ).animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                
                const SizedBox(height: 32),
                
                // ============================================
                // ACTION LIST (Trendy Horizontal Scroll)
                // ============================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Smart Tools", // Updated Header
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.textPrimary,
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, size: 20, color: ColorPalette.emeraldGreen),
                  ],
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  height: 160,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      // CROP DOCTOR (Primary Feature)
                      _buildCompactActionCard(
                        context,
                        title: "Crop Doctor",
                        icon: Icons.local_hospital_rounded,
                        color: ColorPalette.rustRed,
                        onTap: () => context.push(AppRouter.cropDoctorPath),
                        delay: 200,
                      ),
                      const SizedBox(width: 16),

                      // YIELD PREDICTOR
                       _buildCompactActionCard(
                        context,
                        title: "Yield Est.",
                        icon: Icons.trending_up_rounded,
                        color: ColorPalette.goldenSunlight,
                        onTap: () {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text("Coming Soon in Phase 3!")),
                          );
                        },
                        delay: 300,
                      ),
                      const SizedBox(width: 16),

                      // MARKET PRICES
                       _buildCompactActionCard(
                        context,
                        title: "Market",
                        icon: Icons.currency_rupee_rounded,
                        color: ColorPalette.emeraldGreen,
                        onTap: () {},
                        delay: 400,
                      ),
                      const SizedBox(width: 16),
                      
                      // EXPERT HELP
                       _buildCompactActionCard(
                        context,
                        title: "Ask Expert",
                        icon: Icons.support_agent_rounded,
                        color: Colors.blueAccent,
                         onTap: () {},
                        delay: 500,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // ============================================
                // RECENT ACTIVITY
                // ============================================
                const RecentActivityList().animate().fadeIn(delay: 600.ms),
                
                const SizedBox(height: 48), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a compact version of the ActionCard for the horizontal list
  Widget _buildCompactActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return SizedBox(
      width: 130, // Fixed width for compact look
      child: ActionCard(
        title: title,
        icon: icon,
        color: color,
        onTap: onTap,
        // We can pass isPrimary if needed, or default to false for uniform look
        isPrimary: false, 
      ),
    ).animate().scale(delay: delay.ms, duration: 400.ms, curve: Curves.easeOutBack);
  }

  /// Builds the profile button with a popup menu for Logout
  Widget _buildProfileButton(BuildContext context, WidgetRef ref) {
     return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'logout') {
          // Trigger logout in global state
          ref.read(authStateProvider.notifier).logout();
          // Router will redirect to Login thanks to 'refreshListenable' logic (to be added)
          // For now, explicit navigation:
          context.go(AppRouter.loginPath);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'profile',
          child: Text('My Profile'),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text('Logout'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(2), // Border width
        decoration: const BoxDecoration(
          color: ColorPalette.emeraldGreen, // Border color
          shape: BoxShape.circle,
        ),
        child: Container(
           padding: const EdgeInsets.all(8),
           decoration: const BoxDecoration(
             color: Colors.white,
             shape: BoxShape.circle,
           ),
           child: const Icon(Icons.person, color: ColorPalette.emeraldGreen),
        ),
      ),
    );
  }
}
