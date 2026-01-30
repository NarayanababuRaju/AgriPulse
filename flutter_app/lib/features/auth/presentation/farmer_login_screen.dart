import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../providers/auth_provider.dart';
import '../../../core/router/app_router.dart';

/// FarmerLoginScreen - Two-step phone authentication UI
/// 
/// This screen implements a state-driven UI that adapts based on the login flow:
/// 1. Phone Number Entry → Send OTP
/// 2. OTP Verification → Login
/// 
/// Uses ConsumerStatefulWidget to:
/// - Watch login state changes (ref.watch)
/// - Listen for side effects like navigation (ref.listen)
/// - Manage local TextEditingControllers
class FarmerLoginScreen extends ConsumerStatefulWidget {
  const FarmerLoginScreen({super.key});

  @override
  ConsumerState<FarmerLoginScreen> createState() => _FarmerLoginScreenState();
}

class _FarmerLoginScreenState extends ConsumerState<FarmerLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _selectedCountryCode = "+91"; // Default to India

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the login state to rebuild UI when state changes
    final loginState = ref.watch(loginControllerProvider);
    final isOtpSent = loginState.status == LoginStatus.otpSent;
    final isLoading = loginState.status == LoginStatus.authenticating;

    // ref.listen: Execute side effects when state changes
    ref.listen(loginControllerProvider, (previous, next) {
      // Navigation: On successful authentication, go to dashboard
      if (next.status == LoginStatus.authenticated) {
        context.go(AppRouter.dashboardPath);
      } 
      // Error Handling: Show snackbar for errors
      else if (next.status == LoginStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: ColorPalette.rustRed,
          ),
        );
      }
    });

    return Scaffold(
      // Replaced backgroundColor with Stack for Background Image
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. Dark Overlay for Contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),

          // 3. Content
          LoadingOverlay(
            isLoading: isLoading,
            message: "Verifying securely...",
            child: Center(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ============================================
                          // HERO SECTION: Logo + Branding
                          // ============================================
                          const Icon(
                            Icons.agriculture_rounded,
                            size: 80,
                            color: Colors.white,
                          )
                          // flutter_animate: Scale animation with bounce effect
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.easeOutBack),
                          
                          const SizedBox(height: 16),
                          
                          Text(
                            "AgriPulse",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          
                          Text(
                            "Your Intelligent Farming Companion",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ).animate().fadeIn(delay: 400.ms),

                          const SizedBox(height: 48),

                          // Login Form Card
                          Card(
                            elevation: 8,
                            shadowColor: Colors.black45,
                            color: Colors.white.withOpacity(0.95),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Text(
                                    isOtpSent ? "Enter Verification Code" : "Farmer Login",
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: ColorPalette.emeraldGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  if (!isOtpSent) ...[
                                    // STEP 1: Phone Number with Country Code
                                    TextField(
                                      key: const Key('phone_input'),
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        labelText: "Phone Number",
                                        hintText: "98765 43210",
                                        
                                        // Country Code Picker as Prefix
                                        prefixIcon: CountryCodePicker(
                                          onChanged: (code) {
                                            setState(() {
                                              _selectedCountryCode = code.dialCode ?? "+91";
                                            });
                                          },
                                          initialSelection: 'IN', // Default to India
                                          favorite: const ['+91', 'IN'],
                                          showCountryOnly: false,
                                          showOnlyCountryWhenClosed: false,
                                          alignLeft: false,
                                          flagWidth: 24,
                                          padding: const EdgeInsets.all(0),
                                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        
                                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        key: const Key('send_otp_button'),
                                        onPressed: () {
                                          // Combine Country Code + Phone Number
                                          final fullNumber = "$_selectedCountryCode${_phoneController.text}";
                                          ref.read(loginControllerProvider.notifier)
                                             .sendOtp(fullNumber);
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: ColorPalette.emeraldGreen,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                        ),
                                        child: const Text("Send OTP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ] else ...[
                                    // STEP 2: OTP
                                    TextField(
                                      key: const Key('otp_input'),
                                      controller: _otpController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                                      decoration: const InputDecoration(
                                        hintText: "------",
                                        counterText: "",
                                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ).animate().fadeIn(),
                                    
                                    const SizedBox(height: 12),
                                    
                                    Text(
                                      "Sent to $_selectedCountryCode ${_phoneController.text}",
                                      style: const TextStyle(color: ColorPalette.textSecondary),
                                    ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        key: const Key('verify_button'),
                                        onPressed: () {
                                          ref.read(loginControllerProvider.notifier)
                                             .verifyOtp(_otpController.text);
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: ColorPalette.emeraldGreen,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                        ),
                                        child: const Text("Verify & Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    
                                    TextButton(
                                      key: const Key('change_number_button'),
                                      onPressed: () {
                                        ref.read(loginControllerProvider.notifier).reset();
                                        _otpController.clear();
                                      },
                                      child: const Text("Change Number"),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ).animate().slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOut),
                          
                          const SizedBox(height: 32),
                          
                          const Text(
                            "Powered by Gemini 3.0",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
