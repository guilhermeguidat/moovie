import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:moovie/models/movie.dart';

class PagedMoviesResult {
  final List<Movie> movies;
  final int page;
  final int totalPages;
  final int totalResults;
  PagedMoviesResult({
    required this.movies,
    required this.page,
    required this.totalPages,
    required this.totalResults,
  });
}

class TmdbService {
  final String? _apiKey = dotenv.env['TMDB_API_KEY'];
  final String _baseUrl = 'https://api.themoviedb.org/3';
  final String _imageUrl = 'https://image.tmdb.org/t/p/w500';

  String getImageUrl(String posterPath) {
    return '$_imageUrl$posterPath';
  }

  Future<List<Movie>> getPopularMovies() async {
    final String? apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDB_API_KEY não definido. Crie um arquivo .env com TMDB_API_KEY=...');
    }
    final response = await http.get(Uri.parse('$_baseUrl/movie/popular?api_key=$apiKey&language=pt-BR'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'];

      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar filmes populares');
    }
  }

  Future<List<Movie>> searchMovies(String query) async {
    final String? apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDB_API_KEY não definido. Crie um arquivo .env com TMDB_API_KEY=...');
    }
    final response = await http.get(Uri.parse('$_baseUrl/search/movie?api_key=$apiKey&query=$query&language=pt-BR'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'];

      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao buscar filmes');
    }
  }

  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final String? apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDB_API_KEY não definido. Crie um arquivo .env com TMDB_API_KEY=...');
    }
    final response = await http.get(Uri.parse('$_baseUrl/movie/$movieId?api_key=$apiKey&language=pt-BR'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao carregar detalhes do filme');
    }
  }

  Future<int?> getMovieRuntime(int movieId) async {
    final details = await getMovieDetails(movieId);
    final runtime = details['runtime'];
    if (runtime is int) return runtime;
    if (runtime is num) return runtime.toInt();
    return null;
  }

  Future<Map<String, dynamic>> getMovieCredits(int movieId) async {
    final String? apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDB_API_KEY não definido. Crie um arquivo .env com TMDB_API_KEY=...');
    }
    final response = await http.get(Uri.parse('$_baseUrl/movie/$movieId/credits?api_key=$apiKey&language=pt-BR'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao carregar créditos do filme');
    }
  }

  Future<List<Movie>> getTopRatedMovies() async {
    final String? apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDB_API_KEY não definido. Crie um arquivo .env com TMDB_API_KEY=...');
    }
    final response = await http.get(Uri.parse('$_baseUrl/movie/top_rated?api_key=$apiKey&language=pt-BR'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar melhor avaliados');
    }
  }

  Future<List<Movie>> getNowPlayingMovies() async {
    final String? apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDB_API_KEY não definido. Crie um arquivo .env com TMDB_API_KEY=...');
    }
    final response = await http.get(Uri.parse('$_baseUrl/movie/now_playing?api_key=$apiKey&language=pt-BR'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar em cartaz');
    }
  }

  Future<List<Movie>> discoverMovies({int? genreId, int? year}) async {
    final String? apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDB_API_KEY não definido. Crie um arquivo .env com TMDB_API_KEY=...');
    }
    final params = <String, String>{
      'api_key': apiKey,
      'language': 'pt-BR',
      'sort_by': 'popularity.desc',
    };
    if (genreId != null) params['with_genres'] = '$genreId';
    if (year != null) params['primary_release_year'] = '$year';
    final uri = Uri.parse('$_baseUrl/discover/movie').replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar resultados');
    }
  }

  Future<PagedMoviesResult> discoverMoviesPaged({int? genreId, int? year, int page = 1}) async {
    final String? apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDB_API_KEY não definido. Crie um arquivo .env com TMDB_API_KEY=...');
    }
    final params = <String, String>{
      'api_key': apiKey,
      'language': 'pt-BR',
      'sort_by': 'popularity.desc',
      'page': page.toString(),
    };
    if (genreId != null) params['with_genres'] = '$genreId';
    if (year != null) params['primary_release_year'] = '$year';
    final uri = Uri.parse('$_baseUrl/discover/movie').replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      return PagedMoviesResult(
        movies: results.map((json) => Movie.fromJson(json)).toList(),
        page: (data['page'] as num?)?.toInt() ?? page,
        totalPages: (data['total_pages'] as num?)?.toInt() ?? 1,
        totalResults: (data['total_results'] as num?)?.toInt() ?? results.length,
      );
    } else {
      throw Exception('Falha ao carregar resultados');
    }
  }

  Future<PagedMoviesResult> searchMoviesPaged(String query, {int page = 1}) async {
    final String? apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDB_API_KEY não definido. Crie um arquivo .env com TMDB_API_KEY=...');
    }
    final uri = Uri.parse('$_baseUrl/search/movie').replace(queryParameters: {
      'api_key': apiKey,
      'query': query,
      'language': 'pt-BR',
      'page': page.toString(),
    });
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      return PagedMoviesResult(
        movies: results.map((json) => Movie.fromJson(json)).toList(),
        page: (data['page'] as num?)?.toInt() ?? page,
        totalPages: (data['total_pages'] as num?)?.toInt() ?? 1,
        totalResults: (data['total_results'] as num?)?.toInt() ?? results.length,
      );
    } else {
      throw Exception('Falha ao buscar filmes');
    }
  }
}