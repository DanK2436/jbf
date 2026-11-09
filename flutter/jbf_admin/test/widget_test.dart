import 'package:flutter_test/flutter_test.dart';
import 'package:jbf_admin/config/app_config.dart';
import 'package:jbf_admin/services/otp_service.dart';
import 'package:jbf_admin/services/supabase_service.dart';

void main() {
  test('JBF Admin config & services', () {
    expect(AppConfig.appName, 'JBF Service Admin');
    final otp = OtpService();
    expect(otp.verifyOtp('000000'), false);
    final supabase = SupabaseService();
    expect(supabase, isNotNull);
  });
}
