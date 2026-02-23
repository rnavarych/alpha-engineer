# Platform Channels

## MethodChannel — Request/Response

```dart
// Dart side — call native method
import 'package:flutter/services.dart';

class BatteryService {
  static const _channel = MethodChannel('com.myapp/battery');

  /// Get current battery level (0-100)
  static Future<int> getBatteryLevel() async {
    try {
      final level = await _channel.invokeMethod<int>('getBatteryLevel');
      return level ?? -1;
    } on PlatformException catch (e) {
      throw BatteryException('Failed to get battery level: ${e.message}');
    }
  }

  /// Check if device is charging
  static Future<bool> isCharging() async {
    final result = await _channel.invokeMethod<bool>('isCharging');
    return result ?? false;
  }
}
```

```kotlin
// Android side (Kotlin)
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.myapp/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBatteryLevel" -> {
                        val batteryLevel = getBatteryLevel()
                        if (batteryLevel != -1) {
                            result.success(batteryLevel)
                        } else {
                            result.error("UNAVAILABLE", "Battery level not available", null)
                        }
                    }
                    "isCharging" -> result.success(isCharging())
                    else -> result.notImplemented()
                }
            }
    }

    private fun getBatteryLevel(): Int {
        val batteryManager = getSystemService(BATTERY_SERVICE) as BatteryManager
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }
}
```

```swift
// iOS side (Swift)
@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "com.myapp/battery",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "getBatteryLevel":
                let level = self.getBatteryLevel()
                result(level)
            case "isCharging":
                result(UIDevice.current.batteryState == .charging)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func getBatteryLevel() -> Int {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return Int(UIDevice.current.batteryLevel * 100)
    }
}
```

## EventChannel — Continuous Streams

```dart
// Dart side — listen to native events
class SensorService {
  static const _channel = EventChannel('com.myapp/accelerometer');

  /// Stream of accelerometer readings
  static Stream<AccelerometerData> get accelerometerStream {
    return _channel.receiveBroadcastStream().map((event) {
      final data = event as Map;
      return AccelerometerData(
        x: data['x'] as double,
        y: data['y'] as double,
        z: data['z'] as double,
      );
    });
  }
}

// Usage in widget
StreamBuilder<AccelerometerData>(
  stream: SensorService.accelerometerStream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const Text('Waiting...');
    final data = snapshot.data!;
    return Text('X: ${data.x.toStringAsFixed(2)}');
  },
)
```

```kotlin
// Android EventChannel handler
EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.myapp/accelerometer")
    .setStreamHandler(object : EventChannel.StreamHandler {
        private var sensorManager: SensorManager? = null
        private var listener: SensorEventListener? = null

        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
            listener = object : SensorEventListener {
                override fun onSensorChanged(event: SensorEvent) {
                    events?.success(mapOf(
                        "x" to event.values[0],
                        "y" to event.values[1],
                        "z" to event.values[2]
                    ))
                }
                override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
            }
            sensorManager?.registerListener(listener,
                sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER),
                SensorManager.SENSOR_DELAY_NORMAL
            )
        }

        override fun onCancel(arguments: Any?) {
            sensorManager?.unregisterListener(listener)
        }
    })
```

## FFI — Direct C/C++ Calls

```dart
// For performance-critical code — no serialization overhead
import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Load native library
final DynamicLibrary nativeLib = Platform.isAndroid
    ? DynamicLibrary.open('libnative_crypto.so')
    : DynamicLibrary.process();

// Bind C function
typedef NativeHashFunc = Pointer<Utf8> Function(Pointer<Utf8>, Int32);
typedef DartHashFunc = Pointer<Utf8> Function(Pointer<Utf8>, int);

final hashData = nativeLib
    .lookupFunction<NativeHashFunc, DartHashFunc>('hash_data');

String computeHash(String input) {
  final inputPtr = input.toNativeUtf8();
  try {
    final resultPtr = hashData(inputPtr, input.length);
    return resultPtr.toDartString();
  } finally {
    malloc.free(inputPtr);
  }
}
```

## Anti-Patterns
- Using MethodChannel for high-frequency data — use EventChannel or FFI
- Not handling `PlatformException` — crashes on unsupported platforms
- Missing `result.notImplemented()` for unknown methods — silent failures
- Forgetting to unregister listeners in `onCancel` — memory leaks

## Quick Reference
```
MethodChannel: request/response — battery level, permissions, one-shot native calls
EventChannel: continuous stream — sensors, location, Bluetooth data
FFI: direct C/C++ — crypto, image processing, computation-heavy work
Channel naming: 'com.myapp/feature' — reverse domain convention
Error handling: PlatformException on Dart side, result.error on native
Cleanup: onCancel for EventChannel, dispose for MethodChannel
Platform check: Platform.isAndroid / Platform.isIOS for conditional code
```
