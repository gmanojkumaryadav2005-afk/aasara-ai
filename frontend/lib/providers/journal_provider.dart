import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/models.dart';

class JournalProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<JournalEntry> _entries = [];
  bool _isLoading = false;

  List<JournalEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  Future<void> fetchEntries() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.get('/journal/');
      if (res != null && res is List) {
        _entries = res.map((e) => JournalEntry.fromJson(e)).toList();
      }
    } catch (e) {
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addEntry(String title, String content, String mood) async {
    try {
      final body = {'title': title, 'content': content, 'mood': mood};
      final res = await _api.post('/journal/', body: body);
      if (res != null) {
        _entries.insert(0, JournalEntry.fromJson(res));
        notifyListeners();
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _api.delete('/journal/$id');
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }
}
