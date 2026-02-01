import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/color_palette.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import 'providers/weather_provider.dart'; // Import Weather Provider
import 'widgets/weather_card.dart';
import 'widgets/action_card.dart';
import 'widgets/recent_activity_list.dart';
import '../../yield_prediction/providers/language_provider.dart';

/// FarmerDashboardScreen - The main home screen for the farmer
/// 
/// Displays:
/// 1. Greeting & Profile
/// 2. Weather Summary (WeatherCard) with Shimmer Loading
/// 3. Quick Actions Grid (ActionCard)
/// 4. Recent Activity (RecentActivityList)
class FarmerDashboardScreen extends ConsumerWidget {
  const FarmerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access authenticated user data
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    // Access Weather State
    final weatherState = ref.watch(weatherProvider);
    final weather = weatherState.data;

    // Translation Helper
    // We watch the language provider state to rebuild updates, 
    // and use the notifier to look up strings.
    ref.watch(languageProvider); 
    final tr = ref.read(languageProvider.notifier).translate;

    return Scaffold(
      backgroundColor: ColorPalette.offWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... (Header) ...
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${tr('hello')},", 
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: ColorPalette.textSecondary,
                          ),
                        ),
                        Text(
                          user?.name ?? "Raju", 
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Language Dropdown
                        Consumer(
                          builder: (context, ref, _) {
                            final language = ref.watch(languageProvider);
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<AppLanguage>(
                                  value: language,
                                  isDense: true,
                                  icon: const Icon(Icons.language, size: 18, color: ColorPalette.emeraldGreen),
                                  items: AppLanguage.values.map((lang) {
                                    return DropdownMenuItem(
                                      value: lang,
                                      child: Text(
                                        lang == AppLanguage.en ? "English" :
                                        lang == AppLanguage.hi ? "हिन्दी" :
                                        lang == AppLanguage.ta ? "தமிழ்" :
                                        lang == AppLanguage.kn ? "ಕನ್ನಡ" :
                                        lang == AppLanguage.te ? "తెలుగు" : "മലയാളം",
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (lang) {
                                    if (lang != null) {
                                      ref.read(languageProvider.notifier).setLanguage(lang);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        _buildProfileButton(context, ref),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // WEATHER HERO CARD
                WeatherCard(
                  isLoading: weatherState.isLoading,
                  condition: weather?['condition'] ?? "Sunny",
                  temperature: (weather?['temperature'] as num?)?.toInt() ?? 28,
                  location: weather?['location'] ?? "Namakkal, Tamil Nadu",
                  date: DateTime.now(),
                ).animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                
                const SizedBox(height: 32),
                
                // ... (Rest of UI) ...

                
                const SizedBox(height: 32),
                
                // ============================================
                // ACTION LIST (Trendy Horizontal Scroll)
                // ============================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('smart_tools'), // Updated Header
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
                        title: tr('crop_doctor'),
                        icon: Icons.local_hospital_rounded,
                        color: ColorPalette.rustRed,
                        onTap: () => context.push(AppRouter.cropDoctorPath),
                        delay: 200,
                      ),
                      const SizedBox(width: 16),

                      // YIELD PREDICTOR
                       _buildCompactActionCard(
                        context,
                        title: tr('yield_est'),
                        icon: Icons.trending_up_rounded,
                        color: ColorPalette.goldenSunlight,
                        onTap: () => context.push(AppRouter.yieldPredictionPath),
                        delay: 300,
                      ),
                      const SizedBox(width: 16),

                      // MARKET PRICES
                       _buildCompactActionCard(
                        context,
                        title: tr('market'),
                        icon: Icons.currency_rupee_rounded,
                        color: ColorPalette.emeraldGreen,
                        onTap: () {},
                        delay: 400,
                      ),
                      const SizedBox(width: 16),
                      
                      // EXPERT HELP
                       _buildCompactActionCard(
                        context,
                        title: tr('ask_expert'),
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
