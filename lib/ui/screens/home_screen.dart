import 'package:flutter/material.dart';
import 'package:moovie/models/movie.dart';
import 'package:moovie/providers/movie_provider.dart';
import 'package:moovie/providers/user_provider.dart';
import 'package:moovie/ui/widgets/movie_card.dart';
import 'package:moovie/ui/widgets/custom_app_bar.dart';
import 'package:moovie/ui/widgets/custom_bottom_navigation_bar.dart';
import 'package:moovie/ui/widgets/tab_section.dart';
import 'package:provider/provider.dart';

import 'package:moovie/ui/screens/search_screen.dart';
import 'package:moovie/ui/screens/profile_screen.dart';
import 'package:moovie/ui/screens/config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  int _bottomNavIndex = 0;

  final List<String> _tabs = ['Quero ver', 'Concluídos', 'Favoritos'];
  final List<String> _tabKeys = ['isWantToWatch', 'isWatched', 'isFavorite'];

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        return Scaffold(
          backgroundColor: const Color(0xFF191221),
          appBar: const CustomAppBar(),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                TabSection(
                  selectedIndex: _tabIndex,
                  onTap: (index) {
                    setState(() {
                      _tabIndex = index;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildMovieList(user?.id, _tabKeys[_tabIndex]),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomBottomNavigationBar(
            selectedIndex: _bottomNavIndex,
            onTap: (index) {
              setState(() {
                _bottomNavIndex = index;
              });
              _navigateToScreen(index);
            },
          ),
        );
      },
    );
  }

  void _navigateToScreen(int index) {
    if (index == 1) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SearchScreen()))
          .then((_) => setState(() => _bottomNavIndex = 0));
    } else if (index == 2) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ProfileScreen()))
          .then((_) => setState(() => _bottomNavIndex = 0));
    } else if (index == 3) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ConfigScreen()))
          .then((_) => setState(() => _bottomNavIndex = 0));
    }
  }

  Widget _buildMovieList(int? userId, String interactionType) {
    if (userId == null) {
      return const Center(
        child: Text(
          'Faça login para ver sua lista.', 
          style: TextStyle(color: Colors.grey)
        )
      );
    }
    
    return Consumer<MovieProvider>(
      builder: (context, movieProvider, child) {
        return FutureBuilder<List<Movie>>(
          future: movieProvider.getUserMovies(userId, interactionType),
          builder: (context, moviesSnapshot) {
            if (moviesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF6B45A1))
              );
            }
            
            if (moviesSnapshot.hasError) {
              return Center(
                child: Text(
                  'Erro: ${moviesSnapshot.error}', 
                  style: const TextStyle(color: Colors.red)
                ),
              );
            }
            
            if (!moviesSnapshot.hasData || moviesSnapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'Nenhum filme na sua lista.', 
                  style: const TextStyle(color: Colors.grey)
                ),
              );
            }

            return FutureBuilder<Map<int, dynamic>>(
              future: movieProvider.getUserMovieInteractions(userId),
              builder: (context, interactionsSnapshot) {
                final movies = moviesSnapshot.data!;
                final interactions = interactionsSnapshot.data ?? {};
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_tabs[_tabIndex]} (${movies.length} itens)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.6,
                          ),
                          itemCount: movies.length,
                          itemBuilder: (context, index) {
                            final movie = movies[index];
                            return MovieCard(
                              movie: movie, 
                              isFavorite: movieProvider.isFavorite(movie.id),
                              interaction: interactions[movie.id],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}