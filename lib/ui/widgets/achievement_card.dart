import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final int? currentProgress;
  final int? targetProgress;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.currentProgress,
    this.targetProgress,
  });
}

class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: achievement.isUnlocked 
            ? const Color(0xFF2B213A) 
            : const Color(0xFF1A1520),
        borderRadius: BorderRadius.circular(12),
        border: achievement.isUnlocked 
            ? Border.all(color: const Color(0xFF6B45A1), width: 1)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: achievement.isUnlocked 
                  ? const Color(0xFF6B45A1) 
                  : const Color(0xFF3A2E49),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              achievement.icon,
              color: achievement.isUnlocked ? Colors.white : const Color(0xFF8C8696),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: achievement.isUnlocked ? Colors.white : const Color(0xFF8C8696),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: achievement.isUnlocked 
                        ? const Color(0xFFBFB7C8) 
                        : const Color(0xFF6B5B72),
                    fontSize: 14,
                  ),
                ),
                if (achievement.currentProgress != null && achievement.targetProgress != null && !achievement.isUnlocked) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: achievement.currentProgress! / achievement.targetProgress!,
                    backgroundColor: const Color(0xFF3A2E49),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B45A1)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${achievement.currentProgress}/${achievement.targetProgress}',
                    style: const TextStyle(
                      color: Color(0xFF8C8696),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (achievement.isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Desbloqueado',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
