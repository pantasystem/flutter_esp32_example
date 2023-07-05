
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_esp32_ble_example/bluetooth_constants.dart';
import 'package:flutter_esp32_ble_example/bluetooth_device.dart';


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
