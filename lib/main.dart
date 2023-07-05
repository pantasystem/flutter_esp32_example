import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_esp32_ble_example/bluetooth_constants.dart';
import 'package:permission_handler/permission_handler.dart';

// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

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

class FindDevicesScreen extends StatefulWidget {
  const FindDevicesScreen({super.key});

  @override
  State createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreen> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<BluetoothDevice> devices = [];

  @override
  void initState() {
    super.initState();
    startScan();
  }

  startScan() {
    devices = [];

    // Bluetoothデバイスをスキャンする
    flutterBlue.startScan(timeout: const Duration(seconds: 4));

    // スキャンした結果を受け取る
    flutterBlue.scanResults.listen((results) {
      setState(() {
        for (ScanResult result in results) {
          if (!devices.contains(result.device)) {
            // 対応しているserviceが含まれているのかを確認する
            final targetService = result.advertisementData.serviceUuids
                .contains(BluetoothConstants.serviceUuid);

            // 対応しているserviceが含まれていれば、デバイス一覧の配列に追加する。
            if (targetService) {
              devices.add(result.device);
            }
          }
        }
      });
    });

    // 以前に接続したことのあるBluetoothを取得する
    flutterBlue.connectedDevices.then((value) {
      setState(() {
        for (final result in value) {
          if (!devices.contains(result)) {
            devices.add(result);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    flutterBlue.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Devices'),
      ),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          return BluetoothDeviceListTile(device: devices[index]);
        },
      ),
    );
  }
}

/// Bluetoothデバイスの一覧を表示するWidget
/// 一つのWidgetに全てのコードを書いてしまうと、視認性（可読性）が低下してしまうので、
/// 実装を切り分けるようにしている。
class BluetoothDeviceListTile extends StatelessWidget {
  const BluetoothDeviceListTile({super.key, required this.device});

  final BluetoothDevice device;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(device.name),
      subtitle: StreamBuilder(
        stream: device.state,
        initialData: BluetoothDeviceState.disconnected,
        builder: (c, snapshot) {
          switch (snapshot.data) {
            case BluetoothDeviceState.connected:
              return const Text('Connected');
            case BluetoothDeviceState.connecting:
              return const Text('Connecting');
            case BluetoothDeviceState.disconnected:
              return const Text('Disconnected');
            case BluetoothDeviceState.disconnecting:
              return const Text('Disconnecting');
            default:
              return const Text('Unknown');
          }
        },
      ),
      onTap: () async {
        // タップされたら接続を開始する

        // 最新の接続状況を取得して、それに応じて接続処理を行なって画面遷移を行う
        device.state.first.then((value) async {
          switch (value) {
            case BluetoothDeviceState.connected:
              break;
            case BluetoothDeviceState.connecting:
              break;
            case BluetoothDeviceState.disconnected:
              await device.connect();
              break;
            case BluetoothDeviceState.disconnecting:
              await device.connect();
              break;
            default:
              return;
          }
        });
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DeviceScreen(device: device),
          ),
        );
      },
    );
  }
}

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key, required this.device});

  final BluetoothDevice device;

  @override
  State<StatefulWidget> createState() {
    return DeviceScreenState();
  }
}

class DeviceScreenState extends State<DeviceScreen> {
  DeviceScreenState();

  final _inputSsidController = TextEditingController();
  final _inputPasswordController = TextEditingController();
  String? _selectedColor;

  Future<void> writeToCharacteristic(
      BluetoothCharacteristic characteristic, String value) async {
    List<int> codeUnits = [];
    for (int i = 0; i < value.length; i++) {
      codeUnits.add(value.codeUnitAt(i));
    }
    await characteristic.write(codeUnits);
  }

  Future<BluetoothService?> findService() async {
    // 現在のBluetoothの接続状態を取得する
    final state = await widget.device.state.first;

    // 接続状態が切断状態の場合は、接続処理を行う
    if (state == BluetoothDeviceState.disconnected) {
      await widget.device.connect();
    }

    // Bluetoothのサービスを取得する
    final targetServices = await widget.device.discoverServices();

    // 対応しているサービスを探す
    return targetServices.firstWhereOrNull((element) {
      return element.uuid.toString() == BluetoothConstants.serviceUuid;
    });
  }

