import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'package:qr/qr.dart';
import 'dart:async';
import 'dart:ui';

class QRShare extends StatefulWidget {
  @override
  _QRShareState createState() => _QRShareState();
}

class _QRShareState extends State<QRShare> {
  GlobalKey globalKey = new GlobalKey();

  File _imageFile;

  @override
  void initState() {
    super.initState();

    _requestPermission();
  }

  _requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();

    final info = statuses[Permission.storage].toString();
    print(info);
    _toastInfo(info);
  }

  _toastInfo(String info) {
    print(info);
  }

  List<String> imagePaths = [];

  _onShare(BuildContext context) async {
    print('-----------press---------');

    final RenderBox box = context.findRenderObject();

    if (imagePaths.isNotEmpty) {
      await FlutterShare.shareFile(
        title: 'Example share',
        text: 'Example share text',
        filePath: imagePaths[0],
      );
    }
  }

  GlobalKey _globalKey = new GlobalKey();
  Future<Uint8List> _capturePng() async {
    try {
      print('inside');
      RenderRepaintBoundary boundary =
          _globalKey.currentContext.findRenderObject();
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData.buffer.asUint8List();
      var bs64 = base64Encode(pngBytes);
      print(pngBytes);
      imageFromBase64String(bs64);
      _createFileFromString(bs64);
      imagePaths.add(await _createFileFromString(bs64));
      setState(() {});
      return pngBytes;
    } catch (e) {
      print(e);
    }
  }

  Future<String> _createFileFromString(String bas64) async {
    final encodedStr = bas64;
    Uint8List bytes = base64.decode(encodedStr);
    String dir = (await getExternalStorageDirectory()).path;
    File file = File(
        "$dir/" + DateTime.now().millisecondsSinceEpoch.toString() + ".png");
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Image imageFromBase64String(String base64String) {
    return Image.memory(base64Decode(base64String));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Qr Code"),
          leading: GestureDetector(
              child: Icon(Icons.scanner, size: 20), onTap: () {}),
          actions: [
            IconButton(
                icon: Icon(
                  Icons.share,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await _capturePng();
                  await _onShare(context);
                })
          ],
        ),
        body: Container(
          alignment: Alignment.center,
          color: Colors.white,
          child: RepaintBoundary(
              key: _globalKey,
              child: Container(
                height: 300,
                width: 300,
                color: Colors.white,
                child: Center(
                  child: PrettyQr(
                      image: AssetImage('assets/image/img.png'),
                      typeNumber: 5,
                      size: 250,
                      data: 'www.youtube.com',
                      errorCorrectLevel: QrErrorCorrectLevel.Q,
                      roundEdges: false),
                ),
              )),
        ));
  }
}

class PrettyQr extends StatefulWidget {
  final double size;
  final String data;
  final Color elementColor;
  final int errorCorrectLevel;
  final bool roundEdges;
  final int typeNumber;

  final ImageProvider image;

  PrettyQr(
      {Key key,
      this.size = 100,
      @required this.data,
      this.elementColor = Colors.black,
      this.errorCorrectLevel = QrErrorCorrectLevel.M,
      this.roundEdges = true,
      this.typeNumber = 1,
      this.image})
      : super(key: key);

  @override
  _PrettyQrState createState() => _PrettyQrState();
}

class _PrettyQrState extends State<PrettyQr> {
  Future<ui.Image> _loadImage(BuildContext buildContext) async {
    final completer = Completer<ui.Image>();

    final stream = widget.image.resolve(ImageConfiguration(
      devicePixelRatio: MediaQuery.of(buildContext).devicePixelRatio,
    ));

    stream.addListener(ImageStreamListener((imageInfo, error) {
      completer.complete(imageInfo.image);
    }, onError: (dynamic error, _) {
      completer.completeError(error);
    }));
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return widget.image == null
        ? CustomPaint(
            size: Size(widget.size, widget.size),
            isComplex: true,
            painter: PrettyQrCodePainter(
                data: widget.data,
                errorCorrectLevel: widget.errorCorrectLevel,
                elementColor: widget.elementColor,
                roundEdges: widget.roundEdges,
                typeNumber: widget.typeNumber),
          )
        : FutureBuilder(
            future: _loadImage(context),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                return Container(
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: PrettyQrCodePainter(
                        image: snapshot.data,
                        data: widget.data,
                        errorCorrectLevel: widget.errorCorrectLevel,
                        elementColor: widget.elementColor,
                        roundEdges: widget.roundEdges,
                        typeNumber: widget.typeNumber),
                  ),
                );
              } else {
                return Container();
              }
            },
          );
  }
}

