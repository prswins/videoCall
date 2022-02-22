import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';





class Registros {
  String nameScreen;
  Registros(this.nameScreen);

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/${nameScreen}Log.txt');
  }

  Future<String> getLocalFile() async {
    String path = await _localPath;
    return '$path/${nameScreen}Log.txt';
  }

  Future<File> writeLog(String palavra) async {
    final file = await _localFile;
    String texto = await readLog();
    // Write the file
    return file.writeAsString("$texto\n $palavra\n");
  }

  Future<String> readLog() async {
    try {
      final file = await _localFile;

      // Read the file
      final contents = await file.readAsString();

      return contents;
    } catch (e) {
      print(e);
      return "";
    }
  }

 onShare(BuildContext context) async {
    // A builder is used to retrieve the context immediately
    // surrounding the ElevatedButton.
    //
    // The context's `findRenderObject` returns the first
    // RenderObject in its descendent tree when it's not
    // a RenderObjectWidget. The ElevatedButton's RenderObject
    // has its position and size after it's built.
    final RenderBox box = context.findRenderObject() as RenderBox;
    String path = await getLocalFile();
    if ( path.isNotEmpty) {
      await Share.shareFiles([path],
          text: "LOG ERRORS "+DateTime.now().toIso8601String(),
          subject: "Screen: $nameScreen",
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
    }
     /*else {
      await Share.share("text",
          subject: "subject",
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
    }*/
  }

}
