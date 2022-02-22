import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ftoast/ftoast.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:janus_client/utils.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_example/registros.dart';

class VideoCallV2Cliente extends StatefulWidget {
  @override
  _VideoCallV2ClienteState createState() => _VideoCallV2ClienteState();
}

class _VideoCallV2ClienteState extends State<VideoCallV2Cliente> {
  JanusClient j;
  RestJanusTransport rest;
  WebSocketJanusTransport ws;
  JanusSession session;
  JanusPlugin publishVideo;
  TextEditingController nameController = TextEditingController();
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();
  MediaStream myStream;
  Registros registro = Registros("VideoCallV2Cliente");

  var servers = [
    'wss://master-janus.onemandev.tech/websocket',
    'wss://janus.conf.meetecho.com/ws',
    'https://unified-janus.onemandev.tech/rest',
    'wss://janus.conf.meetecho.com/ws',
    'wss://unified-janus.onemandev.tech/websocket',
    'https://unified-janus.onemandev.tech/rest'
  ];

  Map<String, String> servermap = {
    'janus_ws': 'wss://janus.conf.meetecho.com/ws',
    'janus_rest': 'https://janus.conf.meetecho.com/janus',
    'onemandev_master_ws': 'wss://master-janus.onemandev.tech/websocket',
    'onemandev_master_rest': 'https://master-janus.onemandev.tech/rest',
    'onemandev_unified_rest': 'https://unified-janus.onemandev.tech/rest',
    'onemandev_unified_ws': 'wss://unified-janus.onemandev.tech/websocket'
  };

  String userCall = "";

  /* makeCall() async {
    await _localRenderer.initialize();
    _localRenderer.srcObject = await publishVideo.initializeMediaDevices(
        mediaConstraints: {"audio": true, "video": true});
    RTCSessionDescription offerToCall = await publishVideo.createOffer();
    var body = {"request": "call", "username": nameController.text};
    publishVideo.send(
      data: body,
      jsep: offerToCall,
    );
    nameController.text = "";
  }*/

