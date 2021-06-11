import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MaterialApp(home: QRViewExample()));

class QRViewExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  String result;
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  var LastTimeScanned;

  var codesScanned = [];

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.pauseCamera();
    }
    controller.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (result != null)
                  Text(
                    '${result}',
                    style: TextStyle(fontSize: 32),
                  )
                else
                  Text(
                    'Scan a code',
                    style: TextStyle(fontSize: 32),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // We check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sized after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = "Scanned: " + scanData.code;
      });

      if (codesScanned.contains(scanData.code) == false) {
        codesScanned.add(scanData.code);

        final body = {"id": scanData.code};
        final jsonString = json.encode(body);
        final uri =
            Uri.http('lazy-box-server.herokuapp.com', '/updateBoxStatus');
        final headers = {HttpHeaders.contentTypeHeader: 'application/json'};
        final response =
            await http.post(uri, headers: headers, body: jsonString);
        print(response.statusCode);
        print(json.decode(response.body));
        setState(() {
          result = "Scanned";
        });
        if (DateTime.now().millisecondsSinceEpoch != null) {
        LastTimeScanned = DateTime.now().millisecondsSinceEpoch;
        }
      } else {
        if (DateTime.now().millisecondsSinceEpoch - LastTimeScanned > 1000) {
        setState(() {
          result = "Already scanned";
        });
        }
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
