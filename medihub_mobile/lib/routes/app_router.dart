import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/splash/presentation/splash_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/admin/presentation/admin_page.dart';
import '../features/news/presentation/news_admin_page.dart';
import '../features/news/presentation/news_form_page.dart';
import '../features/news/presentation/news_list_page.dart';
import '../features/news/presentation/news_detail_page.dart';
import '../features/appointment/presentation/appointments_page.dart';
import '../features/appointment/presentation/create_appointment_page.dart';
import '../features/admin/presentation/admin_appointments_page.dart';
import '../features/doctor/presentation/doctor_complete_page.dart';
import '../features/admin/presentation/admin_appointment_detail_page.dart';
import '../../features/consult/presentation/consult_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
        path: '/profile',
        builder: (context, state) =>
            const ProfilePage(),
        ),

    GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminPage(),
        ),
    GoRoute(
        path: '/admin/news',
        builder: (_, __) =>
        const NewsAdminPage(),
    ),

    GoRoute(
        path: '/admin/news/create',
        builder: (_, __) =>
        const NewsFormPage(),
    ),

    GoRoute(
        path: '/admin/news/edit/:id',
        builder: (context, state) =>
        NewsFormPage(
            newsId: state.pathParameters['id'],
        ),
    ),

    GoRoute(
        path: '/news',
        builder: (_, __) =>
            const NewsListPage(),
        ),

    GoRoute(
        path: '/news/:id',
        builder: (
            context,
            state,
        ) =>
            NewsDetailPage(
            id:
                state.pathParameters[
                    'id']!,
        ),
    ),

    GoRoute(
        path: '/appointments',
        builder: (_, __) =>
            const AppointmentsPage(),
    ),

    GoRoute(
        path: '/appointments/create',
        builder: (_, __) =>
            const CreateAppointmentPage(),
    ),

    GoRoute(
    path: '/admin/appointments',
    builder: (_, __) =>
        const AdminAppointmentsPage(),
    ),

    GoRoute(
    path: '/doctor-complete/:id',
    builder: (context, state) =>
        DoctorCompletePage(
        appointmentId:
            state.pathParameters['id']!,
        ),
    ),

    GoRoute(
    path: '/admin/appointment/:id',
    builder: (context, state) =>
        AdminAppointmentDetailPage(
        appointmentId:
            state.pathParameters['id']!,
            ),
    ),
    
    GoRoute(
    path: '/consult',
    builder: (
        context,
        state,
    ) =>
        const ConsultPage(),
    ),

  ],
);