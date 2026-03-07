// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yazilimmuhendislgiproje/main.dart'; 

void main() {
  testWidgets('Uygulama basariyla basliyor mu testi', (WidgetTester tester) async {
    // Sadece DuyuruApp'i baslat
    await tester.pumpWidget(const DuyuruApp());

    // Ekranda WelcomeScreen'deki yazilardan biri var mi kontrol et
    expect(find.text('Duyuru Sistemi'), findsWidgets);
  });
}