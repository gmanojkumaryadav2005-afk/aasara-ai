import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final provider = Provider.of<ChatProvider>(context, listen: false);
      await provider.fetchSessions();
      if (provider.sessions.isNotEmpty) {
        await provider.selectSession(provider.sessions.first);
      } else {
        await provider.createSession("AASARA Support");
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendTextMessage(String text) {
    if (text.trim().isNotEmpty) {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      if (provider.isThinking) return; // Prevent duplicate submission while generating
      provider.sendMessage(text.trim());
      _controller.clear();
      Future.delayed(Duration(milliseconds: 150), _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    final suggestions = [
      "🏠 I want to save money to buy a house.",
      "🛒 I spent too much on groceries.",
      "💙 I am not feeling strong enough today.",
      "💰 What is my monthly budget status?",
    ];

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AASARA Confidant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('AI Financial & Mental Wellbeing Companion', style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Unobtrusive Privacy & Guidance Banner
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Color(0xFFEFF6FF),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: Color(0xFF1E3A8A)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🔒 Privacy Notice: Avoid sharing passwords, PINs, or sensitive credentials. AASARA provides supportive guidance, not licensed medical, therapy, legal, or financial advice.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          // Messages View
          Expanded(
            child: chatProvider.isLoading
                ? Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
                : chatProvider.currentMessages.isEmpty
                    ? SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 30),
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Color(0xFF1E3A8A).withValues(alpha: 0.1),
                              child: Icon(Icons.psychology_outlined, size: 40, color: Color(0xFF1E3A8A)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Hi, I\'m AASARA 👋',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'You can talk to me about whatever is on your mind — work, money, goals, family, career, or everyday life.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
                            ),
                            SizedBox(height: 24),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Optional Conversation Starters:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                                  SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: suggestions.map((s) => ActionChip(
                                      label: Text(s, style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A))),
                                      backgroundColor: Color(0xFFF1F5F9),
                                      onPressed: () => _sendTextMessage(s),
                                    )).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16),
                        itemCount: chatProvider.currentMessages.length + (chatProvider.isThinking ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatProvider.currentMessages.length && chatProvider.isThinking) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 8),
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E3A8A))),
                                    SizedBox(width: 10),
                                    Text('AASARA is thinking...', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                            );
                          }

                          final msg = chatProvider.currentMessages[index];
                          final isUser = msg.role == 'user';

                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                              margin: EdgeInsets.symmetric(vertical: 6),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isUser ? Color(0xFF1E3A8A) : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  topRight: Radius.circular(18),
                                  bottomLeft: isUser ? Radius.circular(18) : Radius.circular(4),
                                  bottomRight: isUser ? Radius.circular(4) : Radius.circular(18),
                                ),
                                border: isUser ? null : Border.all(color: Colors.grey[200]!),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: Offset(0, 2)),
                                ],
                              ),
                              child: SelectableText(
                                msg.content,
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black87,
                                  fontSize: 14.5,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Suggestion Chips Bar
          if (chatProvider.currentMessages.isNotEmpty)
            SizedBox(
              height: 46,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12),
                itemCount: suggestions.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(suggestions[i], style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w500)),
                      backgroundColor: Colors.white,
                      elevation: 1,
                      onPressed: chatProvider.isThinking ? null : () => _sendTextMessage(suggestions[i]),
                    ),
                  );
                },
              ),
            ),

          // Chat Input Area
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 4,
                    minLines: 1,
                    enabled: !chatProvider.isThinking,
                    onSubmitted: chatProvider.isThinking ? null : _sendTextMessage,
                    decoration: InputDecoration(
                      hintText: 'Share what\'s on your mind...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      filled: true,
                      fillColor: Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: chatProvider.isThinking ? Colors.grey[400] : Color(0xFF1E3A8A),
                  child: IconButton(
                    icon: chatProvider.isThinking
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: chatProvider.isThinking ? null : () => _sendTextMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
