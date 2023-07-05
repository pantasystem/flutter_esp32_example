import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_esp32_ble_example/bluetooth_constants.dart';

// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';


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
    final wifiStatusCharacteristic = service?.characteristics.firstWhereOrNull((element) {
      return element.uuid.toString() ==
          BluetoothConstants.wifiConnectionStatusCharacteristicUuid;
    });
    if (wifiStatusCharacteristic == null) {
      log("wifiStatusCharacteristic is null");
      return;
    }

    await for (final value in wifiStatusCharacteristic.onValueChangedStream) {
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
