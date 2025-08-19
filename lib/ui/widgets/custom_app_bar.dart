import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moovie/providers/user_provider.dart';
import 'package:moovie/ui/screens/profile_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 92,
      flexibleSpace: _buildGradientBackground(),
      title: _buildUserInfo(context),
      bottom: _buildBottomSpacing(),
      actions: _buildActions(),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1950), Color(0xFF1A0F2D)],
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.user;
        final displayName = user?.name.trim();
        final firstName = (displayName != null && displayName.isNotEmpty)
            ? displayName.split(' ').first
            : null;
        final hello = (firstName != null && firstName.isNotEmpty)
            ? 'Olá, $firstName!'
            : 'Olá!';
            
        return GestureDetector(
          onTap: () => _navigateToProfile(context),
          child: Row(
            children: [
              _buildUserAvatar(),
              const SizedBox(width: 15),
              _buildUserText(hello),
              const SizedBox(width: 12),
            ],
          ),
        );
      },
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen())
    );
  }

  Widget _buildUserAvatar() {
    return const CircleAvatar(
      radius: 20,
      backgroundColor: Color(0xFF6B45A1),
      child: Icon(Icons.person, color: Colors.white, size: 24),
    );
  }

  Widget _buildUserText(String hello) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hello,
            style: const TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: Colors.white
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const Text(
            'Bem-vindo de volta',
            style: TextStyle(
              fontSize: 14, 
              color: Color(0xFFB9A9D3)
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildBottomSpacing() {
    return const PreferredSize(
      preferredSize: Size.fromHeight(16),
      child: SizedBox(height: 16),
    );
  }

  List<Widget> _buildActions() {
    return const [
      Padding(
        padding: EdgeInsets.only(right: 20.0),
        child: Icon(
          Icons.notifications_none, 
          color: Color(0xFFE1D8EF)
        ),
      ),
    ];
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}