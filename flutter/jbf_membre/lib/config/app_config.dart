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

  // Brand Palette
  static const Color brandPink = Color(0xFFDE026A);
  static const Color brandPinkDark = Color(0xFFC8025F);
  static const Color brandPinkLight = Color(0xFFF4AECF);
  static const Color brandPinkTint = Color(0xFFFADCEA);
  static const Color grayBase = Color(0xFFF6F6F7);
  static const Color grayDark = Color(0xFF3F3F46);
  static const Color whiteSurface = Color(0xFFFFFFFF);
  static const Color blackText = Color(0xFF0C0C0E);
  static const Color successGreen = Color(0xFF047857);
  static const Color warningOrange = Color(0xFFB45309);
  static const Color dangerRed = Color(0xFFDC2626);
}
