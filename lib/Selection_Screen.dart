import 'package:flutter/material.dart';
import 'package:qr_code/QRScanner.dart';
import 'package:qr_code/QRShare_Screen.dart';

class Selection_Page extends StatefulWidget {
  @override
  _Selection_PageState createState() => _Selection_PageState();
}

class _Selection_PageState extends State<Selection_Page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RaisedButton(
                color: Colors.blue[700],
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => QRShare()));
                },
                child: Text(
                  "Share QR Code",
                  style: TextStyle(color: Colors.white),
                )),
            RaisedButton(
                color: Colors.blue[700],
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => QRCodeScanner()));
                },
                child: Text(
                  "Scan QR Code",
                  style: TextStyle(color: Colors.white),
                ))
          ],
        ),
      ),
    );
  }
}
