import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Oturum kontrolü için eklendi
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart'; // Doğrudan içeri almak için eklendi

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(
            0xFF4F46E5,
          ), // Yeni Teams konseptimizin ana rengi
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      // --- OTOMATİK GİRİŞ KONTROLÜ (AUTH STATE) ---
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Eğer Firebase ile iletişim kuruluyorsa bekleme ekranı göster
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              ),
            );
          }

          // Eğer kullanıcı daha önceden giriş yapmışsa doğrudan Ana Ekrana at!
          if (snapshot.hasData) {
            return const HomeScreen();
          }

          // Eğer kullanıcı giriş yapmamışsa veya çıkış yaptıysa Karşılama Ekranına at
          return const WelcomeScreen();
        },
      ),
    );
  }
}
