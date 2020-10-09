import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qr_reader/flutter_qr_reader.dart';

import 'package:image_picker/image_picker.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter_qr_reader/qrcode_reader_view.dart';

const flashOn = 'FLASH ON';
const flashOff = 'FLASH OFF';

class QRCodeScanner extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const QRCodeScanner({Key key, this.onChanged}) : super(key: key);
  @override
  _QRCodeScannerState createState() => _QRCodeScannerState();
}

class _QRCodeScannerState extends State<QRCodeScanner>
    with SingleTickerProviderStateMixin {
  QRViewController controller;
  var qrText = '';
  bool flashPress = false;

  void _publishSelection(selectedValue) {
    if (widget.onChanged != null) {
      widget.onChanged(selectedValue);
    }
  }

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  var flashState = flashOff;

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        qrText = scanData;
      });
    });
  }

  Future _scanImage() async {
    /*stopScan();*/
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      /*startScan();*/
      return;
    }
    final rest = await FlutterQrReader.imgScan(image);
    await onScan(rest);
    /*startScan();*/
  }

  /*QrReaderViewController _controller;*/
  AnimationController _animationController;
  bool isScan = false;
  Timer _timer;

  /*void _clearAnimation() {
    _timer?.cancel();
    if (_animationController != null) {
      _animationController?.dispose();
      _animationController = null;
    }
  }*/
  GlobalKey<QrcodeReaderViewState> _key = GlobalKey();

  Future onScan(String data) async {
    await showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text("QR Data"),
          content: data == " " || data == null
              ? Text("Scan Valid QR Code")
              : Text(data),
          actions: <Widget>[
            CupertinoDialogAction(
                child: Text("Ok"),
                onPressed: () {
                  Navigator.pop(context, data);
                  _publishSelection(data);
                })
          ],
        );
      },
    );
    _key.currentState;
  }

  /* void stopScan() {
    _clearAnimation();
  }*/

  /* Future _onQrBack(data, _) async {
    if (isScan == true) return;
    isScan = true;
    stopScan();
  }*/

  void _upState() {
    setState(() {});
  }

  void _initAnimation() {
    setState(() {
      _animationController = AnimationController(
          vsync: this, duration: Duration(milliseconds: 1000));
    });
    _animationController
      ..addListener(_upState)
      ..addStatusListener((state) {
        if (state == AnimationStatus.completed) {
          _timer = Timer(Duration(seconds: 1), () {
            _animationController?.reverse(from: 1.0);
          });
        } else if (state == AnimationStatus.dismissed) {
          _timer = Timer(Duration(seconds: 1), () {
            _animationController?.forward(from: 0.0);
          });
        }
      });
    _animationController.forward(from: 0.0);
  }

  /*void startScan() {
    isScan = false;
    _controller.startCamera(_onQrBack);
    _initAnimation();
  }*/

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Color(0xFF31C3C3),
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 220,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            left: MediaQuery.of(context).size.width * 0.05,
            child: InkWell(
              onTap: () {
                Navigator.pop(context, true);
              },
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.3),
                child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Icon(
                      Icons.cancel,
                      color: Colors.white,
                    )),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.17,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.center,
              child: Center(
                child: Text(
                  'Place the QR Code inside the area',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.22,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.center,
              child: Center(
                child: Text(
                  'Scanning will start automatically',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.75,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.center,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 60),
                  child: InkWell(
                    onTap: () {
                      if (controller != null) {
                        controller.toggleFlash();
                        if (_isFlashOn(flashState)) {
                          setState(() {
                            flashState = flashOff;
                            flashPress = false;
                          });
                        } else {
                          setState(() {
                            flashState = flashOn;
                            flashPress = true;
                          });
                        }
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: !flashPress
                          ? Colors.black.withOpacity(0.3)
                          : Color(0xFF31C3C3),
                      child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Icon(
                            Icons.flash_on,
                            color: Colors.white,
                            size: 30,
                          )),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.75,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.center,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 60.0),
                  child: InkWell(
                    onTap: () {
                      _scanImage();
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.3),
                      child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Icon(
                            Icons.image,
                            color: Colors.white,
                            size: 30,
                          )),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.9,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '$qrText',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          qrText == ""
              ? Container()
              : CupertinoAlertDialog(
                  title: Text("QR Data"),
                  content: Text(qrText),
                  actions: <Widget>[
                    CupertinoDialogAction(
                        child: Text("Ok"),
                        onPressed: () {
                          Navigator.pop(context);
                          _publishSelection(qrText);
                        })
                  ],
                ),
        ],
      ),
    );
  }

  bool _isFlashOn(String current) {
    return flashOn == current;
  }
}
