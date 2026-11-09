import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'JBF Service Membre';
  static const String appSubtitle = 'Espace Collaborateur & Équipes Terrain (RDC)';
  static const String version = '2.0.0';

  // Base API & Supabase
  static const String apiBaseUrl = 'http://localhost:3001/api';
  static const String fallbackApiUrl = 'http://localhost:8080/api';
  static const String supabaseUrl = 'https://dvzwqxcaiagczyonrhsg.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2endxeGNhaWFnY3p5b25yaHNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1ODEzNzIsImV4cCI6MjEwNTE1NzM3Mn0.uam5Z-d6SWS9-4Ly9f0ircJPryFJwOXbNp9_alHHl-o';

  // Demo Credentials for field access
  static const String defaultMatricule = 'JBF-M-2026-012';
  static const String defaultPassword = 'Membre2026!';

  // Brand Palette
  static const Color brandPink = Color(0xFFE6007E);
  static const Color brandPinkDark = Color(0xFFC4006B);
  static const Color brandPinkLight = Color(0xFFFF2E99);
  static const Color brandPinkTint = Color(0xFFFFF0F7);
  static const Color grayBase = Color(0xFFAAAAAA);
  static const Color grayDark = Color(0xFF404048);
  static const Color whiteSurface = Color(0xFFFFFFFF);
  static const Color blackText = Color(0xFF0C0C0E);
  static const Color successGreen = Color(0xFF047857);
  static const Color warningOrange = Color(0xFFB45309);
  static const Color dangerRed = Color(0xFFDC2626);
}
