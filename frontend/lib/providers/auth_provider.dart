import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/models.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token != null) {
      await fetchCurrentUser();
    }
  }

  Future<void> fetchCurrentUser() async {
    try {
      final response = await _api.get('/auth/me');
      if (response != null) {
        _user = User.fromJson(response);
      }
    } catch (e) {
      _token = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.postForm('/auth/login', {'username': email, 'password': password});
      _token = response['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _token!);
      
      await fetchCurrentUser();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({double? monthlyBudget, double? monthlyIncome, String? fullName}) async {
    try {
      final body = <String, dynamic>{};
      if (monthlyBudget != null) body['monthly_budget'] = monthlyBudget;
      if (monthlyIncome != null) body['monthly_income'] = monthlyIncome;
      if (fullName != null) body['full_name'] = fullName;
      
      final response = await _api.put('/auth/me', body: body);
      if (response != null) {
        _user = User.fromJson(response);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _errorMessage = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    notifyListeners();
  }
}
