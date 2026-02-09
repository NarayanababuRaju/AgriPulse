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
import 'widgets/field_selector.dart';
import '../../profile/providers/profile_provider.dart';
import 'package:flutter_app/core/api/path_enforcer.dart';
import 'package:flutter_app/core/widgets/offline_banner.dart';
import 'package:flutter_app/core/localization/language_provider.dart';
import 'package:flutter_app/core/widgets/language_selector.dart';

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

    // Plot Context
    final profileState = ref.watch(profileProvider);
    final activeField = profileState.selectedField;

    return Scaffold(
      backgroundColor: ColorPalette.offWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FIXED HEADER (Greeting, Language, Profile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const OfflineBanner(),
                   const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${tr('hello')},", 
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: ColorPalette.textSecondary,
                              ),
                            ),
                            Text(
                              activeField != null && activeField.id != PathEnforcer.unassignedFieldId
                                ? "${user?.name ?? "Raju"} • ${activeField.name}"
                                : user?.name ?? "Raju", 
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: ColorPalette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const LanguageSelector(
                            textColor: ColorPalette.textPrimary,
                          ),
                          const SizedBox(width: 12),
                          _buildProfileButton(context, ref),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // MAIN CONTENT AREA (Responsive Split Panels)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isDesktop = constraints.maxWidth > 800;
                    
                    if (isDesktop) {
                      // 🏛️ HYBRID DESKTOP VIEW
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔝 TOP SECTION (2 Columns)
                          Expanded(
                            flex: 3,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // LEFT: Active Tools & Weather
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildWeatherSection(weatherState, weather),
                                        const SizedBox(height: 24),
                                        Expanded(
                                          child: _buildSmartToolsSection(context, tr, crossAxisCount: 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                _buildDivider(),

                                // RIGHT: Plot & Recent Activity
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 16, bottom: 12),
                                        child: Text(
                                          tr('select_plot'),
                                          style: GoogleFonts.outfit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: ColorPalette.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(left: 16, bottom: 20),
                                        child: FieldSelector(),
                                      ),
                                      const Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 16),
                                          child: RecentActivityList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                          const Divider(height: 1),
                          const SizedBox(height: 16),

                          // 🆕 BOTTOM SECTION (Full Width Coming Soon)
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildComingSoonSection(tr, crossAxisCount: 6, availableWidth: constraints.maxWidth - 48 - 32), // 48=outer padding, 32=inner padding
                            ),
                          ),
                        ],
                      );
                    } else {
                      // 📱 STACKED VIEW (Mobile)
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildWeatherSection(weatherState, weather),
                                  const SizedBox(height: 24),
                                  const FieldSelector(),
                                  const SizedBox(height: 16),
                                  _buildSmartToolsSection(context, tr, crossAxisCount: 2),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),

                          // RECENT ACTIVITY (Middle Priority)
                          const Expanded(
                            flex: 4,
                            child: Padding(
                               padding: EdgeInsets.only(bottom: 16),
                               child: RecentActivityList(),
                            ),
                          ),

                          const SizedBox(height: 16),
                          
                          // COMING SOON (Bottom Priority - Fixed Wrap)
                          Expanded(
                            flex: 2,
                            child: SingleChildScrollView( // Keep scroll ONLY for this section if it overflows vertically in small space
                              child: _buildComingSoonSection(tr, crossAxisCount: 2, availableWidth: constraints.maxWidth),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Builds the Weather card
  Widget _buildWeatherSection(var weatherState, var weather) {
    return WeatherCard(
      isLoading: weatherState.isLoading,
      condition: weather?['condition'] ?? "Sunny",
      temperature: (weather?['temperature'] as num?)?.toInt() ?? 28,
      location: weather?['location'] ?? "Namakkal, Tamil Nadu",
      date: DateTime.now(),
    ).animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }

  /// Builds the Active Smart Tools grid
  Widget _buildSmartToolsSection(BuildContext context, dynamic tr, {required int crossAxisCount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('smart_tools'),
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ColorPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            ActionCard(
              title: tr('crop_doctor'),
              subtitle: tr('crop_doctor_desc'),
              icon: Icons.local_hospital_rounded,
              color: ColorPalette.rustRed,
              onTap: () => context.push(AppRouter.cropDoctorPath),
            ),
            ActionCard(
              title: tr('yield_est'),
              subtitle: tr('yield_est_desc'),
              icon: Icons.trending_up_rounded,
              color: ColorPalette.goldenSunlight,
              onTap: () => context.push(AppRouter.yieldPredictionPath),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  /// Builds the Coming Soon tools grid
  Widget _buildComingSoonSection(dynamic tr, {required int crossAxisCount, required double availableWidth}) {
    // Calculate card width based on available width and column count
    // Subtract spacing (10px gap * (count - 1))
    const double spacing = 10;
    final double cardWidth = (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('coming_soon'),
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ColorPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _buildWrapItem(tr('soil_health_time_machine'), tr('soil_health_desc'), Icons.history_rounded, Colors.brown.shade400, cardWidth),
            _buildWrapItem(tr('market_analysis'), tr('market_analysis_desc'), Icons.analytics_rounded, ColorPalette.emeraldGreen, cardWidth),
            _buildWrapItem(tr('smart_irrigation'), tr('smart_irrigation_desc'), Icons.water_drop_rounded, Colors.blue.shade400, cardWidth),
            _buildWrapItem(tr('sustainable_farming'), tr('sustainable_farming_desc'), Icons.eco_rounded, Colors.green.shade600, cardWidth),
            _buildWrapItem(tr('community_alert'), tr('community_alert_desc'), Icons.notifications_active_rounded, Colors.orange.shade500, cardWidth),
            _buildWrapItem(tr('government_schemes'), tr('government_schemes_desc'), Icons.account_balance_rounded, Colors.indigo.shade400, cardWidth),
            _buildWrapItem(tr('onboarding_tutorials'), tr('onboarding_tutorials_desc'), Icons.school_rounded, Colors.teal.shade400, cardWidth),
            _buildWrapItem(tr('voice_command'), tr('voice_command_desc'), Icons.mic_rounded, Colors.purple.shade400, cardWidth),
            _buildWrapItem(tr('support_24_7'), tr('support_24_7_desc'), Icons.support_agent_rounded, Colors.blueAccent, cardWidth),
          ].animate(interval: 50.ms).fade(duration: 300.ms),
        ),
      ],
    );
  }

  Widget _buildWrapItem(String title, String subtitle, IconData icon, Color color, double width) {
    return SizedBox(
      width: width,
      child: ActionCard(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        onTap: () {},
        isComingSoon: true,
      ),
    );
  }

  /// Builds a vertical divider
  Widget _buildDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.grey.shade200,
    );
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

