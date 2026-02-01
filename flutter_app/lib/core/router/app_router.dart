import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/farmer_login_screen.dart';
import '../../features/dashboard/presentation/farmer_dashboard_screen.dart';
import '../../features/crop_diagnosis/presentation/crop_doctor_screen.dart';
import '../../features/yield_prediction/presentation/screens/yield_prediction_screen.dart';

class AppRouter {
  // Route Paths
  static const String loginPath = '/login';
  static const String dashboardPath = '/';
  static const String cropDoctorPath = '/crop-doctor';
  static const String yieldPredictionPath = '/yield-prediction';

  // GoRouter Configuration
  // Defines the entire navigation tree of the application
  static final router = GoRouter(
    // Start at Login Screen by default
    // TODO: Add redirect logic based on AuthState later
    initialLocation: loginPath,
    routes: [
      GoRoute(
        path: loginPath,
        builder: (context, state) => const FarmerLoginScreen(),
      ),
      GoRoute(
        path: dashboardPath,
        builder: (context, state) => const FarmerDashboardScreen(),
      ),
      GoRoute(
        path: cropDoctorPath,
        builder: (context, state) => const CropDoctorScreen(),
      ),
      GoRoute(
        path: yieldPredictionPath,
        builder: (context, state) => const YieldPredictionScreen(),
      ),
    ],
  );
}
