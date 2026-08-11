import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/models.dart';

class FinancesProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _weeklyReview = {};
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> get summary => _summary;
  Map<String, dynamic> get weeklyReview => _weeklyReview;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSummaryAndTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final summaryRes = await _apiClient.get('/finances/summary');
      if (summaryRes != null && summaryRes is Map<String, dynamic>) {
        _summary = summaryRes;
      }

      final weeklyRes = await _apiClient.get('/finances/weekly_review');
      if (weeklyRes != null && weeklyRes is Map<String, dynamic>) {
        _weeklyReview = weeklyRes;
      }

      final txRes = await _apiClient.get('/finances/transactions');
      if (txRes != null && txRes is List) {
        _transactions = txRes.map((json) => Transaction.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = 'Failed to load financial data';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTransaction(String title, double amount, String category, String type) async {
    try {
      final response = await _apiClient.post('/finances/transactions', body: {
        'title': title,
        'amount': amount,
        'category': category,
        'type': type,
        'date': DateTime.now().toIso8601String().split('T').first,
      });

      if (response != null) {
        await fetchSummaryAndTransactions();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to record transaction';
    }
    return false;
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      final response = await _apiClient.delete('/finances/transactions/$transactionId');
      if (response != null) {
        await fetchSummaryAndTransactions();
      }
    } catch (e) {
      _errorMessage = 'Failed to delete transaction';
    }
  }
}
