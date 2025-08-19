import 'package:flutter/material.dart';
import 'package:moovie/providers/user_provider.dart';
import 'package:moovie/ui/screens/home_screen.dart';
import 'package:moovie/ui/screens/login_screen.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Usa addPostFrameCallback para garantir que o contexto esteja disponível
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUserStatus());
  }

  void _checkUserStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // O método loadCurrentUser agora verifica se há um usuário logado
    await userProvider.loadCurrentUser();
    if (!mounted) return;

    // Redireciona com base no status do usuário
    if (userProvider.user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF191221),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6B45A1),
        ),
      ),
    );
  }
}