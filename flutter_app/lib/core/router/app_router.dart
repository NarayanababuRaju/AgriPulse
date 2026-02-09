import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/farmer_login_screen.dart';
import '../../features/dashboard/presentation/farmer_dashboard_screen.dart';
import '../../features/crop_diagnosis/presentation/crop_doctor_screen.dart';
import '../../features/yield_prediction/presentation/screens/yield_prediction_screen.dart';
import '../../features/crop_diagnosis/models/diagnosis_record.dart';
import '../../features/crop_diagnosis/presentation/screens/diagnosis_details_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/yield_prediction/models/yield_record.dart';
import '../../features/yield_prediction/presentation/screens/yield_details_screen.dart';
import '../../features/profile/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/field_registration_screen.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/dashboard/presentation/screens/activity_history_screen.dart';

// Global navigator key to prevent duplicate Navigator instances
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey, // Add stable navigator key
    initialLocation: AppRouter.dashboardPath,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    redirect: (context, state) => notifier._redirect(context, state),
    routes: [
      GoRoute(
        path: AppRouter.loginPath,
        builder: (context, state) => const FarmerLoginScreen(),
      ),
      GoRoute(
        path: AppRouter.dashboardPath,
        builder: (context, state) => const FarmerDashboardScreen(),
      ),
      GoRoute(
        path: AppRouter.onboardingPath,
        builder: (context, state) => const FarmSetupWizard(),
      ),
      GoRoute(
        path: AppRouter.fieldRegistrationPath,
        builder: (context, state) => const FieldRegistrationScreen(),
      ),
      GoRoute(
        path: AppRouter.cropDoctorPath,
        builder: (context, state) => const CropDoctorScreen(),
      ),
      GoRoute(
        path: AppRouter.yieldPredictionPath,
        builder: (context, state) => const YieldPredictionScreen(),
      ),
      GoRoute(
        path: AppRouter.diagnosisDetailsPath,
        builder: (context, state) {
          final record = state.extra as DiagnosisRecord;
          return DiagnosisDetailsScreen(record: record);
        },
      ),
      GoRoute(
        path: AppRouter.yieldDetailsPath,
        builder: (context, state) {
          final record = state.extra as YieldRecord;
          return YieldDetailsScreen(record: record);
        },
      ),
      GoRoute(
        path: AppRouter.activityLogPath,
        builder: (context, state) {
          final id = state.extra as String?;
          return ActivityHistoryScreen(initialSelectionId: id);
        },
      ),
    ],
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(profileProvider, (_, __) => notifyListeners());
  }

  String? _redirect(context, state) {
    final authState = _ref.read(authStateProvider);
    final profileState = _ref.read(profileProvider);

    // 🛡️ 1. Loading Guard: Wait for both Auth and Profile to settle
    // This is critical to prevent race conditions during refresh
    if (authState.isLoading || profileState.isLoading) {
      return null;
    }

    final bool loggedIn = authState.value != null;
    final bool hasFields = profileState.fields.isNotEmpty;
    
    final bool atLogin = state.matchedLocation == AppRouter.loginPath;
    final bool atFieldRegistration = state.matchedLocation == AppRouter.fieldRegistrationPath;

    // 🛡️ 2. Auth Guard: Redirect to Login if not authenticated
    if (!loggedIn) {
      return atLogin ? null : AppRouter.loginPath;
    }

    // 🛡️ 3. Login Redirect: If logged in and explicitly AT LOGIN, go to appropriate screen
    if (atLogin && loggedIn) {
      return hasFields ? AppRouter.dashboardPath : AppRouter.fieldRegistrationPath;
    }

    // 🛡️ 4. Onboarding Guard: If logged in but no fields, must register first plot
    if (!hasFields && !atFieldRegistration) {
      return AppRouter.fieldRegistrationPath;
    }

    // 🚀 5. Allow Access: Users can freely navigate to field registration to add plots
    // No need to redirect them away - the screen handles both first-time and returning users

    return null;
  }
}

class AppRouter {
  // Route Paths
  static const String loginPath = '/login';
  static const String dashboardPath = '/';
  static const String onboardingPath = '/onboarding';
  static const String fieldRegistrationPath = '/field-registration';
  static const String cropDoctorPath = '/crop-doctor';
  static const String yieldPredictionPath = '/yield-prediction';
  static const String yieldDetailsPath = '/yield-details';
  static const String diagnosisDetailsPath = '/diagnosis-details';
  static const String activityLogPath = '/activity-log';
}
