import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_constants.dart';

import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }

  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<void> _saveSession(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await saveUser(user);
  }

  static Future<User> refreshUser() async {
    final userData = await ApiService.get(ApiConstants.profile);
    final user = User.fromJson(userData);
    await saveUser(user);
    return user;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  static Future<bool> isAdmin() async {
    final user = await getUser();
    return user?.isAdmin ?? false;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final user = User.fromJson(data['user']);
        await _saveSession(data['token'], user);
        return {'success': true, 'user': user};
      }
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error. Check your network.'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String carPlate,
    required String idNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'carPlate': carPlate,
          'idNumber': idNumber,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        final user = User.fromJson(data['user']);
        await _saveSession(data['token'], user);
        return {'success': true, 'user': user};
      }
      return {'success': false, 'message': data['message'] ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error. Check your network.'};
    }
  }
}
