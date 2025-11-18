import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:moovie/models/user.dart';
import 'package:moovie/models/movie.dart';
import 'package:moovie/models/movie_interaction.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'moovie.db');
    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        username TEXT UNIQUE,
        email TEXT UNIQUE,
        password TEXT,
        memberSince TEXT,
        totalMovies INTEGER DEFAULT 0,
        totalSeries INTEGER DEFAULT 0,
        totalTime INTEGER DEFAULT 0,
        averageRating REAL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE movies(
        id INTEGER PRIMARY KEY,
        title TEXT,
        overview TEXT,
        posterPath TEXT,
        voteAverage REAL,
        releaseDate TEXT,
        runtime INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE movie_interactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        movieId INTEGER,
        isWatched INTEGER DEFAULT 0,
        isFavorite INTEGER DEFAULT 0,
        isWantToWatch INTEGER DEFAULT 0,
        rating INTEGER,
        review TEXT,
        watchedDate TEXT,
        FOREIGN KEY (userId) REFERENCES users(id),
        FOREIGN KEY (movieId) REFERENCES movies(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE top_five_movies(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        position INTEGER,
        movieId INTEGER,
        title TEXT,
        posterPath TEXT,
        year TEXT,
        FOREIGN KEY (userId) REFERENCES users(id),
        FOREIGN KEY (movieId) REFERENCES movies(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE movies ADD COLUMN runtime INTEGER');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE movie_interactions ADD COLUMN rating INTEGER');
      await db.execute('ALTER TABLE movie_interactions ADD COLUMN review TEXT');
      await db.execute('ALTER TABLE movie_interactions ADD COLUMN watchedDate TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE movie_interactions ADD COLUMN rating INTEGER');
      await db.execute('ALTER TABLE movie_interactions ADD COLUMN review TEXT');
      await db.execute('ALTER TABLE movie_interactions ADD COLUMN watchedDate TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE users ADD COLUMN username TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE top_five_movies(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER,
          position INTEGER,
          movieId INTEGER,
          title TEXT,
          posterPath TEXT,
          year TEXT,
          FOREIGN KEY (userId) REFERENCES users(id),
          FOREIGN KEY (movieId) REFERENCES movies(id)
        )
      ''');
    }
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteUserAndData(int userId) async {
    final db = await database;
    await db.delete('movie_interactions', where: 'userId = ?', whereArgs: [userId]);
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> insertMovie(Movie movie) async {
    final db = await database;
    await db.insert('movies', movie.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Movie>> getMoviesByIds(List<int> movieIds) async {
    if (movieIds.isEmpty) return [];
    final db = await database;
    final String idsString = movieIds.join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      'movies',
      where: 'id IN ($idsString)',
    );
    return List.generate(maps.length, (i) => Movie.fromMap(maps[i]));
  }

  Future<void> saveMovieInteraction(MovieInteraction interaction) async {
    final db = await database;
    await db.insert('movie_interactions', interaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateMovieInteraction(MovieInteraction interaction) async {
    final db = await database;
    await db.update(
      'movie_interactions',
      interaction.toMap(),
      where: 'userId = ? AND movieId = ?',
      whereArgs: [interaction.userId, interaction.movieId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<MovieInteraction?> getMovieInteraction(int userId, int movieId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movie_interactions',
      where: 'userId = ? AND movieId = ?',
      whereArgs: [userId, movieId],
    );
    if (maps.isNotEmpty) {
      return MovieInteraction.fromMap(maps.first);
    }
    return null;
  }

  Future<List<MovieInteraction>> getMovieInteractionsByInteraction(int userId, String interactionType) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movie_interactions',
      where: 'userId = ? AND $interactionType = ?',
      whereArgs: [userId, 1],
    );
    return List.generate(maps.length, (i) => MovieInteraction.fromMap(maps[i]));
  }

  Future<void> removeMovieInteraction(int userId, int movieId, String interactionType) async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE movie_interactions SET $interactionType = 0 WHERE userId = ? AND movieId = ?',
        [userId, movieId]
    );
  }

  Future<List<MovieInteraction>> getRecentActivity(int userId, {int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movie_interactions',
      where: 'userId = ? AND isWatched = 1 AND rating IS NOT NULL',
      whereArgs: [userId],
      orderBy: 'watchedDate DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => MovieInteraction.fromMap(maps[i]));
  }

  Future<int> getCurrentStreak(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movie_interactions',
      where: 'userId = ? AND isWatched = 1 AND watchedDate IS NOT NULL',
      whereArgs: [userId],
      orderBy: 'watchedDate DESC',
    );

    if (maps.isEmpty) return 0;

    int streak = 0;
    DateTime? lastDate;
    Set<String> watchedDates = {};

    for (var map in maps) {
      final watchedDate = DateTime.parse(map['watchedDate']);
      final dateOnly = DateTime(watchedDate.year, watchedDate.month, watchedDate.day);
      final dateString = dateOnly.toIso8601String().split('T')[0];
      
      if (!watchedDates.contains(dateString)) {
        watchedDates.add(dateString);
        
        if (lastDate == null) {
          lastDate = dateOnly;
          streak = 1;
        } else {
          final daysDiff = lastDate.difference(dateOnly).inDays;
          if (daysDiff == 1) {
            streak++;
            lastDate = dateOnly;
          } else {
            break;
          }
        }
      }
    }

    if (lastDate != null) {
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final daysSinceLastWatch = todayOnly.difference(lastDate).inDays;
      
      if (daysSinceLastWatch > 1) {
        return 0;
      }
    }

    return streak;
  }

  Future<int> getMaxStreak(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movie_interactions',
      where: 'userId = ? AND isWatched = 1 AND watchedDate IS NOT NULL',
      whereArgs: [userId],
      orderBy: 'watchedDate ASC',
    );

    if (maps.isEmpty) return 0;

    int maxStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;
    Set<String> watchedDates = {};

    for (var map in maps) {
      final watchedDate = DateTime.parse(map['watchedDate']);
      final dateOnly = DateTime(watchedDate.year, watchedDate.month, watchedDate.day);
      final dateString = dateOnly.toIso8601String().split('T')[0];
      
      if (!watchedDates.contains(dateString)) {
        watchedDates.add(dateString);
        
        if (lastDate == null) {
          lastDate = dateOnly;
          currentStreak = 1;
        } else {
          final daysDiff = dateOnly.difference(lastDate).inDays;
          if (daysDiff == 1) {
            currentStreak++;
            lastDate = dateOnly;
          } else {
            maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
            currentStreak = 1;
            lastDate = dateOnly;
          }
        }
      }
    }

    return maxStreak > currentStreak ? maxStreak : currentStreak;
  }

  Future<double> getAverageRating(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movie_interactions',
      where: 'userId = ? AND rating IS NOT NULL',
      whereArgs: [userId],
    );
    if (maps.isEmpty) return 0.0;
    final ratings = maps.map((map) => map['rating'] as int).toList();
    final sum = ratings.fold<int>(0, (a, b) => a + b);
    return sum / ratings.length;
  }

  Future<void> saveTopFiveMovies(int userId, List<Map<String, dynamic>> movies) async {
    final db = await database;
    await db.delete('top_five_movies', where: 'userId = ?', whereArgs: [userId]);
    
    for (int i = 0; i < movies.length; i++) {
      await db.insert('top_five_movies', {
        'userId': userId,
        'position': i + 1,
        'movieId': movies[i]['movieId'],
        'title': movies[i]['title'],
        'posterPath': movies[i]['posterPath'],
        'year': movies[i]['year'],
      });
    }
  }

  Future<List<Map<String, dynamic>>> getTopFiveMovies(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'top_five_movies',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'position ASC',
    );
    return maps;
  }

  Future<void> deleteTopFiveMovie(int userId, int movieId) async {
    final db = await database;
    await db.delete('top_five_movies', where: 'userId = ? AND movieId = ?', whereArgs: [userId, movieId]);
  }

  Future<void> reorderTopFiveMovies(int userId, List<int> newOrder) async {
    final db = await database;
    await db.delete('top_five_movies', where: 'userId = ?', whereArgs: [userId]);
    
    for (int i = 0; i < newOrder.length; i++) {
      final movie = await db.query('top_five_movies', where: 'movieId = ?', whereArgs: [newOrder[i]]);
      if (movie.isNotEmpty) {
        await db.insert('top_five_movies', {
          'userId': userId,
          'position': i + 1,
          'movieId': movie[0]['movieId'],
          'title': movie[0]['title'],
          'posterPath': movie[0]['posterPath'],
          'year': movie[0]['year'],
        });
      }
    }
  }
}