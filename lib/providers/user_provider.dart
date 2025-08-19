import 'package:flutter/material.dart';
import 'package:moovie/database/database_helper.dart';
import 'package:moovie/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  User? _user;
  bool _isLoading = false;

  UserProvider(this._dbHelper);

  User? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('loggedInUserEmail');

    if (email != null) {
      _user = await _dbHelper.getUserByEmail(email);
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> login(String identifier, String password, {bool rememberMe = false}) async {
    User? fetchedUser = await _dbHelper.getUserByEmail(identifier);
    fetchedUser ??= await _dbHelper.getUserByUsername(identifier);
    
    if (fetchedUser == null || fetchedUser.password != password) {
      return 'Email ou senha incorretos.';
    }

    _user = fetchedUser;
    
    if (rememberMe) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('loggedInUserEmail', fetchedUser.email);
    }
    
    notifyListeners();
    return null;
  }

  Future<String?> register(String name, String email, String password, {String? username}) async {
    final User? existingUser = await _dbHelper.getUserByEmail(email);
    if (existingUser != null) {
      return 'Este email já está em uso.';
    }

    final User newUser = User(
      name: name,
      username: username,
      email: email,
      password: password,
      memberSince: DateTime.now().toIso8601String(),
    );
    
    await _dbHelper.insertUser(newUser);
    return null;
  }

  Future<void> logout() async {
    _user = null;
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUserEmail');
    
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (_user == null) return;
    
    await _dbHelper.deleteUserAndData(_user!.id!);
    await logout();
  }
}