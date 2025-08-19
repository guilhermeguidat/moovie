import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moovie/providers/movie_provider.dart';
import 'package:moovie/providers/user_provider.dart';
import 'package:moovie/services/tmdb_service.dart';
import 'package:moovie/models/movie.dart';
import 'package:moovie/models/movie_interaction.dart';
import 'package:moovie/database/database_helper.dart';
import 'package:moovie/ui/widgets/achievement_card.dart';
import 'package:moovie/ui/widgets/activity_item.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getFormattedDate(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        if (user == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF191221),
            appBar: AppBar(
              title: const Text('Meu Perfil'),
              backgroundColor: const Color(0xFF191221),
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text(
                'Nenhum usuário logado.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF191221),
          appBar: AppBar(
            title: const Text('Meu Perfil'),
            backgroundColor: const Color(0xFF191221),
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.person), text: 'Perfil'),
                Tab(icon: Icon(Icons.local_fire_department), text: 'Sequência'),
                Tab(icon: Icon(Icons.emoji_events), text: 'Conquistas'),
                Tab(icon: Icon(Icons.history), text: 'Atividade'),
              ],
              labelColor: const Color(0xFF6B45A1),
              unselectedLabelColor: Colors.white70,
              indicatorColor: const Color(0xFF6B45A1),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(user),
              _buildStreakTab(user),
              _buildAchievementsTab(user),
              _buildActivityTab(user),
            ],
          ),
        );
      },
    );
  }

  // Aba do Perfil
  Widget _buildProfileTab(dynamic user) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildProfileHeader(user.name),
            const SizedBox(height: 30),
            _buildInfoCard(user.email, user.memberSince),
            const SizedBox(height: 30),
                              FutureBuilder<List<Movie>>(
                    future: user.id != null ? context.read<MovieProvider>().getUserMovies(user.id!, 'isWatched') : Future.value(<Movie>[]),
                    builder: (context, moviesSnapshot) {
                      if (moviesSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(color: Color(0xFF6B45A1)),
                          ),
                        );
                      }
                      
                      return FutureBuilder<double>(
                        future: context.read<MovieProvider>().getAverageRating(),
                        builder: (context, ratingSnapshot) {
                          final movies = moviesSnapshot.data ?? [];
                          final int watchedCount = movies.length;
                          final int totalMinutes = movies.fold<int>(0, (sum, m) => sum + (m.runtime ?? 120));
                          final double averageRating = ratingSnapshot.data ?? 0.0;
                          
                          return _buildStatsCard(watchedCount, totalMinutes, averageRating);
                        },
                      );
                    },
                  ),
            const SizedBox(height: 30),
            _buildTopFavoritesSection(),
            const SizedBox(height: 20),
            _buildEditProfileSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Color(0xFF6B45A1),
          child: Icon(Icons.person, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Top 5 favoritos do usuário
  Widget _buildTopFavoritesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF221A2A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 5 Favoritos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text('Pesquise e adicione seus filmes favoritos à lista, depois arraste para ordenar.',
              style: TextStyle(color: Color(0xFF8C8696))),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openTopFiveMoviePicker,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar filme ao Top 5'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B45A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _renderTopFiveMovies(),
        ],
      ),
    );
  }

  Future<void> _openTopFiveMoviePicker() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF221A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const _TopFiveMovieSearchSheet(),
    );
    if (mounted) setState(() {});
  }

  Widget _renderTopFiveMovies() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<MovieProvider>().getTopFiveMovies(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('Nenhum filme adicionado ainda.', style: TextStyle(color: Color(0xFF8C8696))),
          );
        }
        return ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) async {
            final list = List<Map<String, dynamic>>.from(items);
            if (newIndex > oldIndex) newIndex -= 1;
            final item = list.removeAt(oldIndex);
            list.insert(newIndex, item);
            await context.read<MovieProvider>().saveTopFiveMovies(list);
            if (mounted) setState(() {});
          },
          children: [
            for (int i = 0; i < items.length; i++)
              Dismissible(
                key: ValueKey(items[i]['movieId']),
                background: Container(color: Colors.red),
                onDismissed: (_) async {
                  await context.read<MovieProvider>().deleteTopFiveMovie(items[i]['movieId']);
                  if (mounted) setState(() {});
                },
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'https://image.tmdb.org/t/p/w92${items[i]['posterPath']}',
                      width: 40,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text('${i + 1}º - ${items[i]['title']}', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(items[i]['year'] ?? '', style: const TextStyle(color: Color(0xFF8C8696))),
                  trailing: const Icon(Icons.drag_handle, color: Colors.white),
                ),
              )
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(String email, String memberSince) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF221A2A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.email, 'Email', email),
          const Divider(color: Color(0xFF382F48), height: 30),
          _buildInfoRow(Icons.cake, 'Membro desde', _getFormattedDate(memberSince)),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int totalMovies, int totalTime, double averageRating) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF221A2A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Minhas Estatísticas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(totalMovies.toString(), 'Filmes'),
              _buildStatItem('${(totalTime / 60).toStringAsFixed(0)}h', 'Tempo'),
              _buildStatItem(
                averageRating > 0 ? averageRating.toStringAsFixed(1) : '-',
                'Nota Média',
                showStars: averageRating > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6B45A1)),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF8C8696), fontSize: 14),
            ),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, {bool showStars = false}) {
    return Column(
      children: [
        showStars && value != '-' ? 
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.star,
                color: Color(0xFFFFC107),
                size: 16,
              ),
            ],
          ) :
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8C8696), fontSize: 14),
        ),
      ],
    );
  }

  // Aba da Sequência
  Widget _buildStreakTab(dynamic user) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            FutureBuilder<int>(
              future: context.read<MovieProvider>().getCurrentStreak(),
              builder: (context, currentStreakSnapshot) {
                return FutureBuilder<int>(
                  future: context.read<MovieProvider>().getMaxStreak(),
                  builder: (context, maxStreakSnapshot) {
                    final currentStreak = currentStreakSnapshot.data ?? 0;
                    final maxStreak = maxStreakSnapshot.data ?? 0;
                    
                    return Column(
                      children: [
                        _buildStreakCard('Sequência Atual', currentStreak, Icons.local_fire_department, 
                            currentStreak > 0 ? Colors.orange : Colors.grey),
                        const SizedBox(height: 20),
                        _buildStreakCard('Maior Sequência', maxStreak, Icons.military_tech, 
                            maxStreak > 0 ? const Color(0xFF6B45A1) : Colors.grey),
                        const SizedBox(height: 30),
                        _buildStreakProgress(currentStreak),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(String title, int streak, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF221A2A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF8C8696),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$streak dias',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakProgress(int currentStreak) {
    final progressSteps = [5, 10, 15, 20, 30];
    int nextMilestone = progressSteps.firstWhere((step) => step > currentStreak, orElse: () => currentStreak + 10);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF221A2A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Próximo Marco',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Faltam ${nextMilestone - currentStreak} dias para $nextMilestone dias consecutivos',
            style: const TextStyle(
              color: Color(0xFF8C8696),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: currentStreak / nextMilestone,
            backgroundColor: const Color(0xFF3A2E49),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B45A1)),
          ),
          const SizedBox(height: 8),
          Text(
            '$currentStreak/$nextMilestone dias',
            style: const TextStyle(
              color: Color(0xFF8C8696),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }



  // Aba de Conquistas
  Widget _buildAchievementsTab(dynamic user) {
    return FutureBuilder<List<Movie>>(
      future: user.id != null ? context.read<MovieProvider>().getUserMovies(user.id!, 'isWatched') : Future.value(<Movie>[]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6B45A1)));
        }
        
        final watchedMovies = snapshot.data ?? [];
        
        return FutureBuilder<int>(
          future: context.read<MovieProvider>().getMaxStreak(),
          builder: (context, streakSnapshot) {
            final maxStreak = streakSnapshot.data ?? 0;
            final achievements = _generateAchievements(watchedMovies.length, maxStreak);
            
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAchievementsSummary(achievements),
                    const SizedBox(height: 20),
                    const Text(
                      'Todas as Conquistas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ...achievements.map((achievement) => AchievementCard(achievement: achievement)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAchievementsSummary(List<Achievement> achievements) {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF221A2A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Text(
            '🏆 Conquistas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            '$unlockedCount/$totalCount',
            style: const TextStyle(
              color: Color(0xFF6B45A1),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conquistas desbloqueadas',
            style: const TextStyle(
              color: Color(0xFF8C8696),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: totalCount > 0 ? unlockedCount / totalCount : 0,
            backgroundColor: const Color(0xFF3A2E49),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B45A1)),
          ),
        ],
      ),
    );
  }

  List<Achievement> _generateAchievements(int watchedCount, int maxStreak) {
    return [
      Achievement(
        id: 'first_movie',
        title: 'Primeiro Filme',
        description: 'Assista ao seu primeiro filme',
        icon: Icons.movie,
        isUnlocked: watchedCount >= 1,
        currentProgress: watchedCount >= 1 ? 1 : watchedCount,
        targetProgress: 1,
      ),
      Achievement(
        id: 'movie_5',
        title: 'Explorando',
        description: 'Assista a 5 filmes',
        icon: Icons.video_library,
        isUnlocked: watchedCount >= 5,
        currentProgress: watchedCount >= 5 ? 5 : watchedCount,
        targetProgress: 5,
      ),
      Achievement(
        id: 'movie_25',
        title: 'Entusiasta',
        description: 'Assista a 25 filmes',
        icon: Icons.theaters,
        isUnlocked: watchedCount >= 25,
        currentProgress: watchedCount >= 25 ? 25 : watchedCount,
        targetProgress: 25,
      ),
      Achievement(
        id: 'movie_50',
        title: 'Dedicado',
        description: 'Assista a 50 filmes',
        icon: Icons.local_movies,
        isUnlocked: watchedCount >= 50,
        currentProgress: watchedCount >= 50 ? 50 : watchedCount,
        targetProgress: 50,
      ),
      Achievement(
        id: 'cinephile',
        title: 'Cinéfilo',
        description: 'Assista a 100+ filmes',
        icon: Icons.movie_filter,
        isUnlocked: watchedCount >= 100,
        currentProgress: watchedCount >= 100 ? 100 : watchedCount,
        targetProgress: 100,
      ),
      Achievement(
        id: 'movie_master',
        title: 'Mestre do Cinema',
        description: 'Assista a 250+ filmes',
        icon: Icons.auto_awesome,
        isUnlocked: watchedCount >= 250,
        currentProgress: watchedCount >= 250 ? 250 : watchedCount,
        targetProgress: 250,
      ),
      Achievement(
        id: 'critic',
        title: 'Crítico',
        description: 'Avalie 30+ títulos',
        icon: Icons.star,
        isUnlocked: watchedCount >= 30,
        currentProgress: watchedCount >= 30 ? 30 : watchedCount,
        targetProgress: 30,
      ),
      Achievement(
        id: 'time_10h',
        title: 'Maratonista Iniciante',
        description: 'Acumule 10+ horas assistindo',
        icon: Icons.schedule,
        isUnlocked: watchedCount >= 5, // ~10 horas
        currentProgress: watchedCount >= 5 ? 5 : watchedCount,
        targetProgress: 5,
      ),
      Achievement(
        id: 'time_50h',
        title: 'Viciado em Cinema',
        description: 'Acumule 50+ horas assistindo',
        icon: Icons.access_time,
        isUnlocked: watchedCount >= 25, // ~50 horas
        currentProgress: watchedCount >= 25 ? 25 : watchedCount,
        targetProgress: 25,
      ),
      Achievement(
        id: 'streak_3',
        title: 'Início de Hábito',
        description: 'Assista filmes por 3 dias consecutivos',
        icon: Icons.flash_on,
        isUnlocked: maxStreak >= 3,
        currentProgress: maxStreak >= 3 ? 3 : maxStreak,
        targetProgress: 3,
      ),
      Achievement(
        id: 'streak_7',
        title: 'Uma Semana Forte',
        description: 'Assista filmes por 7 dias consecutivos',
        icon: Icons.local_fire_department,
        isUnlocked: maxStreak >= 7,
        currentProgress: maxStreak >= 7 ? 7 : maxStreak,
        targetProgress: 7,
      ),
      Achievement(
        id: 'streak_15',
        title: 'Sequência Impressionante',
        description: 'Assista filmes por 15 dias consecutivos',
        icon: Icons.whatshot,
        isUnlocked: maxStreak >= 15,
        currentProgress: maxStreak >= 15 ? 15 : maxStreak,
        targetProgress: 15,
      ),
      Achievement(
        id: 'streak_30',
        title: 'Lenda da Consistência',
        description: 'Assista filmes por 30 dias consecutivos',
        icon: Icons.emoji_events,
        isUnlocked: maxStreak >= 30,
        currentProgress: maxStreak >= 30 ? 30 : maxStreak,
        targetProgress: 30,
      ),
    ];
  }

  // Aba de Atividade Recente
  Widget _buildActivityTab(dynamic user) {
    return FutureBuilder<List<MovieInteraction>>(
      future: context.read<MovieProvider>().getRecentActivity(limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6B45A1)));
        }
        
        final interactions = snapshot.data ?? [];
        
        if (interactions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Color(0xFF8C8696)),
                SizedBox(height: 16),
                Text(
                  'Nenhuma atividade recente',
                  style: TextStyle(
                    color: Color(0xFF8C8696),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Avalie alguns filmes para ver sua atividade aqui!',
                  style: TextStyle(
                    color: Color(0xFF6B5B72),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        // Buscar os filmes correspondentes às interações
        final movieIds = interactions.map((i) => i.movieId).toList();
        
        return FutureBuilder<List<Movie>>(
          future: DatabaseHelper().getMoviesByIds(movieIds),
          builder: (context, movieSnapshot) {
            if (movieSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF6B45A1)));
            }
            
            final movies = movieSnapshot.data ?? [];
            final movieMap = {for (var movie in movies) movie.id: movie};
            
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Atividade Recente',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ...interactions.map((interaction) {
                      final movie = movieMap[interaction.movieId];
                      if (movie == null) return const SizedBox.shrink();
                      return ActivityItem(movie: movie, interaction: interaction);
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Botão de sair removido desta tela
  Widget _buildEditProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF221A2A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Editar Perfil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text('Altere seus dados pessoais',
              style: TextStyle(color: Color(0xFF8C8696))),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showEditProfileDialog,
              icon: const Icon(Icons.edit),
              label: const Text('Editar dados'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B45A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);
    final usernameController = TextEditingController(text: user.username ?? '');
    final emailController = TextEditingController(text: user.email);
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF221A2A),
          title: const Text('Editar Perfil', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    labelStyle: TextStyle(color: Color(0xFF8C8696)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8C8696))),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6B45A1))),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome de usuário',
                    labelStyle: TextStyle(color: Color(0xFF8C8696)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8C8696))),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6B45A1))),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Color(0xFF8C8696)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8C8696))),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6B45A1))),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nova senha',
                    labelStyle: TextStyle(color: Color(0xFF8C8696)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8C8696))),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6B45A1))),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF8C8696))),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                final newUsername = usernameController.text.trim();
                final newEmail = emailController.text.trim();

                if (newName.isEmpty || newUsername.isEmpty || newEmail.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Todos os campos são obrigatórios')),
                  );
                  return;
                }

                // Aqui você implementaria a lógica para atualizar o usuário
                // Por enquanto, apenas fecha o diálogo
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B45A1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}

