import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_esp32_ble_example/bluetooth_device_list.dart';
import 'package:permission_handler/permission_handler.dart';


void main() {
  if (Platform.isAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
    [
      Permission.location,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan
    ].request().then((status) {
      runApp(MyApp());
    });
  } else {
    runApp(MyApp());
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Blue Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FindDevicesScreen(),
    );
  }
}

