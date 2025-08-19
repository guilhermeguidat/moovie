import 'package:flutter/material.dart';
import 'package:moovie/ui/screens/search_screen.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navega para a tela de pesquisa
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        decoration: BoxDecoration(
          color: const Color(0xFF221A2A),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF8C8696)),
            const SizedBox(width: 10),
            const Expanded(
              child: TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Buscar filmes e séries...',
                  hintStyle: TextStyle(color: Color(0xFF8C8696)),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.tune, color: Color(0xFF8C8696)),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}