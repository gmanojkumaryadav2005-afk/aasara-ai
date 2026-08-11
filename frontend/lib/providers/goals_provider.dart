import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/models.dart';

class GoalsProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<Goal> _goals = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalTargetAmount => _goals.fold(0.0, (sum, item) => sum + item.targetAmount);
  double get totalCurrentSavings => _goals.fold(0.0, (sum, item) => sum + item.currentSavings);
  double get overallProgressPercentage {
    if (totalTargetAmount <= 0) return 0.0;
    return (totalCurrentSavings / totalTargetAmount * 100.0).clamp(0.0, 100.0);
  }

  Future<void> fetchGoals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/goals/');
      if (response != null && response is List) {
        _goals = response.map((json) => Goal.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = 'Failed to load financial goals.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addGoal(String title, String category, double targetAmount, double currentSavings, double monthlyContribution, String targetDate) async {
    try {
      final response = await _apiClient.post('/goals/', body: {
        'title': title,
        'category': category,
        'target_amount': targetAmount,
        'current_savings': currentSavings,
        'monthly_contribution': monthlyContribution,
        'target_date': targetDate,
      });

      if (response != null) {
        await fetchGoals();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to add goal.';
    }
    return false;
  }

  Future<bool> updateGoalSavings(Goal goal, double newSavings) async {
    try {
      final response = await _apiClient.put('/goals/${goal.id}', body: {
        'current_savings': newSavings,
      });
      if (response != null) {
        await fetchGoals();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to update goal savings.';
    }
    return false;
  }

  Future<bool> deleteGoal(String goalId) async {
    try {
      final response = await _apiClient.delete('/goals/$goalId');
      if (response != null) {
        _goals.removeWhere((g) => g.id == goalId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete goal.';
    }
    return false;
  }
}
