import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/models.dart';

class ChatProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<ChatSession> _sessions = [];
  List<ChatMessage> _currentMessages = [];
  ChatSession? _currentSession;
  bool _isLoading = false;
  bool _isThinking = false;

  List<ChatSession> get sessions => _sessions;
  List<ChatMessage> get currentMessages => _currentMessages;
  ChatSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  bool get isThinking => _isThinking;

  Future<void> fetchSessions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/chat/sessions');
      if (response != null && response is List) {
        _sessions = response.map((e) => ChatSession.fromJson(e)).toList();
      }
    } catch (e) {
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<ChatSession?> createSession(String title) async {
    try {
      final response = await _api.post('/chat/sessions', body: {'title': title});
      if (response != null) {
        final session = ChatSession.fromJson(response);
        _sessions.insert(0, session);
        await selectSession(session);
        return session;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<void> selectSession(ChatSession session) async {
    _currentSession = session;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/chat/sessions/${session.id}/messages');
      if (response != null && response is List) {
        _currentMessages = response.map((e) => ChatMessage.fromJson(e)).toList();
      } else {
        _currentMessages = [];
      }
    } catch (e) {
      print(e);
      _currentMessages = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    if (_currentSession == null) {
      final session = await createSession('AASARA Support');
      if (session == null) return;
    }

    final userMsg = ChatMessage(id: DateTime.now().toIso8601String(), role: 'user', content: text);
    _currentMessages.add(userMsg);
    _isThinking = true;
    notifyListeners();

    try {
      final response = await _api.post('/chat/sessions/${_currentSession!.id}/message', body: {'message': text});
      if (response != null && response['reply'] != null) {
        final replyText = response['reply'].toString();
        _currentMessages.add(ChatMessage(
          id: DateTime.now().toIso8601String(),
          role: 'model',
          content: replyText,
        ));
      }
    } catch (e) {
      _currentMessages.add(ChatMessage(
        id: DateTime.now().toIso8601String(),
        role: 'model',
        content: "I'm right here with you. It seems there was a network glitch, but please know you're not alone. What would you like to talk about?",
      ));
    }
    _isThinking = false;
    notifyListeners();
  }
}
