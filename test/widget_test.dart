import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yazilimmuhendislgiproje/main.dart'; 

void main() {
  testWidgets('Uygulama basariyla basliyor mu testi', (WidgetTester tester) async {
    await tester.pumpWidget(const DuyuruApp());
    expect(find.text('Duyuru Sistemi'), findsWidgets);
  });
}
