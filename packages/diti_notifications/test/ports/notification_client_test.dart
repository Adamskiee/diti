import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:diti_notifications/src/ports/notification_client.dart';
import '../mocks/mock_notification_client.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(FakeNotificationDetails());
    registerFallbackValue(FakeTZDateTime());
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
  });

  group('NotificationClient contract', () {
    test('MockNotificationClient implements NotificationClient interface',
        () async {
      final NotificationClient mock = MockNotificationClient();
      when(() => mock.cancel(any())).thenAnswer((_) async {});

      await mock.cancel(42);

      verify(() => mock.cancel(42)).called(1);
    });
  });
}
