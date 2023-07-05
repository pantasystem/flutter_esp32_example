

class BluetoothConstants {
  const BluetoothConstants._();

  /// このプロジェクトのBLEのサービスのUUID
  static const String serviceUuid = "d6f19b1b-3b62-4d39-ad7d-ec2dddbeb0ee";

  /// FlutterからESP32に色を送信するためのキャラクタリスティックのUUID
  static const String colorCharacteristicUuid = "30dfe503-7a09-4c5f-9a9f-352d773666d3";

  /// ESP32からFlutterに送信するセンサー値のキャラクタリスティックのUUID
  static const String sensorValueCharacteristicUuid = "78b5f08c-a793-4127-9a94-85a246056038";

  /// FlutterからESP32にWiFiのSSIDを送信するためのキャラクタリスティックのUUID
  static const String wifiSsidCharacteristicUuid = "54acff26-12f7-4502-a9b4-3f82a268df08";

  /// FlutterからESP32にWiFiのパスワードを送信するためのキャラクタリスティックのUUID
  static const String wifiPasswordCharacteristicUuid = "bb11fb53-9d60-4f30-af5a-70485a572671";

  static const String wifiConnectionStatusCharacteristicUuid = "747eb891-fc27-4627-bb29-0fdca8376957";
}