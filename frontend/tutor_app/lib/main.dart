import 'package:flutter/material.dart';
import 'screens/auth_screen.dart'; // Importamos a tela de autenticação
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const TutorAcademicoApp());
}

class TutorAcademicoApp extends StatelessWidget {
  const TutorAcademicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tutor Acadêmico',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.dark),
      home: const WelcomeScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    const primaryColor = Color(0xFF4A90E2); // Um azul moderno e elegante
    var baseTheme = ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
      ),
      useMaterial3: true,
    );

    return baseTheme.copyWith(
      appBarTheme: AppBarTheme(
        // Remove a sombra para um visual mais limpo
        elevation: 0,
        // Define a cor de fundo do AppBar
        backgroundColor: baseTheme.scaffoldBackgroundColor,
      ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}