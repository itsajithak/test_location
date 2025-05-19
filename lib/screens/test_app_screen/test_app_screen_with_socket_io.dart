import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:test_app/components/custom_elevated_button.dart';
import 'package:test_app/screens/test_app_screen/device_screens/mobile_screen.dart';
import 'package:test_app/screens/test_app_screen/device_screens/pc_screen.dart';
import 'package:test_app/screens/test_app_screen/device_screens/tab_screen.dart';
import 'package:test_app/screens/test_app_screen/test_app_screen_controller.dart';

class TestAppScreen extends StatefulWidget {
  const TestAppScreen({super.key});

  @override
  State<TestAppScreen> createState() => _TestAppScreenState();
}

class _TestAppScreenState extends State<TestAppScreen> {
  final _testScreenCon = TestAppScreenConImpl();
  IO.Socket? _socket;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  void _initializeSocket() {
    _socket = IO.io(
      'https://your-socket-server.com',
      IO.OptionBuilder()
          .setTransports(['websocket']) // for Flutter or Dart VM
          .disableAutoConnect()         // <- disables auto-connect (opposite of setAutoConnect)
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('Connected to Socket.IO server');
    });

    _socket!.on('locationUpdate', (data) {
      _testScreenCon.userLatLong = {
        'lat': data['lat'],
        'long': data['lng'],
      };
      _testScreenCon.locationStream(true);
      debugPrint("Driver's new location: ${data['lat']}, ${data['lng']}");
    });

    _socket!.onDisconnect((_) {
      debugPrint('Disconnected from Socket.IO server');
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _socket?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test App'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                if (screenWidth < 600) {
                  return MobileScreen(
                    buttons: _buildButtons(),
                  );
                } else if (screenWidth < 900) {
                  return TabScreen(
                    buttons: _buildButtons(isPcOrTab: true),
                  );
                } else {
                  return PcScreen(
                    buttons: _buildButtons(),
                  );
                }
              },
            ),
            const SizedBox(height: 100),
            StreamBuilder(
              stream: _testScreenCon.locationStreamCon,
              builder: (context, snapshot) {
                return Text(
                  softWrap: true,
                  textAlign: TextAlign.center,
                  'User latitude: ${_testScreenCon.userLatLong['lat'] ?? ''}'
                      '\n User longitude: ${_testScreenCon.userLatLong['long'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildButtons({bool? isPcOrTab}) {
    return [
      CustomElevatedButton(
        width: isPcOrTab == true ? MediaQuery.of(context).size.width / 2.5 : null,
        height: MediaQuery.of(context).size.height / 18,
        text: 'Location Permission',
        fontSize: 16,
        onPressed: _checkPermission,
      ),
      CustomElevatedButton(
        width: isPcOrTab == true ? MediaQuery.of(context).size.width / 2.5 : null,
        height: MediaQuery.of(context).size.height / 18,
        text: 'Notification Permission',
        fontSize: 16,
      ),
      CustomElevatedButton(
        width: isPcOrTab == true ? MediaQuery.of(context).size.width / 2.5 : null,
        height: MediaQuery.of(context).size.height / 18,
        text: 'Start Monitoring',
        fontSize: 16,
        onPressed: _startMonitoring,
      ),
      CustomElevatedButton(
        width: isPcOrTab == true ? MediaQuery.of(context).size.width / 2.5 : null,
        height: MediaQuery.of(context).size.height / 18,
        text: 'Stop Monitoring',
        fontSize: 16,
        onPressed: _stopMonitoring,
      ),
    ];
  }

  void _startMonitoring() {
    if (_socket == null || !_socket!.connected) {
      _initializeSocket();
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      _socket?.emit('sendLocation', {
        'lat': position.latitude,
        'lng': position.longitude,
      });
    });
  }

  void _stopMonitoring() {
    _positionStream?.cancel();
    _positionStream = null;
    _socket?.disconnect();
  }

  Future<void> _checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }
  }
}
