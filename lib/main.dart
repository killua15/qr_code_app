import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:otp/otp.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_two_factor/resource.dart';
import 'package:qr_two_factor/resources_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ResourceAdapter());
  await Hive.openBox<Resource>('resources');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          elevation: 0,
          actions: [
            InkWell(
              onTap: () {
                final box = SigletonResource.getResource();
                box.clear();
                setState(() {});
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.cleaning_services_rounded,
                  color: Colors.black,
                ),
              ),
            )
          ],
          title: const Center(
              child: Text(
            'WalletID OTP Generate',
            style: TextStyle(color: Colors.black),
          )),
          backgroundColor: Colors.white,
        ),
        body: QRViewExample(),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({
    super.key,
  });

  @override
  State<QRViewExample> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  String textOtp = "";

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    // if (Platform.isAndroid) {
    //   controller!.pauseCamera();
    // }
    // controller!.resumeCamera();
    openBox();
  }

  openBox() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showQRVIew(context, () {
            setState(() {});
          });
        },
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: createListResources(),
        ),
      ),
    );
  }

  List<Widget> createListResources() {
    List<Widget> widgets = [];
    final box = SigletonResource.getResource();

    for (var items in box.values.toList()) {
      widgets.add(CodeComponent(
        resource: items.resource,
        secret: items.secret,
      ));
    }

    return widgets;
  }

  Future<dynamic> showQRVIew(BuildContext context, Function updateListWidgets) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10))),
            height: MediaQuery.of(context).size.height * 0.85,
            child: Expanded(
                flex: 2, child: _buildQrView(context, updateListWidgets)));
      },
    ).then((value) {
      updateListWidgets();
    });
  }

  Widget _buildQrView(BuildContext context, Function updateListWidgets) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: (val) {
        _onQRViewCreated(val, updateListWidgets);
      },
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(
      QRViewController controller, Function updateListWidgets) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      print('qrTest ${scanData.format}');
      print('qrTest ${scanData.code}');
      setState(() {
        result = scanData;
      });
      controller.stopCamera();
      final now = DateTime.now();
      final secret = result?.code?.split("secret=")[1].split("&issuer")[0];
      final resource =
          result?.code?.split("secret=")[0].split("otpauth://totp/")[1];
      final box = SigletonResource.getResource();

      var res = Resource()
        ..secret = secret ?? ""
        ..resource = resource ?? "";
      box.add(res);
      print(box.length);

      Navigator.pop(context, updateListWidgets);
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p' as num);
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

class CodeComponent extends StatefulWidget {
  final String secret;
  final String resource;

  const CodeComponent({
    super.key,
    required this.secret,
    required this.resource,
  });

  @override
  State<CodeComponent> createState() => _CodeComponentState();
}

class _CodeComponentState extends State<CodeComponent> {
  final int TIMERINTERVAL = 30;
  double percent = 0;
  int count = 0;
  Timer? timer;
  String otpGenerate = "";
  @override
  void initState() {
    // TODO: implement initState
    startTimer();
    super.initState();
  }

  startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (count == 0) {
        final code = OTP.generateTOTPCodeString(
            widget.secret, DateTime.now().millisecondsSinceEpoch,
            length: 6, interval: 30, algorithm: Algorithm.SHA1, isGoogle: true);
        setState(() {
          otpGenerate = code;
        });
      }
      setState(() {
        count = count + 1;
        percent = percent + 0.033;
      });
      if (count == TIMERINTERVAL) {
        setState(() {
          count = 0;
          percent = 0.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, top: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.resource),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                otpGenerate,
                style: const TextStyle(color: Colors.blue, fontSize: 30),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularPercentIndicator(
                    radius: 15.0,
                    lineWidth: 5.0,
                    percent: percent,
                    progressColor: Colors.green,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
