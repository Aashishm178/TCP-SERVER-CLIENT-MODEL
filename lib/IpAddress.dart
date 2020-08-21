import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:tcp/ChatScreen.dart';

class IpAddress extends StatefulWidget {
  @override
  _IpAddressState createState() => _IpAddressState();
}

class _IpAddressState extends State<IpAddress> {
  String ipAddress;
  String connectionIp;
  ReceivePort receivePort;
  Isolate isolate;

  Future<void> start() async {
    receivePort = ReceivePort();
    isolate = await Isolate.spawn(_handleIsolate, receivePort.sendPort);
    receivePort.listen((map) {
      if (Utf8Codec().decode(map['data']) == 'request') {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                  '${map['address'].address} has requested to connect with you'),
              actions: <Widget>[
                FlatButton(
                    onPressed: () async {
                      var socket = await Socket.connect(
                          InternetAddress(map['address'].address), 10000);
                      socket.write('requestallowed');
                      socket.close();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ChatScreen(map['address'].address),
                        ),
                      );
                    },
                    child: Text('Allow')),
                FlatButton(
                    onPressed: () async {
                      var socket = await Socket.connect(
                          InternetAddress(map['address'].address), 10000);
                      socket.write('requestdisallowed');
                      socket.close();
                      Navigator.of(context).pop();
                    },
                    child: Text('Disallow')),
              ],
            );
          },
        );
      }
      if (Utf8Codec().decode(map['data']) == 'requestallowed') {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title:
                  Text('${map['address'].address} has accepted your request'),
              actions: <Widget>[
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatScreen(map['address'].address),
                      ),
                    );
                  },
                  child: Text('Start Conversation'),
                ),
              ],
            );
          },
        );
      }
      if (Utf8Codec().decode(map['data']) == 'requestdisallowed') {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title:
                    Text('${map['address'].address} has rejected your request'),
                actions: <Widget>[
                  FlatButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Ok'),
                  ),
                ],
              );
            });
      }
    });
  }

  static void _handleIsolate(SendPort sendPort) async {
    Map<String, dynamic> map = {};
    var socket = await ServerSocket.bind(InternetAddress('0.0.0.0'), 10000,
        shared: true);
    socket.listen((soc) {
      soc.listen((data) {
        if (data != null) {
          soc.write('ack');
          map = {'address': soc.remoteAddress, 'data': data};
          sendPort.send(map);
          map.clear();
        } else {
          soc.write('nack');
        }
      });
    });
  }

  void stop() {
    receivePort = null;
    isolate.kill(priority: Isolate.immediate);
    isolate = null;
  }

  @override
  void didChangeDependencies() async {
    await start();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
    stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text('Ip Address'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Enter Ip Address'),
                    content: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            onChanged: (value) {
                              connectionIp = value;
                            },
                          ),
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      FlatButton(
                        onPressed: () async {
                          var socket = await Socket.connect(
                              InternetAddress(connectionIp), 10000);
                          socket.write('request');
                          socket.listen((event) {
                            print(Utf8Codec().decode(event));
                          });
                          socket.close();
                        },
                        child: Text('Connect'),
                      ),
                      FlatButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel'),
                      )
                    ],
                  );
                },
              );
            },
          )
        ],
      ),
      body: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  onChanged: (value) {
                    ipAddress = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'Enter Ip Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20.0),
                      ),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 10.0),
                child: FlatButton(
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(ipAddress),
                      ),
                    );
                  },
                  child: Text(
                    'Ok',
                    style: TextStyle(color: Colors.white, fontSize: 15.0),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
