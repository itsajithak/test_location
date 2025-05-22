import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'test_app_channel',
    'Location Tracking',
    description: 'This channel is used for background location tracking.',
    importance: Importance.high,
  );
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  await service.configure(
    iosConfiguration: IosConfiguration(),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: channel.id,
      initialNotificationTitle: 'Location Tracking',
      initialNotificationContent: 'Waiting for location updates...',
      foregroundServiceNotificationId: 888,
    ),
  );
  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Removed DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('startLocationUpdates').listen((event) async {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          forceAndroidLocationManager: true,
        );

        final prefs = await SharedPreferences.getInstance();
        final existingData = prefs.getStringList('location_history') ?? [];
        final newLocation = {
          'lat': position.latitude,
          'lng': position.longitude,
        };
        existingData.add(jsonEncode(newLocation));
        await prefs.setStringList('location_history', existingData);
        final decodedList = existingData
            .map((e) => jsonDecode(e) as Map<String, dynamic>)
            .toList();
        service.invoke('locationUpdate', {'locations': decodedList});
        debugPrint(
            '*** Background Location sent: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        debugPrint('Error getting location: $e');
      }
    });
  });

  service.on('startMonitoring').listen(
        (event) async {
      debugPrint("Received startMonitoring event in service isolate");
      await flutterLocalNotificationsPlugin.show(
        999,
        'Tracking Started',
        'Start monitoring',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_app_channel',
            'Location Tracking',
            channelDescription:
            'This channel is used for background location tracking.',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    },
  );

  service.on('stopMonitoring').listen(
        (event) async {
      await flutterLocalNotificationsPlugin.show(
        999,
        'Tracking Stopped',
        'Start stopping',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_app_channel',
            'Location Tracking',
            channelDescription:
            'This channel is used for background location tracking.',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    },
  );
}

Future<void> requestPermissions() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint("Location permission not granted");
      return;
    }
  }
}
