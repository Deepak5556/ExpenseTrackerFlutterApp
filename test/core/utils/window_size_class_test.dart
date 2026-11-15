import 'package:expense_journal_budget/core/utils/window_size_class.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('windowSizeClassForWidth', () {
    test('uses compact below 600 dp', () {
      expect(windowSizeClassForWidth(320), WindowSizeClass.compact);
      expect(windowSizeClassForWidth(599.9), WindowSizeClass.compact);
    });

    test('uses medium from 600 through 839 dp', () {
      expect(windowSizeClassForWidth(600), WindowSizeClass.medium);
      expect(windowSizeClassForWidth(839.9), WindowSizeClass.medium);
    });

    test('uses expanded at 840 dp and wider', () {
      expect(windowSizeClassForWidth(840), WindowSizeClass.expanded);
      expect(windowSizeClassForWidth(1024), WindowSizeClass.expanded);
    });
  });
}
