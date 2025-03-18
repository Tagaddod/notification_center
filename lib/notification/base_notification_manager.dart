abstract class BaseNotificationManager {
  Future<void> initializeNotification();
  Future<bool> requestNotificationPermission();
  Future<void> onBackgroundMessageRecieved(dynamic handler);
  // Add these:
  Stream<Map<String, dynamic>> get notificationStream;
  Stream<String?> get userTokenStream;
}
