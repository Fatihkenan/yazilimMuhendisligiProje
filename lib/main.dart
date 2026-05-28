import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DuyuruApp());
}

class DuyuruApp extends StatelessWidget {
  const DuyuruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Odaksınıf',
      debugShowCheckedModeBanner: false, // Sağ üstteki kırmızı etiketi kaldırır
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5), // Teams Konsepti İndigo Rengi
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      // --- OTOMATİK GİRİŞ KONTROLÜ (AUTH STATE) ---
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Durum: Firebase ile bağlantı kuruluyor
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFF8FAFC),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              ),
            );
          }

          // 2. Durum: Kullanıcı oturumu açık, direkt Ana Ekrana gönder
          if (snapshot.hasData) {
            return const HomeScreen();
          }

          // 3. Durum: Oturum kapalı, Karşılama/Giriş Ekranına gönder
          return const WelcomeScreen();
        },
      ),
    );
  }
}
