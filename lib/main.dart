import 'package:flutter/material.dart';

void main() {
  runApp(const DuyuruApp());
}

class DuyuruApp extends StatelessWidget {
  const DuyuruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duyuru Sistemi',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('SOA Mimarisi Hazır!'))),
    );
  }
}
