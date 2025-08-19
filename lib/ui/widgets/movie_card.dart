import 'package:flutter/material.dart';
import 'package:moovie/models/movie.dart';
import 'package:moovie/models/movie_interaction.dart';
import 'package:moovie/services/tmdb_service.dart';
import 'package:moovie/ui/screens/movie_details_screen.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final bool isFavorite;
  final MovieInteraction? interaction;

  const MovieCard({
    super.key,
    required this.movie,
    this.isFavorite = false,
    this.interaction,
  });

  @override
  Widget build(BuildContext context) {
    final TmdbService tmdbService = TmdbService();

    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: Container(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildPoster(tmdbService),
                _buildFavoriteIndicator(),
                _buildRatingIndicator(),
                _buildStatusIndicator(),
              ],
            ),
            const SizedBox(height: 8),
            _buildTitle(),
            _buildReleaseYear(),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(movie: movie),
      ),
    );
  }

  Widget _buildPoster(TmdbService tmdbService) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: Image.network(
        tmdbService.getImageUrl(movie.posterPath),
        height: 200,
        width: 140,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            width: 140,
            color: const Color(0xFF221A2A),
            child: const Center(
              child: Icon(Icons.broken_image, color: Color(0xFF8C8696)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteIndicator() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildRatingIndicator() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
            const SizedBox(width: 4),
            Text(
              movie.voteAverage.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (interaction?.isWatched == true) {
      return Positioned(
        bottom: 8,
        right: 8,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 16,
          ),
        ),
      );
    } else if (interaction?.isWantToWatch == true) {
      return Positioned(
        bottom: 8,
        right: 8,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF6B45A1).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            Icons.bookmark,
            color: Colors.white,
            size: 16,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTitle() {
    return Text(
      movie.title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildReleaseYear() {
    return Text(
      movie.releaseDate.isNotEmpty ? movie.releaseDate.substring(0, 4) : 'N/A',
      style: const TextStyle(
        color: Color(0xFF8C8696),
        fontSize: 12,
      ),
    );
  }
}