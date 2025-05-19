import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/components/custom_elevated_button.dart';
import 'package:test_app/screens/test_app_screen/device_screens/mobile_screen.dart';
import 'package:test_app/screens/test_app_screen/device_screens/pc_screen.dart';
import 'package:test_app/screens/test_app_screen/device_screens/tab_screen.dart';
import 'package:test_app/screens/test_app_screen/test_app_screen_controller.dart';
import 'package:test_app/utils/app_colors.dart';
import 'package:test_app/utils/app_widget_utils.dart';
import 'package:web_socket_channel/io.dart';

class TestAppScreen extends StatefulWidget {
  const TestAppScreen({super.key});

  @override
  State<TestAppScreen> createState() => _TestAppScreenState();
}

class _TestAppScreenState extends State<TestAppScreen> {
  final _testScreenCon = TestAppScreenConImpl();
  final _appColors = AppColors();
  IOWebSocketChannel? _channel;
  StreamSubscription<Position>? _position;
  Timer? _locationPollTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialLocationHistory();
    _startPollingLocationUpdates();
    _testScreenCon.locationHistoryStreamCon.listen((event) {
      debugPrint('the event is ${event.length}');
      setState(() {});
    });
  }

  void _startPollingLocationUpdates() {
    _locationPollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _loadInitialLocationHistory();
    });
  }

  Future<void> _loadInitialLocationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = await prefs.getStringList('location_history') ?? [];

    final decodedList =
        storedData.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    debugPrint('the decode list is ${decodedList.length}');

    _testScreenCon.locationHistoryStream(decodedList);
  }

  @override
  void dispose() {
    _position?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: _appColors.whiteColor,
      body: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.only(left: 18, right: 18, top: 50, bottom: 18),
            decoration: BoxDecoration(color: _appColors.backgroundBlack),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppWidgetUtils.buildTextWidget('Test App',
                      color: _appColors.whiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 23),
                ),
                AppWidgetUtils.buildSizedBox(custHeight: 18),
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
              ],
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _testScreenCon.locationHistoryStreamCon,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No location data found"),
                );
              }
              final locations = snapshot.data!;

              if (screenWidth < 600) {
                return Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final location = locations[index];
                      final lat = location['lat'];
                      final lng = location['lng'];

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text("Lat: $lat"),
                          subtitle: Text("Lng: $lng"),
                          trailing: Text("No: ${index + 1}"),
                        ),
                      );
                    },
                  ),
                );
              }
              return Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: locations.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3 / 0.7,),
                  itemBuilder: (context, index) {
                    final location = locations[index];
                    final lat = location['lat'];
                    final lng = location['lng'];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text("Lat: $lat"),
                        subtitle: Text("Lng: $lng"),
                        trailing: Text("No: ${index + 1}"),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildButtons({bool? isPcOrTab}) {
    return [
      CustomElevatedButton(
        buttonBackgroundColor: _appColors.blueColor,
        fontColor: _appColors.whiteColor,
        width:
            isPcOrTab == true ? MediaQuery.of(context).size.width / 2.5 : null,
        height: MediaQuery.of(context).size.height / 15,
        text: 'Location Permission',
        fontSize: 16,
        onPressed: () {
          _checkPermission();
        },
      ),
      CustomElevatedButton(
        buttonBackgroundColor: _appColors.yellowColor,
        fontColor: _appColors.blackColor,
        onPressed: () {
          _checkNotificationPermission();
        },
        width:
            isPcOrTab == true ? MediaQuery.of(context).size.width / 2.5 : null,
        height: MediaQuery.of(context).size.height / 15,
        text: 'Notification Permission',
        fontSize: 16,
      ),
      CustomElevatedButton(
        buttonBackgroundColor: _appColors.greenColor,
        fontColor: _appColors.whiteColor,
        width:
            isPcOrTab == true ? MediaQuery.of(context).size.width / 2.5 : null,
        height: MediaQuery.of(context).size.height / 15,
        text: 'Start Monitoring',
        fontSize: 16,
        onPressed: () async {
          // _startMonitoring();
          // await FlutterBackgroundService().startService();
          final service = FlutterBackgroundService();
          await service.startService();
          service.invoke('startMonitoring');
          service.invoke("startLocationUpdates");
        },
      ),
      CustomElevatedButton(
        buttonBackgroundColor: _appColors.redColor,
        fontColor: _appColors.whiteColor,
        width:
            isPcOrTab == true ? MediaQuery.of(context).size.width / 2.5 : null,
        height: MediaQuery.of(context).size.height / 15,
        text: 'Stop Monitoring',
        fontSize: 16,
        onPressed: () async {
          // _stopMonitoring();
          final service = FlutterBackgroundService();
          await service.startService();
          service.invoke('stopMonitoring');
          service.invoke("stopService");
        },
      ),
    ];
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

  Future<void> _checkNotificationPermission() async {
    var status = await Permission.notification.status;
    if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
      status = await Permission.notification.request();
    }
    if (status.isGranted) {
      debugPrint('Notification permission granted');
    } else {
      debugPrint('Notification permission denied');
    }
  }
}
