import 'package:flutter/material.dart';
import 'package:tcp/IpAddress.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IpAddress(),
    );
  }
}
