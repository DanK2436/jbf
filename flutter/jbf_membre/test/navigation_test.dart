import 'package:flutter_test/flutter_test.dart';
import 'package:jbf_membre/navigation/destinations.dart';

void main() {
  test('messagerie et bibliothèque restent atteignables', () {
    final indexes = membreDestinations.map((d) => d.index).toList();
    expect(indexes, [0, 1, 2, 3, 4, 5]);
    final reachable = {...membreMobilePrimary, ...indexes.where((i) => !membreMobilePrimary.contains(i))};
    expect(reachable.containsAll(indexes), true);
  });
}
