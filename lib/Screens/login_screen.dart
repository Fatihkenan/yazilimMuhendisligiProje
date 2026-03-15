//login_screen.dart 
import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'student_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // الانتقال إلى صفحة الطالب الرئيسية
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))]),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))]),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.login, size: 60, color: Color(0xFF6366F1)),
                              const SizedBox(height: 24),
                              const Text('Giriş Yap', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                              const SizedBox(height: 8),
                              const Text('Hesabınıza giriş yapın', style: TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
                              const SizedBox(height: 32),
                              TextFormField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                                decoration: InputDecoration(labelText: 'E-posta', prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: const Color(0xFFF9FAFB)),
                                validator: (value) => (value == null || value.isEmpty || !value.contains('@')) ? 'Geçerli bir e-posta girin' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _login(),
                                decoration: InputDecoration(
                                  labelText: 'Şifre',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                ),
                                validator: (value) => (value == null || value.isEmpty) ? 'Şifre gerekli' : null,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2),
                                  child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Giriş Yap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                                child: const Text('Hesabınız yok mu? Kayıt olun', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}