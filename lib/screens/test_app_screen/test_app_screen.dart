import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_app/components/custom_elevated_button.dart';
import 'package:test_app/screens/test_app_screen/device_screens/mobile_screen.dart';
import 'package:test_app/screens/test_app_screen/device_screens/pc_screen.dart';
import 'package:test_app/screens/test_app_screen/device_screens/tab_screen.dart';
import 'package:test_app/screens/test_app_screen/location_bloc/location_bloc.dart';
import 'package:test_app/utils/app_colors.dart';
import 'package:test_app/utils/app_widget_utils.dart';

class TestAppScreen extends StatefulWidget {
  const TestAppScreen({super.key});

  @override
  State<TestAppScreen> createState() => _TestAppScreenState();
}

class _TestAppScreenState extends State<TestAppScreen> {
  final _appColors = AppColors();
  StreamSubscription<Position>? _position;
  Timer? _locationPollTimer;
  final ReceivePort _receivePort = ReceivePort();

  @override
  void initState() {
    super.initState();
    _receiveLocationPort();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 App resumed — re-registering ReceivePort');
      _receiveLocationPort(); // Safety re-register
    }
  }

  _receiveLocationPort() {
    IsolateNameServer.removePortNameMapping('location_updates_port');
    IsolateNameServer.registerPortWithName(
        _receivePort.sendPort, 'location_updates_port');
    _receivePort.listen((data) {
      if (data is List) {
        final decodedList =
            data.map((e) => Map<String, dynamic>.from(e)).toList();
        debugPrint('inside the init state *** ${decodedList.length}');
        context.read<LocationBloc>().add(LatLongFetchEvent(decodedList));
      }
    });
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('location_updates_port');
    _receivePort.close();
    _position?.cancel();
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
          BlocBuilder<LocationBloc, LocationState>(
            builder: (context, state) {
              if (state is FetchLocationState) {
                final locations = state.locationList;
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
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppWidgetUtils.buildTextWidget(
                                    'Request ${index + 1}',
                                    fontWeight: FontWeight.w700),
                                Row(
                                  children: [
                                    AppWidgetUtils.buildTextWidget('Lat: $lat'),
                                    AppWidgetUtils.buildSizedBox(custWidth: 12),
                                    AppWidgetUtils.buildTextWidget('Lng: $lng'),
                                  ],
                                )
                              ],
                            ),
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3 / 0.7,
                    ),
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

              return AppWidgetUtils.buildSizedBox();
            },
          )
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
          showDialog(
            context: context,
            builder: (context) {
              return _buildAlertDialog(true);
            },
          );
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
          showDialog(
            context: context,
            builder: (context) {
              return _buildAlertDialog(false);
            },
          );
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

  AlertDialog _buildAlertDialog(bool isStart) {
    return AlertDialog(
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width / 4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeaderDialog(isStart),
            const Divider(),
            _buildContent(isStart),
            AppWidgetUtils.buildSizedBox(custHeight: 12),
            _buildMonitoringBtns(isStart)
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderDialog(bool isStart) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppWidgetUtils.buildTextWidget(
            isStart ? 'Start Monitoring' : 'Stop Monitoring',
            fontSize: 18,
            fontWeight: FontWeight.bold),
        IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close))
      ],
    );
  }

  Widget _buildContent(bool isStart) {
    return AppWidgetUtils.buildTextWidget(
        'Are you sure want to ${isStart ? 'start' : 'stop'} monitoring',
        textAlign: TextAlign.center);
  }

  Widget _buildMonitoringBtns(bool isStart) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomElevatedButton(
          buttonBackgroundColor: _appColors.redColor,
          fontColor: _appColors.whiteColor,
          width: MediaQuery.sizeOf(context).width / 4,
          text: 'No',
          fontSize: 16,
          onPressed: () => Navigator.pop(context),
        ),
        AppWidgetUtils.buildSizedBox(custWidth: 12),
        CustomElevatedButton(
          text: 'YES',
          fontSize: 16,
          buttonBackgroundColor: _appColors.greenColor,
          fontColor: _appColors.whiteColor,
          width: MediaQuery.sizeOf(context).width / 4,
          onPressed: isStart
              ? () async {
                  final service = FlutterBackgroundService();
                  await service.startService();
                  service.invoke('startMonitoring');
                  service.invoke("startLocationUpdates");
                  Navigator.pop(context);
                }
              : () async {
                  final service = FlutterBackgroundService();
                  await service.startService();
                  service.invoke('stopMonitoring');
                  service.invoke("stopService");
                  Navigator.pop(context);
                },
        )
      ],
    );
  }
}
