import 'package:flutter/material.dart';

import 'main_feed_screen.dart'; 

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _errorMessage;

  void _handleJoin() {
    setState(() {
      
      if (_codeController.text.length != 6) {
        _errorMessage = "Lütfen 6 haneli kodu doğru girdiğinizden emin olun";
      } else {
        _errorMessage = null;
        
       
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainFeedScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sınıfa katılım sağlanıyor...')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sınıfa Katıl')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Lütfen 6 haneli sınıf kodunu giriniz',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: '000000',
                errorText: _errorMessage,
                counterText: "", 
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 10),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _handleJoin, 
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Şimdi Katıl'),
            ),
          ],
        ),
      ),
    );
  }
}