import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class ChatScreen extends StatefulWidget {
  String ipAddress;

  ChatScreen(this.ipAddress);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Isolate isolate;
  ReceivePort receivePort;
  String dataToSend;
  List<String> messageList = [];

  Future<void> start(BuildContext context) async {
    receivePort = ReceivePort();
    isolate = await Isolate.spawn(_handleIsolate, receivePort.sendPort);
    receivePort.listen((message) {
      print(Utf8Codec().decode(message));
      setState(() {
        messageList.add(Utf8Codec().decode(message));
      });
    });
  }

  Future<void> stop() async {
    receivePort.close();
    isolate.kill(priority: Isolate.immediate);
    isolate = null;
  }

  static void _handleIsolate(SendPort sendPort) async {
    var socket = await ServerSocket.bind('0.0.0.0', 12000);
    socket.listen((soc) {
      soc.listen((data) {
        sendPort.send(data);
      });
    });
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await start(context);
  }

  @override
  void dispose() async {
    super.dispose();
    await stop();
  }

  @override
  Widget build(BuildContext context) {
    int getLength() {
      if (messageList.length >= 1) {
        return messageList.length;
      } else {
        return 0;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('ChatScreen'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Expanded(
            flex: 1,
            child: getLength() >= 1
                ? ListView.builder(
                    reverse: false,
                    itemCount: getLength(),
                    itemBuilder: (context, index) {
                      return Container(
                        padding: EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.lightBlue.withOpacity(0.1),
                              Colors.lightBlue.withOpacity(0.9)
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20.0),
                            bottomLeft: Radius.circular(20.0),
                            bottomRight: Radius.circular(20.0),
                          ),
                        ),
                        child: Text(
                          '${messageList[index]}',
                          style: TextStyle(color: Colors.black, fontSize: 14.0),
                        ),
                      );
                    },
                  )
                : Container(),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    initialValue: '',
                    onChanged: (value) {
                      if (value != null) {
                        dataToSend = value;
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Send Message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20.0),
                        ),
                        borderSide: BorderSide(
                          color: Colors.grey,
                          style: BorderStyle.solid,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: FlatButton(
                      color: Colors.blue,
                      onPressed: () async {
                        try {
                          var inputSocket = await Socket.connect(
                              InternetAddress(widget.ipAddress.trim()), 12000);
                          inputSocket.write(dataToSend);
                          inputSocket.close();
                        } catch (error) {
                          print(error);
                        }
                      },
                      child: Text(
                        'Send',
                        style: TextStyle(color: Colors.white),
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
