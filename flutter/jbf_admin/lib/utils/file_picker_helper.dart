import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class LocalPickedFile {
  final String path;
  final String name;
  final String sizeFormatted;
  final int sizeInBytes;
  final Uint8List bytes;

  LocalPickedFile({
    required this.path,
    required this.name,
    required this.sizeFormatted,
    required this.sizeInBytes,
    required this.bytes,
  });
}

class FilePickerHelper {
  /// Ouvre l'explorateur de fichiers natif (Windows Forms / STA) pour sélectionner un fichier
  static Future<LocalPickedFile?> pickFile({
    String filter = 'Tous les fichiers (*.*)|*.*',
    String title = 'Sélectionner un fichier',
  }) async {
    if (kIsWeb) {
      return null;
    }

    if (Platform.isWindows) {
      try {
        final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$dialog = New-Object System.Windows.Forms.OpenFileDialog
\$dialog.Filter = "$filter"
\$dialog.Title = "$title"
\$dialog.CheckFileExists = \$true
\$dialog.RestoreDirectory = \$true
if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    [Console]::Out.Write(\$dialog.FileName)
}
''';
        final result = await Process.run('powershell', ['-NoProfile', '-STA', '-Command', script]);
        if (result.exitCode == 0) {
          final chosenPath = result.stdout.toString().trim();
          if (chosenPath.isNotEmpty) {
            return await loadFromFilePath(chosenPath);
          }
        }
      } catch (e) {
        debugPrint('Erreur lors du file picker natif: \$e');
      }
    }

    return null;
  }

  /// Charge et lit un fichier depuis un chemin local
  static Future<LocalPickedFile?> loadFromFilePath(String path) async {
    try {
      final file = File(path.trim());
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final sizeInBytes = bytes.length;
      final fileName = path.split(Platform.isWindows ? '\\' : '/').last;

      String sizeFormatted;
      if (sizeInBytes < 1024) {
        sizeFormatted = '\$sizeInBytes B';
      } else if (sizeInBytes < 1024 * 1024) {
        sizeFormatted = '\${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
      } else {
        sizeFormatted = '\${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }

      return LocalPickedFile(
        path: file.path,
        name: fileName,
        sizeFormatted: sizeFormatted,
        sizeInBytes: sizeInBytes,
        bytes: bytes,
      );
    } catch (_) {
      return null;
    }
  }

  /// Détermine le type MIME en fonction de l'extension
  static String getMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx')) return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.avi')) return 'video/x-msvideo';
    return 'application/octet-stream';
  }

  /// Téléverse le fichier vers Supabase Storage (bucket 'documents' ou 'galerie')
  /// et retourne l'URL publique directe accessible.
  static Future<String?> uploadToSupabase({
    required LocalPickedFile file,
    required String bucket,
  }) async {
    final cleanFileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
    final mimeType = getMimeType(file.name);

    // 1. Envoi vers Supabase Storage API
    try {
      final uploadUrl = '${AppConfig.supabaseUrl}/storage/v1/object/$bucket/$cleanFileName';
      final res = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': mimeType,
          'x-upsert': 'true',
        },
        body: file.bytes,
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return '${AppConfig.supabaseUrl}/storage/v1/object/public/$bucket/$cleanFileName';
      }
    } catch (_) {}

    // 2. Si image et échec du bucket, encodage Base64 Data URI
    if (mimeType.startsWith('image/')) {
      final b64 = base64Encode(file.bytes);
      return 'data:$mimeType;base64,$b64';
    }

    return null;
  }
}
