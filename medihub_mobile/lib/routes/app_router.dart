import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/reset_password_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/home/presentation/feedback_page.dart';
import '../features/home/presentation/guide_page.dart';
import '../features/home/presentation/hotline_page.dart';
import '../features/home/presentation/direction_page.dart';
import '../features/home/presentation/queue_page.dart';
import '../features/home/presentation/lab_results_page.dart';
import '../features/home/presentation/imaging_results_page.dart';
import '../features/home/presentation/surgery_page.dart';
import '../features/splash/presentation/splash_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/profile/presentation/profile_detail_page.dart';
import '../features/profile/presentation/relatives_page.dart';
import '../features/profile/presentation/relative_form_page.dart';
import '../features/profile/presentation/referral_page.dart';
import '../features/profile/presentation/policy_page.dart';
import '../features/profile/presentation/change_password_page.dart';
import '../features/profile/presentation/change_phone_page.dart';
import '../features/admin/presentation/admin_page.dart';
import '../features/news/presentation/news_admin_page.dart';
import '../features/news/presentation/news_form_page.dart';
import '../features/news/presentation/news_list_page.dart';
import '../features/news/presentation/news_detail_page.dart';
import '../features/appointment/presentation/appointments_page.dart';
import '../features/appointment/presentation/create_appointment_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/admin/presentation/admin_appointments_page.dart';
import '../features/doctor/presentation/doctor_complete_page.dart';
import '../features/admin/presentation/admin_appointment_detail_page.dart';
import '../../features/consult/presentation/consult_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterPage(
        organizationCode: state.uri.queryParameters['organizationCode'],
        organizationName: state.uri.queryParameters['organizationName'],
      ),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordPage(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/feedback',
      builder: (context, state) => const FeedbackPage(),
    ),
    GoRoute(path: '/guide', builder: (context, state) => const GuidePage()),
    GoRoute(path: '/hotline', builder: (context, state) => const HotlinePage()),
    GoRoute(
      path: '/direction',
      builder: (context, state) => const DirectionPage(),
    ),
    GoRoute(path: '/queue', builder: (context, state) => const QueuePage()),
    GoRoute(
      path: '/lab-results',
      builder: (context, state) => const LabResultsPage(),
    ),
    GoRoute(
      path: '/imaging-results',
      builder: (context, state) => const ImagingResultsPage(),
    ),
    GoRoute(path: '/surgery', builder: (context, state) => const SurgeryPage()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
    GoRoute(
      path: '/profile/detail',
      builder: (context, state) => const ProfileDetailPage(),
    ),
    GoRoute(
      path: '/profile/relatives',
      builder: (context, state) => const RelativesPage(),
    ),
    GoRoute(
      path: '/profile/relatives/form',
      builder: (context, state) =>
          RelativeFormPage(relative: state.extra as Map<String, dynamic>?),
    ),
    GoRoute(
      path: '/profile/referral',
      builder: (context, state) => const ReferralPage(),
    ),
    GoRoute(
      path: '/profile/policy',
      builder: (context, state) => const PolicyPage(),
    ),
    GoRoute(
      path: '/profile/change-password',
      builder: (context, state) => const ChangePasswordPage(),
    ),
    GoRoute(
      path: '/profile/change-phone',
      builder: (context, state) => const ChangePhonePage(),
    ),

    GoRoute(path: '/admin', builder: (context, state) => const AdminPage()),
    GoRoute(path: '/admin/news', builder: (context, state) => const NewsAdminPage()),

    GoRoute(
      path: '/admin/news/create',
      builder: (context, state) => const NewsFormPage(),
    ),

    GoRoute(
      path: '/admin/news/edit/:id',
      builder: (context, state) =>
          NewsFormPage(newsId: state.pathParameters['id']),
    ),

    GoRoute(path: '/news', builder: (context, state) => const NewsListPage()),

    GoRoute(
      path: '/news/:id',
      builder: (context, state) =>
          NewsDetailPage(id: state.pathParameters['id']!),
    ),

    GoRoute(
      path: '/appointments',
      builder: (context, state) => const AppointmentsPage(),
    ),

    GoRoute(
      path: '/appointments/create',
      builder: (context, state) => const CreateAppointmentPage(),
    ),

    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),

    GoRoute(
      path: '/admin/appointments',
      builder: (context, state) => const AdminAppointmentsPage(),
    ),

    GoRoute(
      path: '/doctor-complete/:id',
      builder: (context, state) =>
          DoctorCompletePage(appointmentId: state.pathParameters['id']!),
    ),

    GoRoute(
      path: '/admin/appointment/:id',
      builder: (context, state) => AdminAppointmentDetailPage(
        appointmentId: state.pathParameters['id']!,
      ),
    ),

    GoRoute(path: '/consult', builder: (context, state) => const ConsultPage()),
  ],
);
