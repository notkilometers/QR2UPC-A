import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() => runApp(const MaterialApp(home: HomePage(), debugShowCheckedModeBanner: false,));

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: Colors.grey[700],
      appBar: AppBar(
        backgroundColor: Colors.indigo[400],
          title: const Text('QR2UPC-A'),
          centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[400],
          ),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const QRScanner(),
            ));
          },
          child: const Text('Scan'),
        ),
      ),
    );
  }
}

class QRScanner extends StatefulWidget {
  const QRScanner({Key? key}) : super(key: key);

  @override State<StatefulWidget> createState() => QRScannerState();
}

class QRScannerState extends State<QRScanner> {
  Barcode? result;
  QRViewController? controller;
  bool flashStatus = false;
  bool isScanning = true;
  final GlobalKey qrKey = GlobalKey();

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: Column(
        children: [
          Expanded(flex: 4, child: _buildQrView(context)),
        ],
      ),
    );
  }

  _appBar() {
    return AppBar(
      title: const Text('QR2UPC-A'),
      backgroundColor: Colors.indigo.shade400,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          if (isScanning) {
            controller!.toggleFlash();
            flashStatus = !flashStatus;
            setState(() {});
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 80,
            //color: Get.isDarkMode ? Colors.deepOrange:Colors.grey,
            padding: const EdgeInsets.all(5),
            child: Icon(
                flashStatus ? Icons.light_mode : Icons.light_mode_outlined
            ),
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            isScanning ? controller!.pauseCamera() : controller!.resumeCamera();
            isScanning = !isScanning;
            setState(() {});
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              height: 80,
              //color: Get.isDarkMode ? Colors.deepOrange:Colors.grey,
              padding: const EdgeInsets.all(15),
              child: Icon(
                  isScanning ? Icons.pause : Icons.play_arrow
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;

    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;

        if (result != null) {
          controller.pauseCamera();
          isScanning = false;
          setState(() {});

          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.grey[700],
                content: SizedBox(
                  height: 300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Image.network("https://barcode.tec-it.com/barcode.ashx?data=${result!.code}&code=UPCA"),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo[400],
                          ),
                          onPressed: () => popAndReset(),
                          child: const Text("Close")
                      ),
                    ],
                  ),
                ),
              )
          );
        }
      });
    });
  }

  void popAndReset() {
    Navigator.pop(context);
    result = null;
    isScanning = true;
    controller!.resumeCamera();
    setState(() {});
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}