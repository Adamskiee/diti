import 'package:mocktail/mocktail.dart';
import 'package:focus_flow_notifications/src/ports/notification_client.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class FakeNotificationDetails extends Fake implements NotificationDetails {}
class FakeTZDateTime extends Fake implements tz.TZDateTime {}

class MockNotificationClient extends Mock implements NotificationClient {}
