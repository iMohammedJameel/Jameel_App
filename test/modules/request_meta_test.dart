import 'package:flutter_test/flutter_test.dart';
import 'package:jameel/modules/requests_screen/request_meta.dart';

void main() {
  group('RequestMeta', () {
    test('every declared request type has its own metadata', () {
      for (final type in RequestMeta.types) {
        expect(
          RequestMeta.of(type).titleKey,
          isNot('request_unknown'),
          reason: '"$type" fell through to the unknown fallback',
        );
      }
    });

    test('an unknown type falls back to the generic metadata', () {
      expect(RequestMeta.of('something-else').titleKey, 'request_unknown');
    });
  });
}
