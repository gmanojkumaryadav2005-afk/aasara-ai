import 'package:flutter/foundation.dart';
import '../core/api_client.dart';

class InsightsProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();
  Map<String, dynamic> _data = {
    'has_sufficient_data': false,
    'message': 'Not enough data yet. Add a few transactions to see personalized insights.',
    'insights': []
  };
  bool _isLoading = false;

  Map<String, dynamic> get data => _data;
  bool get isLoading => _isLoading;

  Future<void> fetchInsights() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.get('/insights/');
      if (res != null && res is Map<String, dynamic>) {
        _data = res;
      }
    } catch (e) {
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }
}