class PrettyQrCodePainter extends CustomPainter {
  final String data;
  final Color elementColor;
  final int errorCorrectLevel;
  final int typeNumber;
  final bool roundEdges;
  ui.Image image;
  QrCode _qrCode;
  int deletePixelCount = 0;

  PrettyQrCodePainter(
      {this.data,
      this.elementColor = Colors.black,
      this.errorCorrectLevel = QrErrorCorrectLevel.M,
      this.roundEdges = false,
      this.typeNumber = 1,
      this.image}) {
    _qrCode = QrCode(typeNumber, errorCorrectLevel);
    _qrCode.addData(data);
    _qrCode.make();
  }

  @override
  paint(Canvas canvas, Size size) {
    if (image != null) {
      if (this.typeNumber <= 2) {
        deletePixelCount = this.typeNumber + 7;
      } else if (this.typeNumber <= 4) {
        deletePixelCount = this.typeNumber + 8;
      } else {
        deletePixelCount = this.typeNumber + 9;
      }

      var imageSize = Size(image.width.toDouble(), image.height.toDouble());

      var src = Alignment.center.inscribe(imageSize,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()));

      var dst = Alignment.center.inscribe(
          Size(size.height / 5, size.height / 5),
          Rect.fromLTWH(size.width / 3, size.height / 3, size.height / 3,
              size.height / 3));

      canvas.drawImageNine(image, src, dst, Paint());
    }

