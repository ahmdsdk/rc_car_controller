import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

class RCControllerScreen extends StatefulWidget {
  final BluetoothDevice? selectedDevice;
  const RCControllerScreen({
    super.key,
    required this.selectedDevice,
  });

  @override
  State<RCControllerScreen> createState() => _RCControllerScreenState();
}

class _RCControllerScreenState extends State<RCControllerScreen> {
  BluetoothConnection? _connection;
  BluetoothDevice? _selectedDevice;

  ScrollController listScrollController = ScrollController();

  bool isConnecting = true;
  bool get isConnected => (_connection?.isConnected ?? false);

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    _connect();
  }

  void _connect() {
    _selectedDevice = widget.selectedDevice!;
    BluetoothConnection.toAddress(_selectedDevice!.address).then((connection) {
      setState(() {
        _connection = connection;
        isConnecting = false;
        isDisconnecting = false;
      });

      connection.input!.listen(_onDataReceived).onDone(() {
        // if (isDisconnecting) {
        //   print('Disconnecting locally!');
        // } else {
        //   print('Disconnected remotely!');
        // }
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    }).catchError((error) {
      // print('Cannot connect, exception occured');
      // print(error);
    });
  }

  void _onDataReceived(Uint8List data) {
    // print(data);
    // Allocate buffer for parsed data
    // int backspacesCounter = 0;
    // for (var byte in data) {
    //   if (byte == 8 || byte == 127) {
    //     backspacesCounter++;
    //   }
    // }
    // Uint8List buffer = Uint8List(data.length - backspacesCounter);
    // int bufferIndex = buffer.length;

    // // Apply backspace control character
    // backspacesCounter = 0;
    // for (int i = data.length - 1; i >= 0; i--) {
    //   if (data[i] == 8 || data[i] == 127) {
    //     backspacesCounter++;
    //   } else {
    //     if (backspacesCounter > 0) {
    //       backspacesCounter--;
    //     } else {
    //       buffer[--bufferIndex] = data[i];
    //     }
    //   }
    // }

    // // Create message if there is new line character
    // String dataString = String.fromCharCodes(buffer);
    // int index = buffer.indexOf(13);
    // if (~index != 0) {
    //   setState(() {
    //     messages.add(
    //       Message(
    //         1,
    //         backspacesCounter > 0
    //             ? _messageBuffer.substring(
    //                 0, _messageBuffer.length - backspacesCounter)
    //             : _messageBuffer + dataString.substring(0, index),
    //       ),
    //     );
    //     _messageBuffer = dataString.substring(index);
    //   });
    // } else {
    //   _messageBuffer = (backspacesCounter > 0
    //       ? _messageBuffer.substring(
    //           0, _messageBuffer.length - backspacesCounter)
    //       : _messageBuffer + dataString);
    // }
  }

  void _sendMessage(String text) async {
    text = text.trim();

    if (text.isNotEmpty) {
      try {
        _connection?.output.add(Uint8List.fromList(utf8.encode(text)));
        await _connection?.output.allSent;
      } catch (e) {
        // Ignore error, but notify state
        // print(e);
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      _connection?.dispose();
      _connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        foregroundColor: Colors.white,
        title: Text('RC Controller for ${widget.selectedDevice!.name}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            Joystick(
              stick: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.amber,
                      Colors.amber.shade900,
                      const Color(0xFF964100),
                    ],
                    tileMode: TileMode.mirror,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),
              mode: JoystickMode.all,
              listener: (details) {
                num x = details.x;
                num y = details.y;
                num angle = x == 0 ? 0 : atan(y / x) * 180 / pi;

                if (x > 0) {
                  if (angle > -30 && angle < 30) {
                    _sendMessage('R');
                  } else if (angle < -30 && angle > -60) {
                    _sendMessage('E');
                  } else if (angle < -60 && angle > -90) {
                    _sendMessage('F');
                  } else if (angle > 30 && angle < 60) {
                    _sendMessage('C');
                  } else if (angle > 60 && angle < 90) {
                    _sendMessage('B');
                  } else {
                    _sendMessage('S');
                  }
                } else if (x < 0) {
                  if (angle > -30 && angle < 30) {
                    _sendMessage('L');
                  } else if (angle < -30 && angle > -60) {
                    _sendMessage('Z');
                  } else if (angle < -60 && angle > -90) {
                    _sendMessage('B');
                  } else if (angle > 30 && angle < 60) {
                    _sendMessage('Q');
                  } else if (angle > 60 && angle < 90) {
                    _sendMessage('F');
                  } else {
                    _sendMessage('S');
                  }
                } else {
                  _sendMessage('S');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
