import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:rc_car_controller/src/discovery_page.dart';
import 'package:rc_car_controller/src/screens/rc_controller_screen.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'RC Car Controller'),
    );
  }
}

class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  // BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  BluetoothDevice? _selectedDevice;

  String _address = "...";
  String _name = "...";

  Timer? _discoverableTimeoutTimer;

  final ValueNotifier _restartDiscovery = ValueNotifier(false);

  bool _autoAcceptPairingRequests = false;

  @override
  void initState() {
    super.initState();

    // Get current state
    _bluetooth.state.then((state) {
      setState(() {
        // _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await _bluetooth.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }).then((_) {
      // Update the address field
      _bluetooth.address.then((address) {
        setState(() {
          _address = address!;
        });
      });
    });

    _bluetooth.name.then((name) {
      setState(() {
        _name = name!;
      });
    });

    // Listen for futher state changes
    _bluetooth.onStateChanged().listen((BluetoothState state) {
      setState(() {
        // _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
      });
    });
  }

  @override
  void dispose() {
    _bluetooth.setPairingRequestHandler(null);
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // print('Selected device -> ${_selectedDevice?.name}');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView(
          children: [
            ListTile(
              title: Text('Device Name: $_name'),
            ),
            ListTile(
              title: Text('Device Address: $_address'),
            ),
            const ListTile(title: Text('Devices discovery and connection')),
            SwitchListTile(
              title: const Text('Auto-try specific pin when pairing'),
              subtitle: const Text('Pin 1234'),
              value: _autoAcceptPairingRequests,
              onChanged: (bool value) {
                setState(() {
                  _autoAcceptPairingRequests = value;
                });
                if (value) {
                  _bluetooth.setPairingRequestHandler(
                      (BluetoothPairingRequest request) {
                    // print("Trying to auto-pair with Pin 1234");
                    if (request.pairingVariant == PairingVariant.Pin) {
                      return Future.value("1234");
                    }
                    return Future.value(null);
                  });
                } else {
                  _bluetooth.setPairingRequestHandler(null);
                }
              },
            ),
            DiscoveryPage(
              restartDiscovery: _restartDiscovery,
              onDeviceSelected: (device) async {
                setState(() => _selectedDevice = device);
                _restartDiscovery.value = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return RCControllerScreen(
                        selectedDevice: _selectedDevice,
                      );
                    },
                  ),
                );
              },
              selectedDevice: _selectedDevice,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _restartDiscovery.value = true;
          });
        },
        tooltip: 'Scan',
        backgroundColor: Colors.amber.shade900,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        child: const Icon(Icons.bluetooth_searching),
      ),
    );
  }
}