    /*  roundEdges ?*/
    _paintRound(canvas, size);
    /*  : _paintDefault(canvas, size);*/
  }

  void _paintRound(Canvas canvas, Size size) {
    var _paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black
      ..isAntiAlias = true;

    var _paintBackground = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white
      ..isAntiAlias = true;

    List<List> matrix = List<List>(_qrCode.moduleCount + 2);
    for (var i = 0; i < _qrCode.moduleCount + 2; i++) {
      matrix[i] = List(_qrCode.moduleCount + 2);
    }

    for (int x = 0; x < _qrCode.moduleCount + 2; x++) {
      for (int y = 0; y < _qrCode.moduleCount + 2; y++) {
        matrix[x][y] = false;
      }
    }

    for (int x = 0; x < _qrCode.moduleCount; x++) {
      for (int y = 0; y < _qrCode.moduleCount; y++) {
        if (image != null &&
            x >= deletePixelCount &&
            y >= deletePixelCount &&
            x < _qrCode.moduleCount - deletePixelCount &&
            y < _qrCode.moduleCount - deletePixelCount) {
          matrix[y + 1][x + 1] = false;
          continue;
        }

        if (_qrCode.isDark(y, x)) {
          matrix[y + 1][x + 1] = true;
        } else {
          matrix[y + 1][x + 1] = false;
        }
      }
    }

    double pixelSize = size.width / _qrCode.moduleCount;

    for (int x = 0; x < _qrCode.moduleCount; x++) {
      for (int y = 0; y < _qrCode.moduleCount; y++) {
        if (matrix[y + 1][x + 1]) {
          final Rect squareRect =
              Rect.fromLTWH(x * pixelSize, y * pixelSize, pixelSize, pixelSize);

          _setShape(x + 1, y + 1, squareRect, _paint, matrix, canvas,
              _qrCode.moduleCount);
        } else {
          _setShapeInner(
              x + 1, y + 1, _paintBackground, matrix, canvas, pixelSize);
        }
      }
    }
  }

  void _drawCurve(Offset p1, Offset p2, Offset p3, Canvas canvas) {
    Path path = Path();

    path.moveTo(p1.dx, p1.dy);
    path.quadraticBezierTo(p2.dx, p2.dy, p3.dx, p3.dy);
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p1.dx, p1.dy);
    path.close();

    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.white);
  }

  //Скругляем внутренние углы (фоновым цветом)
  void _setShapeInner(
      int x, int y, Paint paint, List matrix, Canvas canvas, double pixelSize) {
    double widthY = pixelSize * (y + 1);
    double heightX = pixelSize * (x + 1);

    //bottom right check
    if (matrix[y + 1][x] && matrix[y][x + 1] && matrix[y + 1][x + 1]) {
      Offset p1 =
          Offset(heightX + pixelSize - (0.25 * pixelSize), widthY + pixelSize);
      Offset p2 = Offset(heightX + pixelSize, widthY + pixelSize);
      Offset p3 =
          Offset(heightX + pixelSize, widthY + pixelSize - (0.25 * pixelSize));

      _drawCurve(p1, p2, p3, canvas);
    }

    //top left check
    if (matrix[y - 1][x] && matrix[y][x - 1] && matrix[y - 1][x - 1]) {
      Offset p1 = Offset(heightX, widthY + (0.25 * pixelSize));
      Offset p2 = Offset(heightX, widthY);
      Offset p3 = Offset(heightX + (0.25 * pixelSize), widthY);

      _drawCurve(p1, p2, p3, canvas);
    }

    //bottom left check
    if (matrix[y + 1][x] && matrix[y][x - 1] && matrix[y + 1][x - 1]) {
      Offset p1 = Offset(heightX, widthY + pixelSize - (0.25 * pixelSize));
      Offset p2 = Offset(heightX, widthY + pixelSize);
      Offset p3 = Offset(heightX + (0.25 * pixelSize), widthY + pixelSize);

      _drawCurve(p1, p2, p3, canvas);
    }

    //top right check
    if (matrix[y - 1][x] && matrix[y][x + 1] && matrix[y - 1][x + 1]) {
      Offset p1 = Offset(heightX + pixelSize - (0.25 * pixelSize), widthY);
      Offset p2 = Offset(heightX + pixelSize, widthY);
      Offset p3 = Offset(heightX + pixelSize, widthY + (0.25 * pixelSize));

      _drawCurve(p1, p2, p3, canvas);
    }
  }

  //Round the corners and paint it
  void _setShape(int x, int y, Rect squareRect, Paint paint, List matrix,
      Canvas canvas, int n) {
    bool bottomRight = false;
    bool bottomLeft = false;
    bool topRight = false;
    bool topLeft = false;

    var _paint2 = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(0xff098282)
      ..isAntiAlias = true;

    if (!matrix[y + 1][x] &&
        !matrix[y][x + 1] &&
        !matrix[y - 1][x] &&
        !matrix[y][x - 1]) {
      canvas.drawRRect(
          RRect.fromRectAndCorners(
            squareRect,
            bottomRight: Radius.zero,
            bottomLeft: Radius.zero,
            topLeft: Radius.zero,
            topRight: Radius.zero,
          ),
          _paint2);
      return;
    }

    //bottom right check
    if (!matrix[y + 1][x] && !matrix[y][x + 1]) {
      bottomRight = true;
    }

    //top left check
    if (!matrix[y - 1][x] && !matrix[y][x - 1]) {
      topLeft = true;
    }

    //bottom left check
    if (!matrix[y + 1][x] && !matrix[y][x - 1]) {
      bottomLeft = true;
    }

    //top right check
    if (!matrix[y - 1][x] && !matrix[y][x + 1]) {
      topRight = true;
    }

    canvas.drawRRect(
        RRect.fromRectAndCorners(
          squareRect,
          bottomRight: Radius.zero,
          bottomLeft: Radius.zero,
          topLeft: Radius.zero,
          topRight: Radius.zero,
        ),
        paint);

//    if it is dot (arount an empty place)
    if (!bottomLeft && !bottomRight && !topLeft && !topRight) {
      canvas.drawRect(squareRect, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CustomPaint extends SingleChildRenderObjectWidget {
  const CustomPaint({
    Key key,
    this.painter,
    this.foregroundPainter,
    this.size = Size.zero,
    this.isComplex = true,
    this.willChange = false,
    Widget child,
  })  : assert(size != null),
        assert(isComplex != null),
        assert(willChange != null),
        assert(painter != null ||
            foregroundPainter != null ||
            (!isComplex && !willChange)),
        super(key: key, child: child);

  final CustomPainter painter;

  final CustomPainter foregroundPainter;

  final Size size;

  final bool isComplex;

  final bool willChange;

  @override
  RenderCustomPaint createRenderObject(BuildContext context) {
    return RenderCustomPaint(
      painter: painter,
      foregroundPainter: foregroundPainter,
      preferredSize: size,
      isComplex: isComplex,
      willChange: willChange,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderCustomPaint renderObject) {
    renderObject
      ..painter = painter
      ..foregroundPainter = foregroundPainter
      ..preferredSize = size
      ..isComplex = isComplex
      ..willChange = willChange;
  }

  @override
  void didUnmountRenderObject(RenderCustomPaint renderObject) {
    renderObject
      ..painter = null
      ..foregroundPainter = null;
  }
}
