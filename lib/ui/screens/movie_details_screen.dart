// lib/ui/screens/movie_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moovie/models/movie.dart';
import 'package:moovie/models/movie_interaction.dart';
import 'package:moovie/providers/movie_provider.dart';
import 'package:moovie/services/tmdb_service.dart';
import 'package:moovie/ui/widgets/rating_dialog.dart';
import 'package:provider/provider.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final TmdbService _tmdb = TmdbService();
  late Future<Map<String, dynamic>> _detailsFuture;
  bool _isWatched = false;
  bool _isWantToWatch = false;
  MovieInteraction? _currentInteraction;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadAll();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshInteraction());
  }

  Future<Map<String, dynamic>> _loadAll() async {
    final details = await _tmdb.getMovieDetails(widget.movie.id);
    final credits = await _tmdb.getMovieCredits(widget.movie.id);
    return {
      'details': details,
      'credits': credits,
    };
  }

  Future<void> _refreshInteraction() async {
    final provider = Provider.of<MovieProvider>(context, listen: false);
    final interaction = await provider.getInteraction(widget.movie.id);
    if (!mounted) return;
    setState(() {
      _currentInteraction = interaction;
      _isWatched = interaction?.isWatched ?? false;
      _isWantToWatch = interaction?.isWantToWatch ?? false;
    });
  }

  String _formatRuntime(int? minutes) {
    if (minutes == null || minutes <= 0) return '—';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}min';
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final d = DateTime.parse(iso);
      return DateFormat('d de MMMM de yyyy', 'pt_BR').format(d);
    } catch (_) {
      return iso;
    }
  }

  Future<void> _showRatingDialog() async {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        movieTitle: widget.movie.title,
        initialRating: _currentInteraction?.rating,
        initialReview: _currentInteraction?.review,
        onSubmit: (rating, review) async {
          await context.read<MovieProvider>().rateMovie(widget.movie, rating, review);
          await _refreshInteraction();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movieProvider = context.watch<MovieProvider>();
    final isFav = movieProvider.isFavorite(widget.movie.id);

    return Scaffold(
      backgroundColor: const Color(0xFF191221),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6B45A1)));
          }
          final details = snapshot.data!['details'] as Map<String, dynamic>;
          final credits = snapshot.data!['credits'] as Map<String, dynamic>;

          final backdrop = (details['backdrop_path'] ?? widget.movie.posterPath) as String?;
          final rating = (widget.movie.voteAverage).toStringAsFixed(1);
          final year = (widget.movie.releaseDate.isNotEmpty && widget.movie.releaseDate.length >= 4)
              ? widget.movie.releaseDate.substring(0, 4)
              : '—';
          final runtime = _formatRuntime((details['runtime'] as num?)?.toInt());
          final genres = (details['genres'] as List<dynamic>? ?? []).map((g) => g['name'] as String).toList();
          final companies = (details['production_companies'] as List<dynamic>? ?? [])
              .map((c) => c['name'] as String)
              .toList();
          final director = ((credits['crew'] as List<dynamic>? ?? [])
                  .firstWhere((c) => (c['job'] == 'Director' || c['known_for_department'] == 'Directing'),
                      orElse: () => null) as Map<String, dynamic>?)
              ?['name'];
          final cast = (credits['cast'] as List<dynamic>? ?? [])
              .take(6)
              .map((c) => c['name'] as String)
              .toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 300,
                backgroundColor: const Color(0xFF191221),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (backdrop != null && backdrop.isNotEmpty)
                        Image.network(
                          _tmdb.getImageUrl(backdrop),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: const Color(0xFF221A2A)),
                        )
                      else
                        Container(color: const Color(0xFF221A2A)),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xFF191221)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.movie.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                                const SizedBox(width: 4),
                                Text(rating, style: const TextStyle(color: Colors.white)),
                                const SizedBox(width: 10),
                                Text(year, style: const TextStyle(color: Colors.white70)),
                                const SizedBox(width: 10),
                                Text(runtime, style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!_isWatched) {
                              // Se não tem review, mostra o diálogo
                              if (_currentInteraction?.review == null || _currentInteraction!.review!.isEmpty) {
                                await _showRatingDialog();
                              } else {
                                // Se já tem review, apenas marca como assistido
                                await context.read<MovieProvider>().toggleWatched(widget.movie);
                                await _refreshInteraction();
                              }
                            } else {
                              await context.read<MovieProvider>().toggleWatched(widget.movie);
                              await _refreshInteraction();
                            }
                          },
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: Text(_isWatched ? 'Assistido' : 'Marcar como assistido'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isWatched ? Colors.green[700] : const Color(0xFF6B45A1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _circleIconButton(
                        icon: isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.white,
                        onTap: () async {
                          await context.read<MovieProvider>().toggleFavorite(widget.movie);
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(width: 8),
                      if (_isWatched && _currentInteraction?.rating != null) ...[
                        _circleIconButton(
                          icon: Icons.star,
                          color: const Color(0xFFFFC107),
                          onTap: () => _showRatingDialog(),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _circleIconButton(
                        icon: Icons.add,
                        color: Colors.white,
                        filled: _isWantToWatch,
                        fillColor: const Color(0xFF6B45A1),
                        onTap: () async {
                          await context.read<MovieProvider>().toggleWantToWatch(widget.movie);
                          await _refreshInteraction();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mostrar avaliação do usuário se existir
                      if (_currentInteraction?.rating != null)
                        _sectionCard(
                          title: 'Minha Avaliação',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ...List.generate(5, (index) {
                                    return Icon(
                                      index < (_currentInteraction?.rating ?? 0) ? Icons.star : Icons.star_border,
                                      color: const Color(0xFFFFC107),
                                      size: 20,
                                    );
                                  }),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_currentInteraction?.rating}/5',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              if (_currentInteraction?.review?.isNotEmpty == true) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _currentInteraction!.review!,
                                  style: const TextStyle(color: Color(0xFFBFB7C8), height: 1.4),
                                ),
                              ],
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _showRatingDialog,
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Editar avaliação'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF6B45A1),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      _sectionCard(
                        title: 'Sinopse',
                        child: Text(
                          widget.movie.overview,
                          style: const TextStyle(color: Color(0xFFBFB7C8), height: 1.4),
                        ),
                      ),
                      if (genres.isNotEmpty)
                        _sectionCard(
                          title: 'Gêneros',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: genres
                                .map((g) => _chip(g))
                                .toList(),
                          ),
                        ),
                      _sectionCard(
                        title: 'Informações',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow(Icons.calendar_month, 'Lançamento', _formatDate(details['release_date'] as String?)),
                            const SizedBox(height: 12),
                            _infoRow(Icons.schedule, 'Duração', runtime),
                            const SizedBox(height: 12),
                            _infoRow(Icons.person, 'Diretor', director ?? '—'),
                          ],
                        ),
                      ),
                      if (cast.isNotEmpty)
                        _sectionCard(
                          title: 'Elenco Principal',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: cast.map((n) => _chip(n)).toList(),
                          ),
                        ),
                      if (companies.isNotEmpty)
                        _sectionCard(
                          title: 'Produção',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: companies.map((n) => _chip(n)).toList(),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2B213A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF221A2A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6B45A1)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF8C8696))),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _circleIconButton({required IconData icon, required Color color, required VoidCallback onTap, bool filled = false, Color? fillColor}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: filled ? (fillColor ?? const Color(0xFF2B213A)) : const Color(0xFF2B213A),
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: const Color(0xFF3A2E49)),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}