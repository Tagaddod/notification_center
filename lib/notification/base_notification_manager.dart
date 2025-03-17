

abstract class BaseNotificationManager {
Future<void> initializeNotification();
Future<bool> requestNotificationPermission();
Future<void> onBackgroundMessageRecieved(dynamic handler);
  

}