class _TopFiveMovieSearchSheet extends StatefulWidget {
  const _TopFiveMovieSearchSheet();
  @override
  State<_TopFiveMovieSearchSheet> createState() => _TopFiveMovieSearchSheetState();
}

class _TopFiveMovieSearchSheetState extends State<_TopFiveMovieSearchSheet> {
  final TextEditingController _search = TextEditingController();
  List<Movie> _results = [];
  bool _loading = false;
  final TmdbService _tmdb = TmdbService();

  Future<void> _doSearch(String q) async {
    if (q.isEmpty) return;
    setState(() => _loading = true);
    try {
      final page = await _tmdb.searchMoviesPaged(q, page: 1);
      setState(() => _results = page.movies);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _add(Movie m) async {
    final movieProvider = context.read<MovieProvider>();
    final currentList = await movieProvider.getTopFiveMovies();
    
    // Verifica se já existe
    if (currentList.any((item) => item['movieId'] == m.id)) return;
    
    // Adiciona o novo filme
    final newMovie = {
      'movieId': m.id,
      'title': m.title,
      'posterPath': m.posterPath,
      'year': (m.releaseDate.isNotEmpty && m.releaseDate.length >= 4) ? m.releaseDate.substring(0, 4) : '',
    };
    
    final updatedList = [...currentList, newMovie];
    
    // Mantém apenas os 5 primeiros
    if (updatedList.length > 5) {
      updatedList.removeRange(5, updatedList.length);
    }
    
    await movieProvider.saveTopFiveMovies(updatedList);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _search,
            onSubmitted: _doSearch,
            decoration: const InputDecoration(
              hintText: 'Buscar filme... ',
              hintStyle: TextStyle(color: Color(0xFF8C8696)),
              filled: true,
              fillColor: Color(0xFF191221),
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          if (_loading) const CircularProgressIndicator(color: Color(0xFF6B45A1)) else ...[
            SizedBox(
              height: 360,
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final m = _results[i];
                  return ListTile(
                    onTap: () => _add(m),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        'https://image.tmdb.org/t/p/w92${m.posterPath}',
                        width: 40,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(m.title, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      (m.releaseDate.isNotEmpty && m.releaseDate.length >= 4) ? m.releaseDate.substring(0, 4) : '',
                      style: const TextStyle(color: Color(0xFF8C8696)),
                    ),
                  );
                },
              ),
            ),
          ]
        ],
      ),
    );
  }
}