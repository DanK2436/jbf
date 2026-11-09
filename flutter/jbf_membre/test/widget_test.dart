import 'package:flutter_test/flutter_test.dart';
import 'package:jbf_membre/config/app_config.dart';
import 'package:jbf_membre/services/otp_service.dart';
import 'package:jbf_membre/services/supabase_service.dart';

void main() {
  test('JBF Membre config & services', () {
    expect(AppConfig.appName, 'JBF Service Membre');
    final otp = OtpService();
    expect(otp.verifyOtp('000000'), false);
    final supabase = SupabaseService();
    expect(supabase, isNotNull);
  });
}
