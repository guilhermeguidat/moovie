// lib/models/user.dart

class User {
  final int? id;
  final String name;
  final String? username;
  final String email;
  final String password;
  final String memberSince;
  final int totalMovies;
  final int totalSeries;
  final int totalTime;
  final double averageRating;

  User({
    this.id,
    this.name = 'Usuário',
    this.username,
    required this.email,
    required this.password,
    this.memberSince = 'Data de Cadastro',
    this.totalMovies = 0,
    this.totalSeries = 0,
    this.totalTime = 0,
    this.averageRating = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'password': password,
      'memberSince': memberSince,
      'totalMovies': totalMovies,
      'totalSeries': totalSeries,
      'totalTime': totalTime,
      'averageRating': averageRating,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'] ?? 'Usuário',
      username: map['username'],
      email: map['email'],
      password: map['password'],
      memberSince: map['memberSince'] ?? 'Data de Cadastro',
      totalMovies: map['totalMovies'] ?? 0,
      totalSeries: map['totalSeries'] ?? 0,
      totalTime: map['totalTime'] ?? 0,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

extension UserCopyWith on User {
  User copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    String? password,
    String? memberSince,
    int? totalMovies,
    int? totalSeries,
    int? totalTime,
    double? averageRating,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      memberSince: memberSince ?? this.memberSince,
      totalMovies: totalMovies ?? this.totalMovies,
      totalSeries: totalSeries ?? this.totalSeries,
      totalTime: totalTime ?? this.totalTime,
      averageRating: averageRating ?? this.averageRating,
    );
  }
}