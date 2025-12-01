import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/home_student.dart';
import 'screens/teacher/home_teacher.dart';
import 'screens/admin/admin_panel.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'MusiClase',
        theme: _buildAppTheme(),
        home: AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    if (authService.usuario == null) {
      return LoginScreen();
    } else {
      final tipo = authService.usuario!.tipo;
      if (tipo == 'profesor') {
        return HomeTeacherScreen();
      } else if (tipo == 'admin') {
        return AdminPanel();
      } else {
        return HomeStudentScreen();
      }
    }
  }
}

ThemeData _buildAppTheme() {
  const color1 = Color(0xFF69A198);
  const color2 = Color(0xFFFAF6F3);
  const color3 = Color(0xFFE3BC92);
  const color4 = Color(0xFF16120F);

  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: color1,
    onPrimary: Colors.white,
    secondary: color3,
    onSecondary: color4,
    error: Colors.red.shade700,
    onError: Colors.white,
    surface: color2,
    onSurface: color4,
    tertiary: color3,
    onTertiary: Colors.white,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 3,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.tertiary,
      foregroundColor: scheme.onTertiary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textTheme: const TextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.secondary.withOpacity(0.15),
      selectedColor: scheme.secondary,
      labelStyle: TextStyle(color: scheme.onSurface),
      secondaryLabelStyle: TextStyle(color: scheme.onSecondary),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: scheme.surface,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
