import 'package:flutter/material.dart';
import 'package:moovie/database/database_helper.dart';
import 'package:moovie/models/movie.dart';
import 'package:moovie/models/movie_interaction.dart';
import 'package:moovie/services/tmdb_service.dart';

class MovieProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  int? _currentUserId;

  final Set<int> _favoriteMovieIds = {};

  MovieProvider(this._dbHelper);

  void setCurrentUserId(int? userId) async {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      if (_currentUserId != null) {
        await _loadFavorites();
      } else {
        _favoriteMovieIds.clear();
      }
      notifyListeners();
    }
  }

  Future<void> _loadFavorites() async {
    _favoriteMovieIds.clear();
    if (_currentUserId != null) {
      final favoriteInteractions = await _dbHelper.getMovieInteractionsByInteraction(_currentUserId!, 'isFavorite');
      _favoriteMovieIds.addAll(favoriteInteractions.map((i) => i.movieId));
    }
  }

  Future<List<Movie>> getUserMovies(int userId, String interactionType) async {
    final interactions = await _dbHelper.getMovieInteractionsByInteraction(userId, interactionType);
    final movieIds = interactions.map((i) => i.movieId).toList();
    if (movieIds.isEmpty) {
      return [];
    }
    return await _dbHelper.getMoviesByIds(movieIds);
  }

  Future<void> saveMovie(Movie movie) async {
    await _dbHelper.insertMovie(movie);
  }

  Future<MovieInteraction?> getInteraction(int movieId) async {
    if (_currentUserId == null) return null;
    return await _dbHelper.getMovieInteraction(_currentUserId!, movieId);
  }

  Future<void> toggleWatched(Movie movie) async {
    if (_currentUserId == null) return;
    await _dbHelper.insertMovie(movie);
    MovieInteraction? interaction = await getInteraction(movie.id);

    if (interaction == null) {
      interaction = MovieInteraction(
        userId: _currentUserId!, 
        movieId: movie.id, 
        isWatched: true,
        watchedDate: DateTime.now(),
      );
      if (movie.runtime == null) {
        final runtime = await TmdbService().getMovieRuntime(movie.id);
        if (runtime != null) {
          await _dbHelper.insertMovie(Movie(
            id: movie.id,
            title: movie.title,
            overview: movie.overview,
            posterPath: movie.posterPath,
            voteAverage: movie.voteAverage,
            releaseDate: movie.releaseDate,
            runtime: runtime,
          ));
        }
      }
      interaction.isWantToWatch = false;
      await _dbHelper.saveMovieInteraction(interaction);
    } else {
      interaction.isWatched = !interaction.isWatched;
      if (interaction.isWatched) {
        interaction.isWantToWatch = false;
        interaction.watchedDate = DateTime.now();
      } else {
        interaction.watchedDate = null;
      }
      await _dbHelper.updateMovieInteraction(interaction);
    }
    notifyListeners();
  }

  Future<void> toggleFavorite(Movie movie) async {
    if (_currentUserId == null) return;
    await _dbHelper.insertMovie(movie);
    MovieInteraction? interaction = await getInteraction(movie.id);

    if (interaction == null) {
      interaction = MovieInteraction(userId: _currentUserId!, movieId: movie.id, isFavorite: true);
      await _dbHelper.saveMovieInteraction(interaction);
      _favoriteMovieIds.add(movie.id);
    } else {
      interaction.isFavorite = !interaction.isFavorite;
      await _dbHelper.updateMovieInteraction(interaction);
      if (interaction.isFavorite) {
        _favoriteMovieIds.add(movie.id);
      } else {
        _favoriteMovieIds.remove(movie.id);
      }
    }
    notifyListeners();
  }

  Future<void> toggleWantToWatch(Movie movie) async {
    if (_currentUserId == null) return;
    await _dbHelper.insertMovie(movie);
    MovieInteraction? interaction = await getInteraction(movie.id);

    if (interaction == null) {
      interaction = MovieInteraction(userId: _currentUserId!, movieId: movie.id, isWantToWatch: true);
      await _dbHelper.saveMovieInteraction(interaction);
    } else {
      interaction.isWantToWatch = !interaction.isWantToWatch;
      if (interaction.isWantToWatch) {
        interaction.isWatched = false;
      }
      await _dbHelper.updateMovieInteraction(interaction);
    }
    notifyListeners();
  }

  bool isFavorite(int? movieId) {
    if (movieId == null || _currentUserId == null) return false;
    return _favoriteMovieIds.contains(movieId);
  }

  Future<void> rateMovie(Movie movie, int rating, String review) async {
    if (_currentUserId == null) return;
    await _dbHelper.insertMovie(movie);
    MovieInteraction? interaction = await getInteraction(movie.id);
    
    if (interaction != null) {
      interaction.rating = rating;
      interaction.review = review.isEmpty ? null : review;
      if (!interaction.isWatched) {
        interaction.isWatched = true;
        interaction.watchedDate = DateTime.now();
        interaction.isWantToWatch = false;
      }
      await _dbHelper.updateMovieInteraction(interaction);
    } else {
      interaction = MovieInteraction(
        userId: _currentUserId!,
        movieId: movie.id,
        isWatched: true,
        rating: rating,
        review: review.isEmpty ? null : review,
        watchedDate: DateTime.now(),
      );
      await _dbHelper.saveMovieInteraction(interaction);
    }
    notifyListeners();
  }

  Future<List<MovieInteraction>> getRecentActivity({int limit = 10}) async {
    if (_currentUserId == null) return [];
    return await _dbHelper.getRecentActivity(_currentUserId!, limit: limit);
  }

  Future<int> getCurrentStreak() async {
    if (_currentUserId == null) return 0;
    return await _dbHelper.getCurrentStreak(_currentUserId!);
  }

  Future<int> getMaxStreak() async {
    if (_currentUserId == null) return 0;
    return await _dbHelper.getMaxStreak(_currentUserId!);
  }

  Future<Map<int, MovieInteraction>> getUserMovieInteractions(int userId) async {
    final interactions = await _dbHelper.getMovieInteractionsByInteraction(userId, 'isWatched');
    final favoriteInteractions = await _dbHelper.getMovieInteractionsByInteraction(userId, 'isFavorite');
    final wantToWatchInteractions = await _dbHelper.getMovieInteractionsByInteraction(userId, 'isWantToWatch');
    
    final Map<int, MovieInteraction> interactionMap = {};
    
    for (var interaction in interactions) {
      interactionMap[interaction.movieId] = interaction;
    }
    
    for (var interaction in favoriteInteractions) {
      if (interactionMap.containsKey(interaction.movieId)) {
        interactionMap[interaction.movieId]!.isFavorite = interaction.isFavorite;
      } else {
        interactionMap[interaction.movieId] = interaction;
      }
    }
    
    for (var interaction in wantToWatchInteractions) {
      if (interactionMap.containsKey(interaction.movieId)) {
        interactionMap[interaction.movieId]!.isWantToWatch = interaction.isWantToWatch;
      } else {
        interactionMap[interaction.movieId] = interaction;
      }
    }
    
    return interactionMap;
  }

  Future<Map<int, MovieInteraction>> getCurrentUserInteractions() async {
    if (_currentUserId == null) return {};
    return getUserMovieInteractions(_currentUserId!);
  }

  Future<double> getAverageRating() async {
    if (_currentUserId == null) return 0.0;
    return await _dbHelper.getAverageRating(_currentUserId!);
  }

  Future<void> saveTopFiveMovies(List<Map<String, dynamic>> movies) async {
    if (_currentUserId == null) return;
    await _dbHelper.saveTopFiveMovies(_currentUserId!, movies);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getTopFiveMovies() async {
    if (_currentUserId == null) return [];
    return await _dbHelper.getTopFiveMovies(_currentUserId!);
  }

  Future<void> deleteTopFiveMovie(int movieId) async {
    if (_currentUserId == null) return;
    await _dbHelper.deleteTopFiveMovie(_currentUserId!, movieId);
    notifyListeners();
  }

  Future<void> reorderTopFiveMovies(List<int> newOrder) async {
    if (_currentUserId == null) return;
    await _dbHelper.reorderTopFiveMovies(_currentUserId!, newOrder);
    notifyListeners();
  }
}