  logDialog() async {
    String log = await registro.readLog();
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text("Log"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [Text(log)],
              ),
            ),
          );
        });
  }

  /*registerDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text("Register As"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: "Your Name"),
                  controller: nameController,
                ),
                RaisedButton(
                  color: Colors.green,
                  textColor: Colors.white,
                  onPressed: () {
                    registerUser(nameController.text);
                  },
                  child: Text("Proceed"),
                )
              ],
            ),
          );
        });
  }*/

  /*makeCallDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text("Call Registered User or wait for user to call you"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                      labelText: "Name Of Registered User to call"),
                  controller: nameController,
                ),
                RaisedButton(
                  color: Colors.green,
                  textColor: Colors.white,
                  onPressed: () {
                    makeCall();
                  },
                  child: Text("Call"),
                )
              ],
            ),
          );
        });
  }*/

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  initJanusClient() async {
    setState(() {
      rest = RestJanusTransport(url: servermap['janus_rest']);
      ws = WebSocketJanusTransport(url: servermap['janus_ws']);
      j = JanusClient(transport: ws, iceServers: [
        RTCIceServer(
            url: "stun:stun.voip.eutelia.it:3478", username: "", credential: "")
      ]);
    });
    session = await j.createSession();
    publishVideo = await session.attach(JanusPlugins.VIDEO_CALL);
    publishVideo.remoteStream.listen((event) {
      setState(() {
        _remoteRenderer.srcObject = event;
      });
    });
    publishVideo.messages.listen((even) async {
      print(even);
      var pluginData = even.event['plugindata'];
      if (pluginData != null) {
        var data = pluginData['data'];
        await registro.writeLog(
            DateTime.now().toIso8601String() + ": " + data.toString());
        if (data != null) {
          var result = data["result"];
          if (result != null) {
            if (result["event"] != null) {
              var event = result["event"];

              if (event == 'registered') {
                FToast.toast(context, msg: "registered", duration: 2000);

                // Navigator.of(context).pop();
                //  nameController.clear();
                //   makeCallDialog();
              } else if (event == 'accepted') {
                var peer = result["username"];
                if (peer != null) {
                  debugPrint("Call started!");
                  FToast.toast(context, msg: "Call started!", duration: 2000);
                } else {}
                // Video call can start
                if (even.jsep != null) {
                  publishVideo.handleRemoteJsep(even.jsep);
                  //Navigator.of(context).pop();
                }
              } else if (event == 'incomingcall') {
                debugPrint("Incoming call from " + result["username"] + "!");
                FToast.toast(context,
                    msg: "Incoming call from " + result["username"] + "!",
                    duration: 4000);

                var yourusername = result["username"];

                await _localRenderer.initialize();
                dynamic janusPlugin = await publishVideo
                    .initializeMediaDevices(mediaConstraints: {
                  "audio": true,
                  "video": {
                    "mandatory": {
                      //"minWidth": '1280',
                      // Provide your own width, height and frame rate here
                      // "minHeight": '720',
                      "minFrameRate": '60',
                    },
                    "facingMode": "user",
                    "optional": [],
                  }
                });
                setState(() {
                  _localRenderer.srcObject = janusPlugin;
                });

                if (even.jsep != null) {
                  await publishVideo.handleRemoteJsep(even.jsep);
                  //Navigator.of(context).pop();
                }
                // Notify user
                var offer = await publishVideo.createAnswer();
                var body = {"request": "accept"};
                FToast.toast(context, msg: "accept", duration: 2000);
                publishVideo.send(
                  data: body,
                  jsep: offer,
                );

                // print(publishVideo.webRTCHandle.pc.);
              } else if (event == 'hangup') {
                FToast.toast(context, msg: "hangup", duration: 2000);
                await destroy();
              }
            }
          }
        }
      }
    });
    // await registerDialog();
    registerUser("cliente01");
  }

  @override
  void deactivate() {
    // TODO: implement deactivate
    super.deactivate();
    _remoteRenderer.dispose();
    _localRenderer.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initJanusClient();

    // janusClient.connect(onSuccess: (sessionId) {
    //   janusClient.attach(Plugin(
    //       onRemoteStream: (remoteStream) {
    //         _remoteRenderer.srcObject = remoteStream;
    //       },
    //       plugin: "janus.plugin.videocall",
    //       onMessage: ,
    //       onSuccess: (plugin) {
    //         setState(() {
    //           publishVideo = plugin;
    //           registerDialog();
    //         });
    //       }));
    // });
  }

  registerUser(userName) {
    // if (publishVideo != null) {
    publishVideo.send(data: {"request": "register", "username": userName});
    setState(() {
      userCall = userName;
    });
    //   onSuccess: () {
    //     print("User registered");
    //     nameController.text = "";
    //     Navigator.pop(context);
    //     makeCallDialog();
    //   },
    // onError: (error) {
    // print(error);
    // }
    // }
  }

  destroy() async {
    await publishVideo.dispose();
     session.dispose();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userCall),
      ),
      body: Stack(children: [
        Column(
          children: [
            Expanded(
              flex: 1,
              child: RTCVideoView(
                _remoteRenderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
              ),
            ),
            Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                      boxShadow: [BoxShadow(color: Colors.black45)]),
                  child: RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  ),
                ))
          ],
        ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            child: IconButton(
                icon: Icon(Icons.switch_camera),
                color: Colors.black,
                onPressed: () {
                  publishVideo.switchCamera();
                }),
            padding: EdgeInsets.all(25),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            child: IconButton(
                icon: Icon(Icons.report),
                color: Colors.black,
                onPressed: () {
                  logDialog();
                }),
            padding: EdgeInsets.all(25),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            child: CircleAvatar(
                backgroundColor: Colors.red,
                radius: 30,
                child: IconButton(
                    icon: Icon(Icons.call_end),
                    color: Colors.white,
                    onPressed: () {
                      publishVideo.send(
                        data: {'request': 'hangup'},
                      );
                    })),
            padding: EdgeInsets.all(10),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            child: CircleAvatar(
                backgroundColor: Colors.green,
                radius: 30,
                child: IconButton(
                    icon: Icon(Icons.share),
                    color: Colors.white,
                    onPressed: () async {
                      registro.onShare(context);
                    })),
            padding: EdgeInsets.all(10),
          ),
        )
      ]),
    );
  }

  @override
  void dispose() async {
    // TODO: implement dispose
    super.dispose();
  }
}
