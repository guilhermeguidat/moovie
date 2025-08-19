import 'package:flutter/material.dart';

class TabSection extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const TabSection({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = ['Quero ver', 'Concluídos', 'Favoritos'];
    final icons = [Icons.add, Icons.check_circle, Icons.favorite];

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(tabs.length, (index) {
            final isSelected = index == selectedIndex;
            
            return Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: ElevatedButton(
                onPressed: () => onTap(index),
                style: _buildButtonStyle(isSelected),
                child: _buildButtonContent(tabs[index], icons[index], isSelected),
              ),
            );
          }),
        ),
      ),
    );
  }

  ButtonStyle _buildButtonStyle(bool isSelected) {
    return ElevatedButton.styleFrom(
      backgroundColor: isSelected 
        ? const Color(0xFF5A33A1)
        : const Color(0xFF221A2A),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected 
            ? const Color(0xFF8F4DE2)
            : const Color(0xFF2E243A),
        ),
      ),
    );
  }

  Widget _buildButtonContent(String tabName, IconData icon, bool isSelected) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon, 
          size: 16, 
          color: isSelected 
            ? Colors.white
            : const Color(0xFF8C8696)
        ),
        const SizedBox(width: 6),
        Text(
          tabName,
          style: TextStyle(
            color: isSelected 
              ? Colors.white
              : const Color(0xFF8C8696),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}