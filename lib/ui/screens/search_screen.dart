import 'package:flutter/material.dart';
import 'package:moovie/models/movie.dart';
import 'package:moovie/services/tmdb_service.dart';
import 'package:moovie/ui/widgets/movie_card.dart';
import 'package:provider/provider.dart';
import 'package:moovie/providers/movie_provider.dart';
import 'package:moovie/models/movie_interaction.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TmdbService _tmdbService = TmdbService();
  final TextEditingController _searchController = TextEditingController();
  List<Movie> _searchResults = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  bool _isFilterMode = false;
  List<Movie> _popular = [];
  List<Movie> _topRated = [];
  List<Movie> _nowPlaying = [];
  int? _selectedGenreId;
  int? _selectedYear;
  bool _isLoading = false;
  String _error = '';
  static const Map<int, String> _genresMap = {
    28: 'Ação',
    12: 'Aventura',
    16: 'Animação',
    35: 'Comédia',
    18: 'Drama',
  };

  @override
  void initState() {
    super.initState();
    _loadInitialLists();
  }

  Widget _buildFilterSummary() {
    final String genreLabel = _selectedGenreId == null
        ? 'Todos os gêneros'
        : (_genresMap[_selectedGenreId!] ?? 'Gênero');
    final String yearLabel = _selectedYear == null ? 'Todos os anos' : _selectedYear.toString();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(genreLabel),
        _chip(yearLabel),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2B213A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  Future<void> _loadInitialLists() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final results = await Future.wait<List<Movie>>([
        _tmdbService.getPopularMovies(),
        _tmdbService.getTopRatedMovies(),
        _tmdbService.getNowPlayingMovies(),
      ]);
      if (!mounted) return;
      setState(() {
        _popular = results[0];
        _topRated = results[1];
        _nowPlaying = results[2];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Falha ao carregar listas iniciais.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _searchMovies(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final page1 = await _tmdbService.searchMoviesPaged(query, page: 1);
      setState(() {
        _searchResults = page1.movies;
        _currentPage = 1;
        _totalPages = page1.totalPages;
        _isFilterMode = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Falha ao buscar filmes. Tente novamente.';
        _searchResults = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreSearch() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    setState(() => _isLoadingMore = true);
    try {
      final next = _isFilterMode
          ? await _tmdbService.discoverMoviesPaged(
              genreId: _selectedGenreId,
              year: _selectedYear,
              page: _currentPage + 1,
            )
          : await _tmdbService.searchMoviesPaged(
              _searchController.text,
              page: _currentPage + 1,
            );
      setState(() {
        _searchResults.addAll(next.movies);
        _currentPage = next.page;
        _totalPages = next.totalPages;
      });
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Buscar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildSearchBar(),
            const SizedBox(height: 12),
            if (_selectedGenreId != null || _selectedYear != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildFilterSummary(),
              ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6B45A1)));
    }
    if (_error.isNotEmpty) {
      return Center(child: Text(_error, style: const TextStyle(color: Colors.red)));
    }
    if (_searchController.text.isEmpty && _searchResults.isEmpty) {
      return _buildInitialLists();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultsHeader(),
        const SizedBox(height: 10),
        Expanded(child: _buildResultsBody()),
      ],
    );
  }

  Widget _buildInitialLists() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Populares', _popular),
          const SizedBox(height: 20),
          _buildSection('Lançamentos', _nowPlaying),
          const SizedBox(height: 20),
          _buildSection('Mais bem avaliados', _topRated),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Movie> movies) {
    if (movies.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Consumer<MovieProvider>(
          builder: (context, provider, _) {
            return SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return SizedBox(
                    width: 150,
                    child: MovieCard(
                      movie: movie,
                      isFavorite: provider.isFavorite(movie.id),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: movies.length.clamp(0, 20),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFF221A2A),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF8C8696)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: _searchMovies,
              decoration: const InputDecoration(
                hintText: 'Buscar filmes e séries...',
                hintStyle: TextStyle(color: Color(0xFF8C8696)),
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF8C8696)),
            onPressed: _openFilters,
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters() async {
    int? tempGenreId = _selectedGenreId;
    int? tempYear = _selectedYear;
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF221A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filtros', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildDropdown<String>(
                    label: 'Gênero',
                    value: tempGenreId?.toString() ?? 'all',
                    items: const {
                      'all': 'Todos os gêneros',
                      '28': 'Ação',
                      '12': 'Aventura',
                      '16': 'Animação',
                      '35': 'Comédia',
                      '18': 'Drama',
                    },
                    onChanged: (val) {
                      setModalState(() {
                        tempGenreId = (val == 'all') ? null : int.tryParse(val!);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown<String>(
                    label: 'Ano',
                    value: tempYear?.toString() ?? 'all',
                    items: {
                      'all': 'Todos os anos',
                      for (int y = DateTime.now().year; y >= 1980; y--) '$y': '$y'
                    },
                    onChanged: (val) {
                      setModalState(() {
                        tempYear = (val == 'all') ? null : int.tryParse(val!);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Persiste no estado da tela e aplica
                        setState(() {
                          _selectedGenreId = tempGenreId;
                          _selectedYear = tempYear;
                        });
                        Navigator.of(context).pop();
                        await _applyDiscoveryFilters();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B45A1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Aplicar filtros'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8C8696))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF383040),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items.entries
                  .map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value, style: const TextStyle(color: Colors.white))))
                  .toList(),
              onChanged: onChanged,
              dropdownColor: const Color(0xFF221A2A),
              iconEnabledColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _applyDiscoveryFilters() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final page1 = await _tmdbService.discoverMoviesPaged(
          genreId: _selectedGenreId, year: _selectedYear, page: 1);
      if (!mounted) return;
      setState(() {
        _searchResults = page1.movies;
        _currentPage = 1;
        _totalPages = page1.totalPages;
        _isFilterMode = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Falha ao aplicar filtros.';
        _searchResults = [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildResultsHeader() {
    if (_isLoading || _error.isNotEmpty || _searchResults.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultados da busca',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${_searchResults.length} resultados encontrados',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF8C8696),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildResultsBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6B45A1)));
    }
    if (_error.isNotEmpty) {
      return Center(child: Text(_error, style: const TextStyle(color: Colors.red)));
    }
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(child: Text('Nenhum filme encontrado.', style: TextStyle(color: Colors.grey)));
    }
    if (_searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollUpdateNotification) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300 && !_isLoadingMore) {
            _loadMoreSearch();
          }
        }
        return false;
      },
      child: Center(
        child: Consumer<MovieProvider>(
          builder: (context, provider, _) {
            return GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.6,
          ),
          itemCount: _searchResults.length + (_isLoadingMore ? 2 : 0),
          itemBuilder: (context, index) {
            if (index >= _searchResults.length) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF6B45A1)));
            }
                final movie = _searchResults[index];
                return FutureBuilder<Map<int, MovieInteraction>>(
                  future: provider.getCurrentUserInteractions(),
                  builder: (context, interactionSnapshot) {
                    final interaction = interactionSnapshot.data?[movie.id];
                    return MovieCard(
                      movie: movie,
                      isFavorite: provider.isFavorite(movie.id),
                      interaction: interaction,
                    );
                  },
                );
          },
            );
          },
        ),
      ),
    );
  }
}