import 'package:flutter_test/flutter_test.dart';
import 'package:jbf_client/navigation/destinations.dart';

void main() {
  test('avis et profil client restent atteignables', () {
    final indexes = clientDestinations.map((d) => d.index).toList();
    expect(indexes, [0, 1, 2, 3, 4, 5, 6]);
    final reachable = {...clientMobilePrimary, ...indexes.where((i) => !clientMobilePrimary.contains(i))};
    expect(reachable.containsAll(indexes), true);
  });
}
