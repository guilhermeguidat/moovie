import 'package:flutter/material.dart';
import 'package:moovie/models/movie.dart';
import 'package:moovie/models/movie_interaction.dart';
import 'package:intl/intl.dart';

class ActivityItem extends StatelessWidget {
  final Movie movie;
  final MovieInteraction interaction;

  const ActivityItem({
    super.key,
    required this.movie,
    required this.interaction,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF221A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 90,
              child: movie.posterPath.isNotEmpty
                  ? Image.network(
                      'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF3A2E49),
                        child: const Icon(Icons.movie, color: Colors.white54),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF3A2E49),
                      child: const Icon(Icons.movie, color: Colors.white54),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (interaction.rating != null) ...[
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < interaction.rating! ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFC107),
                          size: 16,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${interaction.rating}/5',
                        style: const TextStyle(
                          color: Color(0xFFBFB7C8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (interaction.review?.isNotEmpty == true) ...[
                  Text(
                    interaction.review!,
                    style: const TextStyle(
                      color: Color(0xFFBFB7C8),
                      fontSize: 14,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  _formatDate(interaction.watchedDate),
                  style: const TextStyle(
                    color: Color(0xFF8C8696),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
