import 'package:flutter/material.dart';
import 'package:moovie/providers/user_provider.dart';
import 'package:moovie/ui/screens/login_screen.dart';
import 'package:provider/provider.dart';
// Removida a barra inferior

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {

  // Função para lidar com o logout do usuário
  void _logout() async {
    // Chama o método logout do UserProvider para limpar o estado de login
    await Provider.of<UserProvider>(context, listen: false).logout();

    // Navega de volta para a tela de login, limpando a pilha de navegação
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191221),
        foregroundColor: Colors.white,
        title: const Text('Configurações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              _buildHeader(),
              const SizedBox(height: 30),
              _buildActionButtons(),
              const SizedBox(height: 30),
              _buildFooter(),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurações',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Personalize sua experiência no Moovie',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF8C8696),
          ),
        ),
      ],
    );
  }

  // Seção de idioma removida

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildRedButton(
          title: 'Sair da conta',
          icon: Icons.logout,
          onPressed: _logout, // Conecta o botão à função de logout
        ),
        const SizedBox(height: 12),
        _buildRedButton(
          title: 'Excluir conta',
          icon: Icons.delete_forever,
          onPressed: _confirmDeleteAccount,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return const Center(
      child: Column(
        children: [
          Text(
            'Moovie v1.0.0',
            style: TextStyle(color: Color(0xFF8C8696)),
          ),
          SizedBox(height: 5),
          Text(
            '© 2025 Moovie. Todos os direitos reservados.',
            style: TextStyle(color: Color(0xFF8C8696)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Widgets auxiliares removidos junto com a seção de idioma

  // Toggle de tema removido

  Widget _buildRedButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 15.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF221A2A),
          title: const Text('Excluir conta', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Tem certeza que deseja excluir sua conta? Esta ação não pode ser desfeita.',
            style: TextStyle(color: Color(0xFFBFB7C8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await Provider.of<UserProvider>(context, listen: false).deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}