// ignore_for_file: import_of_legacy_library_into_null_safe, unnecessary_null_comparison

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:codereader/getapi.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'api_key.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as image_lib;

import 'debug.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String comment = '';

  // ignore: non_constant_identifier_names
  var explanation_text = "";

  var img64 = "";
  _readable(String parsedtext) async {
    final String prompt = """Function 1:
        export const emojifyArray = (arr: any) => {{
        for (let i = 0; i < arr.length; i++) {{
            if (arr[i].sent_emails !== null) {{
                emojify(arr[i].sent_emails);
                console.log(arr[i].sent_emails);
            }}
        }}
        return arr;
        }} 

          A short description of what Function 1 does:
          The emojifyArray function takes an array of objects and for each object in the array, it checks if the object has a sent_emails property. If it does, it calls the emojify function on that property.
          The emojify function takes a string and replaces all instances of the word "

        Function 2:
        const getKey = () => {{
            let key = localStorage.getItem("key");
            console.log("key " + key);
            if (!key) {{
                window.location.href = "/login";
            }}
            return key;
        }};
         
          A short description of what Function 2 does:
        Gets the key from local storage and redirects to the login page if it is not found.

        Function 3:
        $parsedtext
          A short description of what Function 3 does:
          """;

    if (kDebugMode) {
      print("Starting openAI call...");
    }
    String url;
    if (Platform.isAndroid) {
      url = "https://8a1a-66-235-3-1.ngrok.io/api?Query=" + prompt.toString();
    } else {
      url = "https://c3f8-66-235-3-1.ngrok.io/api?Query=" + prompt.toString();
    }
    final dataP = await getData(url);
    final data = jsonDecode(dataP);

    setState(() {
      if (kDebugMode) {
        print("...got data from openAI call!");
      }
      String bullet = "•";
      var sec = "";
      comment = data["choices"][0]["text"];
      comment = comment.replaceAll("}", "");
      comment = comment.replaceAll("/", "");
      comment = comment.replaceAll("*", "");
      comment = comment.replaceAll("<div", "");
      comment = comment.replaceAll(">", "");

      comment = comment.replaceAll("  ", "");
      if (comment.substring(comment.length - 1) != '.') {
        comment = comment.substring(0, comment.lastIndexOf("\n"));
      }
      if (comment.contains("\n")) {
        sec = comment.substring(0, comment.indexOf("\n"));
      }
      var x = comment[0];
      comment = comment.substring(0, 0) + "?" + comment.substring(1);
      comment = comment.replaceAll(sec, "");
      comment = comment.substring(0, 0) + x + comment.substring(1);
      comment = comment.replaceAll("\n\n", "");

      comment = bullet + " " + comment;
      comment = comment.replaceAll("\n", "\n" + bullet + " ");

      explanation_text = "Explanation:";
      EasyLoading.dismiss();
    });
  }

  void _configLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.cubeGrid
      ..loadingStyle = EasyLoadingStyle.custom
      ..indicatorSize = 45.0
      ..fontSize = 20
      ..textStyle = GoogleFonts.exo(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)
      ..radius = 10.0
      ..progressColor = Colors.blue
      ..backgroundColor = Colors.black.withOpacity(0.5)
      ..indicatorColor = Colors.blue
      ..textColor = Colors.white
      ..maskColor = Colors.blue.withOpacity(0.5)
      ..userInteractions = true
      ..dismissOnTap = false;
  }

  Future<Uint8List> _readFileByte(String filePath) async {
    Uri myUri = Uri.parse(filePath);
    File image = File.fromUri(myUri);
    Uint8List bytes = Uint8List(0);
    await image.readAsBytes().then((value) {
      bytes = Uint8List.fromList(value);
      if (kDebugMode) {
        print('reading of bytes is completed');
      }
    }).catchError((onError) {
      if (kDebugMode) {
        print('Exception Error while reading audio from path:' +
            onError.toString());
      }
    });
    return bytes;
  }

  Future<image_lib.Image> _fileToImage(File image) async {
    final imagefile = await ImagePicker.pickImage(
        source: ImageSource.gallery, maxWidth: 670, maxHeight: 970);

    final loadedImage = await decodeImageFromList(imagefile.readAsBytesSync());

    return image_lib.Image.fromBytes(
        int.parse(loadedImage.width.toString()),
        int.parse(loadedImage.height.toString()),
        await _readFileByte(image.path.toString()));
  }

  _parsethetext() async {
    debugprint("pressed");
    // pick a image
    File imagefile;

    imagefile = await ImagePicker.pickImage(
        source: ImageSource.gallery, maxWidth: 670, maxHeight: 970);

    debugprint("Opened gallery and selected image");

    // prepare the image
    image_lib.Image image = await _fileToImage(imagefile);

    greyscale(image);

    var bytes = image.getBytes();
    img64 = base64Encode(bytes);

    // send to api
    debugprint("sending to OCR...");
    _configLoading();

    await EasyLoading.show(status: "Loading...", dismissOnTap: false);

    Uri url = Uri.parse('https://api.ocr.space/parse/image');

    var payload = {"base64Image": "data:image/jpg;base64,${img64.toString()}"};
    var header = {"apikey": ocr_api_key};
    var post = await http.post(url = url, body: payload, headers: header);

    debugprint("Sent to OCR");

    debugprint("Sent post to: $url");
    // get result from api
    var result = jsonDecode(post.body);
    setState(() {
      _readable(result['ParsedResults'][0]['ParsedText']);
    });
  }

  Image getImage() {
    Image ret = Image.memory(base64Decode(img64));
    if (base64Decode(img64).toString() == "[]") {
      Uint8List blankBytes = const Base64Codec().decode(
          "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAoMBgDTD2qgAAAAASUVORK5CYII=");
      ret = Image.memory(blankBytes, height: 1);
    }
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 70.0),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: ElevatedButton(
                onPressed: () {
                  _parsethetext();
                },
                child: Text(
                  'Explain Code',
                  style: GoogleFonts.exo(
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: getImage(),
            ),
            const SizedBox(height: 10.0),
            Container(
              alignment: Alignment.center,
              child: Column(
                children: <Widget>[
                  Text(
                    explanation_text,
                    style: GoogleFonts.exo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Container(
                    margin: const EdgeInsets.all(16.0),
                    child: Text(
                      comment,
                      textAlign: TextAlign.left,
                      style: GoogleFonts.exo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void greyscale(image_lib.Image image) {
    //Y = 0.299 R + 0.587 G + 0.114 B
    for (var i = 0; i < image.width; ++i) {
      for (var j = 0; j < image.height; ++j) {
        int pixel = image.getPixel(i, j);
        debugprint(pixel.toString());
      }
    }
  }
}
