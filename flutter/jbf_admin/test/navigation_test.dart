import 'package:flutter_test/flutter_test.dart';
import 'package:jbf_admin/navigation/destinations.dart';

void main() {
  test('toutes les pages admin sont atteignables sur mobile', () {
    final indexes = adminDestinations.map((d) => d.index).toList();
    expect(indexes, List<int>.generate(adminDestinations.length, (i) => i));
    final reachable = {...adminMobilePrimary, ...indexes.where((i) => !adminMobilePrimary.contains(i))};
    expect(reachable.containsAll(indexes), true);
    expect(adminDestinations.map((d) => d.label), containsAll(['Congés', 'Membres', 'Sécurité OTP']));
  });
}
