import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';
import 'screens/ngo/ngo_dashboard_screen.dart';
import 'screens/ngo/ngo_register_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/inspector/inspector_flow_screen.dart';
import 'screens/inspector/inspector_portal_screen.dart';

void main() {
  runApp(const DrishtiApp());
}

class DrishtiApp extends StatelessWidget {
  const DrishtiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drishti Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFF0F2942),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF16A34A),
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => LandingScreen(
                onSelectNgoPortal: () =>
                    Navigator.pushNamed(context, '/ngo/dashboard'),
                onSelectNgoRegister: () =>
                    Navigator.pushNamed(context, '/ngo/register'),
                onSelectAdminPortal: () =>
                    Navigator.pushNamed(context, '/admin/dashboard'),
                onSelectInspectorPortal: () =>
                    Navigator.pushNamed(context, '/inspector'),
              ),
            );
          case '/ngo/dashboard':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => NgoDashboardScreen(
                onSwitchPortal: () =>
                    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
              ),
            );
          case '/ngo/register':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => NgoRegisterScreen(
                onCancel: () => Navigator.pop(context),
                onRegistered: () => Navigator.pushReplacementNamed(
                  context, '/ngo/dashboard'),
              ),
            );
          case '/admin/dashboard':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const AdminShell(),
            );
          case '/inspector':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const InspectorPortalScreen(),
            );
          case '/inspector/flow':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const InspectorFlowScreen(),
            );
          default:
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const Scaffold(
                body: Center(child: Text('Page not found')),
              ),
            );
        }
      },
    );
  }
}
