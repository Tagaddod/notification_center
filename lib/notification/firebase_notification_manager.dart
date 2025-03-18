import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'base_notification_manager.dart';

class FirebaseNotificationManager implements BaseNotificationManager {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String?> _userTokenStreamController =
      StreamController<String?>();
  @override
  Stream<String?> get userTokenStream => _userTokenStreamController.stream;
  @override
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;

  @override
  Future<void> initializeNotification() async {
    try {
      final permissionStatus = await requestNotificationPermission();

      if (permissionStatus) {
        await _getUserToken();
        _listenOnRefreshToken();

        listenOnFirebaseNotifications();
      }
    } on Exception catch (e) {
      print(e);
    }
  }

  _getUserToken() async {
    final token = await firebaseMessaging.getToken();
    _userTokenStreamController.add(token);
    return token;
  }

  _listenOnRefreshToken() {
    firebaseMessaging.onTokenRefresh.listen((String token) {
      print("refreshed Token $token");
      _userTokenStreamController.add(token);
    });
  }

  Future<void> listenOnFirebaseNotifications() async {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _notificationStreamController.add(message.data);
    });

    // Background/terminated messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _notificationStreamController.add(message.data);
    });

    // Get initial message (if app was terminated and opened via a notification)
    RemoteMessage? initialMessage = await firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _notificationStreamController.add(initialMessage.data);
    }
  }

  @override
  Future<void> onBackgroundMessageRecieved(dynamic handler) async {
    FirebaseMessaging.onBackgroundMessage(handler);
  }

  @override
  Future<bool> requestNotificationPermission() async {
    final notificationSettings = await firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );
    return notificationSettings.authorizationStatus ==
        AuthorizationStatus.authorized;
  }
}
