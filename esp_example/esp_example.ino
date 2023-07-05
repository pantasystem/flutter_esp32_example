#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLE2902.h>
#include <WiFi.h>


#define DEVICE_NAME "BLE-ESP32" 

#define SERVICE_UUID "d6f19b1b-3b62-4d39-ad7d-ec2dddbeb0ee"  // サービスのUUID

// スマホから色情報を送信するためのキャラスタリスティックを識別するためのUUID
#define COLOR_INFO_CHARACTERISTIC_UUID "30dfe503-7a09-4c5f-9a9f-352d773666d3" 

// スマホからSSIDを送信するためのキャラスタリスティックを識別するためのUUID
#define WIFI_SSID_CHARACTERISTIC_UUID "54acff26-12f7-4502-a9b4-3f82a268df08"

// スマホからWiFiのパスワードを送信するためのキャラスタリスティックを識別するためのUUID
#define WIFI_PASSWORD_CHARACTERISTIC_UUID "bb11fb53-9d60-4f30-af5a-70485a572671"

// ESP32からスマホにセンサーの値を送信するためのキャラスタリスティックを識別するためのUUID
#define SENSOR_INFO_CHARACTERISTIC_UUID "b8beec32-0da5-4144-93a1-f69a5674d014"

// ESP32のWiFiの接続状態をスマホに送信するためのキャラスタリスティックを識別するためのUUID
#define WIFI_CONNECTION_STATUS_CHARACTERISTIC_UUID "747eb891-fc27-4627-bb29-0fdca8376957"

// Bluetoothのパケットサイズ
#define MTU_SIZE 200

BLECharacteristic* colorInfoCharacteristic;
BLECharacteristic* wifiSsidCharacteristic;
BLECharacteristic* wifiPasswordCharacteristic;
BLECharacteristic* sensorInfoCharacteristic;
BLECharacteristic* wifiConnectionStatusCharacteristic;

bool deviceConnected = false; 

bool connectingWifi = false;

char wifiSsid[128]; 
char wifiPassword[128]; 

void setup() {
  Serial.begin(115200);
  Serial.println("Start programm ...");
  // put your setup code here, to run once:
  startBluetooth();
  while(!checkWifiInfoAvailable()) {
    delay(100);
  }
  connectWifi(wifiSsid, wifiPassword);
}

/**
 * ssidとpasswordに値が入っていることをチェックする関数
 */
bool checkWifiInfoAvailable() {
  return strlen(wifiSsid) != 0 && strlen(wifiPassword) != 0;
}

void connectWifi(const char* ssid, const char* password) {
  if (connectingWifi) {
    return;
  }
  connectingWifi = true;
  sendWifiConnectionStatus("Connectiong...");
    
  WiFi.begin(ssid, password);
  Serial.print("Connecting to ");

  int delayCounter = 0;
    
  while (WiFi.status() != WL_CONNECTED && delayCounter < 100) {
    delay(500);
    delayCounter++;
    Serial.print(".");
  }
  if (delayCounter < 100) {
    Serial.println("接続成功");  
    sendWifiConnectionStatus("Connection success");
  } else {
    Serial.println("接続失敗");
    sendWifiConnectionStatus("Connection failed");
  }
    
  connectingWifi = false;
}

void sendWifiConnectionStatus(const char* statusMessage) {
  wifiConnectionStatusCharacteristic->setValue(statusMessage);
  wifiConnectionStatusCharacteristic->notify();
}

void loop() {
  // put your main code here, to run repeatedly:
  
}

// Bluetoothの接続状態の結果がこのクラスのメソッドが呼び出されることによって返ってくる(Observerパターン)
class ConnectionCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      pServer->updatePeerMTU(pServer->getConnId(), 200);
      Serial.println("接続された");
  }
  void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("接続解除された");
  }
};
void startBluetooth() {
  BLEDevice::init(DEVICE_NAME);
  BLEServer *pServer = BLEDevice::createServer();
  
  pServer->setCallbacks(new ConnectionCallbacks());
  BLEService *pService = pServer->createService(SERVICE_UUID);
  doPrepare(pService);
  pService->start();
  BLEAdvertising *pAdvertising = pServer->getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->start();
}


class ColorInfoBleCallback: public BLECharacteristicCallbacks {
  void onRead(BLECharacteristic *pC) {
  }

  // スマホから色情報が書き込まれた場合ここが呼び出される
  void onWrite(BLECharacteristic *pC) {
    std::string value = pC->getValue();
    Serial.print("色が送信されました:");
    Serial.println(value.c_str());
  }
};

class WifiSsidBleCallback: public BLECharacteristicCallbacks {
  void onRead(BLECharacteristic *pC) {
  }

  // スマホからWifiのssidが書き込まれた場合このメソッドが呼び出される
  void onWrite(BLECharacteristic *pC) {
    std::string value = pC->getValue();
    Serial.print("WiFI SSIDが送信されました:");
    Serial.println(value.c_str());
    strncpy(wifiSsid, value.c_str(), sizeof(wifiSsid) - 1);
  }
};

class WifiPasswordBleCallback: public BLECharacteristicCallbacks {
  void onRead(BLECharacteristic *pC) {
  }

  // スマホからWifiのパスワードが書き込まれた場合このメソッドが呼び出される
  void onWrite(BLECharacteristic *pC) {
    std::string value = pC->getValue();
    Serial.print("WiFi パスワードが送信されました:");
    Serial.println(value.c_str());
    strncpy(wifiPassword, value.c_str(), sizeof(wifiPassword) - 1);
  }
};

void doPrepare(BLEService *pService) {
  // 色情報をスマホから書き込むためのキャラクタリスティックを作成する
  colorInfoCharacteristic = pService->createCharacteristic(
                                          COLOR_INFO_CHARACTERISTIC_UUID, 
                                          BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE
                                          );

  // SSIDをスマホから書き込むためのキャラクタリスティックを作成する
  wifiSsidCharacteristic = pService->createCharacteristic(
                                          WIFI_SSID_CHARACTERISTIC_UUID, 
                                          BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE
                                          );

  // WiFIのパスワードを書き込むためのキャラクタリスティックを作成する
  wifiPasswordCharacteristic = pService->createCharacteristic(
                                          WIFI_PASSWORD_CHARACTERISTIC_UUID, 
                                          BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE
                                          );

  // センサーの情報を送信するためのキャラクタリスティックを作成する
  sensorInfoCharacteristic = pService->createCharacteristic(
                                          WIFI_PASSWORD_CHARACTERISTIC_UUID, 
                                          BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
                                          );

  wifiConnectionStatusCharacteristic = pService->createCharacteristic(
                                          WIFI_CONNECTION_STATUS_CHARACTERISTIC_UUID,
                                                                BLECharacteristic::PROPERTY_READ   |
                                                                BLECharacteristic::PROPERTY_WRITE  |
                                                                BLECharacteristic::PROPERTY_NOTIFY |
                                                                BLECharacteristic::PROPERTY_INDICATE
                                          );
  colorInfoCharacteristic->setCallbacks(new ColorInfoBleCallback());
  wifiSsidCharacteristic->setCallbacks(new WifiSsidBleCallback());
  wifiPasswordCharacteristic->setCallbacks(new WifiPasswordBleCallback());

}
