import 'package:notification_center/notification/models/notification_model.dart';

abstract class BaseNotificationManager {
  Future<void> initializeNotification();
  Future<bool> requestNotificationPermission();
  Future<void> onBackgroundMessageRecieved(dynamic handler);
  Stream<NotificationMessage> get notificationStream;
  Stream<String?> get userTokenStream;
}
