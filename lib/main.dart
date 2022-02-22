import 'package:flutter/material.dart';
import 'package:janus_client_example/Home.dart';
import 'package:janus_client_example/streaming.dart';
import 'package:janus_client_example/videoCall2.dart';
import 'package:janus_client_example/videoCallCliente.dart';
import 'package:janus_client_example/videoCallVendedor.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        "/video_call_cliente": (c) => VideoCallV2Cliente(),
        "/video_call_vendedor": (c) => VideoCallV2Vendedor(),
        "/video_call_2": (c) => VideoCallV2Example(),
        "/streaming": (c) => Streaming(),

        "/": (c) => Home()
      },
    );
  }
}
