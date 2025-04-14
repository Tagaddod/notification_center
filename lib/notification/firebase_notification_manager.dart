import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:notification_center/notification/models/notification_model.dart';

import 'base_notification_manager.dart';

class FirebaseNotificationManager implements BaseNotificationManager {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  final StreamController<NotificationMessage> _notificationStreamController =
      StreamController<NotificationMessage>.broadcast();
  final StreamController<String?> _userTokenStreamController =
      StreamController<String?>();
  @override
  Stream<String?> get userTokenStream => _userTokenStreamController.stream;
  @override
  Stream<NotificationMessage> get notificationStream =>
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
      debugPrint("Notification received: ${message.notification?.title}");
      if (message.notification != null) {
        _notificationStreamController.add(
          NotificationMessage(
            title: message.notification?.title,
            body: message.notification?.body,
            data: message.data,
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.notification != null) {
        _notificationStreamController.add(
          NotificationMessage(
            title: message.notification?.title,
            body: message.notification?.body,
            data: message.data,
          ),
        );
      }
    });

    RemoteMessage? initialMessage = await firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _notificationStreamController.add(
        NotificationMessage(
          title: initialMessage.notification?.title,
          body: initialMessage.notification?.body,
          data: initialMessage.data,
        ),
      );
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

  @override
  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }
}
