# flutter_esp32_ble_example
flutterとesp32をBLEで通信するサンプルコードです。<br>
サンプルの内容としてはFlutterとESP32で、BLEで接続を行い、<br>
ESP32から定期的にデータを送信し、Flutter側で受信したデータを表示する実装と<br>
Flutter側のフォームに入力した状態を、ESP32側に送信し、ESP32側で受信したデータを表示(Serial.print)する実装があります。<br>

# プロジェクト構成
esp_exampleにesp32のコード例が格納されています。<br>
プロジェクトディレクトリ全体はflutterのプロジェクトになっています。

# 使用技術
- flutter
- Arduino(esp32)
- flutter_blue_plus

# Bluetooth構成
## セントラルとペリフェラル
BLEにはセントラルとペリフェラルというものがあります。<br>
セントラルとは、一般的にはスマートフォン側になることが多く、IoTデバイスなどと通信を行います。<br>
ペリフェラルとは、一般的にはIoT側になることが多く、スマートフォンなどのセントラルと通信を行います。<br>
また、セントラルはペリフェラルに対して、複数の接続を行うことができます。<br>

## Service
このプロジェクトでBLEの通信を行うためのサービスです。<br>
Bluetoothのデバイス一覧では、このサービスのUUIDを持つデバイスが表示されます。<br>
※このUUIDのサービスがないデバイスはこのFlutterアプリに対応していないと言えます<br>
UUID: d6f19b1b-3b62-4d39-ad7d-ec2dddbeb0ee

## Characteristic
Characteristicとは、サービスの中で、データの送受信を行うためのものです。<br>
このプロジェクトでは、ESP32のCharacteristicをFlutter側から読み取ったり、<br>
書き込んだりしながらデータのやり取りを行います。
一般的にはペリフェラル(EPS32)側が、Characteristicを作成し、<br>
セントラル(Flutter)側が、Characteristicを読み取ったり、書き込んだりします。<br>

### 3つのデータの送受信用Characteristic(補足)
BLEにはread, write, notifyの3つのデータのやり取りの方法があります。<br>
readは、Characteristicの値を読み取ることです。<br>
writeは、Characteristicに値を書き込むことです。<br>
notifyは特殊で、Characteristicの値が変更されたときに、<br>
接続しているデバイス（今回はFlutter）などにそのことを通知するための仕組みです。<br>
notifyがある理由としては、notifyを行わないと、定期的にreadを行う必要性が出てきてしまい、<br>
省電力性が損なわれてしまうためです。<br>

### 色の送信用Characteristic
UUID: 30dfe503-7a09-4c5f-9a9f-352d773666d3<br>

Flutter側からESP32に色の情報を送信するためのCharacteristicです。<br>

### ESP32からのWiFiの接続状態の受信用Characteristic
UUID: 747eb891-fc27-4627-bb29-0fdca8376957<br>

ESP32からWiFiの接続状態を受信するためのCharacteristicです。<br>
また、このCharacteristicはESP32からFlutterに値が変化したことを伝えないといけないので、<br>
notifyを有効にします。<br>

### WiFiのSSID送信用のCharacteristic
UUID: 54acff26-12f7-4502-a9b4-3f82a268df08

### WiFiのパスワード送信用のCharacteristic
UUID: bb11fb53-9d60-4f30-af5a-70485a572671

# ファイル構成
## lib/main.dart
Flutterのメインのファイルです。<br>

## lib/bluetooth_device_list.dart
Bluetoothのデバイス一覧を取得し、表示する実装があるファイルです。<br>

## lib/bluetooth_constants.dart
BluetoothのUUIDなどの定数を定義しているファイルです。<br>

## lib/bluetooth_device.dart
Bluetoothデバイスに接続後に表示される画面の実装があるファイルです。<br>
接続状態や、WiFiの接続用のUIなどが実装されています。<br>