  /// デバイスにwifiの情報を送信する
  void sendWifiInformation() async {
    // 入力されたssidとpasswordの情報を取得する
    final ssid = _inputSsidController.text;
    final password = _inputPasswordController.text;
    final service = await findService();

    // wifiのssidを送信(書き込む)ためのcharacteristicを取得する
    final wifiSsidCharacteristic =
        service?.characteristics.firstWhereOrNull((element) {
      return element.uuid.toString() ==
          BluetoothConstants.wifiSsidCharacteristicUuid;
    });

    // wifiのpasswordを送信(書き込む)ためのcharacteristicを取得する
    final wifiPasswordCharacteristic =
        service?.characteristics.firstWhereOrNull((element) {
      return element.uuid.toString() ==
          BluetoothConstants.wifiPasswordCharacteristicUuid;
    });

    // wifiとpasswordのcharacteristicが取得できていれば、書き込みを行う
    if (wifiSsidCharacteristic != null && wifiPasswordCharacteristic != null) {
      await writeToCharacteristic(wifiSsidCharacteristic, ssid);
      await writeToCharacteristic(wifiPasswordCharacteristic, password);
    }
  }

  /// 選択した色をESP32に送信する
  void sendSelectedColor() async {
    final service = await findService();
    final color = _selectedColor;
    final colorCharacteristic =
        service?.characteristics.firstWhereOrNull((element) {
      return element.uuid.toString() ==
          BluetoothConstants.colorCharacteristicUuid;
    });
    if (colorCharacteristic == null || color == null) {
      return;
    }
    await writeToCharacteristic(colorCharacteristic, color);
  }

  Stream<String> getEsp32WiFiStatus() async* {
    final service = await findService();
    final wifiStatusCharacteristic =
        service?.characteristics.firstWhereOrNull((element) {
      return element.uuid.toString() ==
          BluetoothConstants.wifiConnectionStatusCharacteristicUuid;
    });
    if (wifiStatusCharacteristic == null) {
      log("wifiStatusCharacteristic is null");
      return;
    }
    await for (final value in wifiStatusCharacteristic.value) {
      final connectionStatus = String.fromCharCodes(value);
      log("wifi connection status: $connectionStatus");
      yield connectionStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ConnectionStatus(device: widget.device),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Wi-Fi設定",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _inputSsidController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'SSID',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _inputPasswordController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'パスワード',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StreamBuilder(
                          stream: getEsp32WiFiStatus(),
                          initialData: "未接続",
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data.toString(),
                            );
                          },
                        ),
                        ElevatedButton(
                          onPressed: sendWifiInformation,
                          child: const Text("接続"),
                        )
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "色設定",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<String>(
                      value: _selectedColor,
                      items: const [
                        DropdownMenuItem(
                          value: "red",
                          child: Text("赤"),
                        ),
                        DropdownMenuItem(
                          value: "green",
                          child: Text("緑"),
                        ),
                        DropdownMenuItem(
                          value: "blue",
                          child: Text("青"),
                        )
                      ],
                      onChanged: (String? color) {
                        setState(() {
                          _selectedColor = color;
                        });

                        // 選択した色をESP32に送信する
                        sendSelectedColor();
                      },
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ConnectionStatus extends StatelessWidget {
  final BluetoothDevice device;

  const ConnectionStatus({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text("接続状態"),
      subtitle: StreamBuilder(
        stream: device.state,
        initialData: BluetoothDeviceState.disconnected,
        builder: (c, snapshot) {
          switch (snapshot.data) {
            case BluetoothDeviceState.connected:
              return const Text('Connected');
            case BluetoothDeviceState.connecting:
              return const Text('Connecting');
            case BluetoothDeviceState.disconnected:
              return const Text('Disconnected');
            default:
              return const Text('Unknown');
          }
        },
      ),
    );
  }
}
