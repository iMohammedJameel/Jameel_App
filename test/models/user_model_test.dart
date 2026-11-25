import 'package:flutter_test/flutter_test.dart';
import 'package:jameel/models/user_model.dart';

void main() {
  group('JameelUserModel', () {
    test('toMap / fromMap round trip keeps every field', () {
      final user = JameelUserModel(
        uId: 'u1',
        userName: 'Sara',
        userEmail: 'sara@example.com',
        userDepartment: 'HR',
        userJoinDate: DateTime(2022, 3, 14),
      );

      final copy = JameelUserModel.fromMap(user.toMap());

      expect(copy.uId, 'u1');
      expect(copy.userName, 'Sara');
      expect(copy.userEmail, 'sara@example.com');
      expect(copy.userDepartment, 'HR');
      expect(copy.userJoinDate, DateTime(2022, 3, 14));
    });

    test('fromMap tolerates a missing or malformed join date', () {
      expect(JameelUserModel.fromMap({}).userJoinDate, isNull);
      expect(
        JameelUserModel.fromMap({'userJoinDate': 'not-a-date'}).userJoinDate,
        isNull,
      );
    });
  });
}
