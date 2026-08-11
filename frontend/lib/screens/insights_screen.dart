import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/insights_provider.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<InsightsProvider>(context, listen: false).fetchInsights();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final insights = Provider.of<InsightsProvider>(context);
    final data = insights.data;

    final List list = data['insights'] ?? [];

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Financial & Wellbeing Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: insights.isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Personalized Observations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  SizedBox(height: 6),
                  Text('Real-time analysis based on your budget, financial goals, grocery list, and journal activity.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  SizedBox(height: 20),

                  if (list.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Icon(Icons.analytics_outlined, size: 56, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'Not enough data yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add transactions, grocery items, or reflections to generate personalized observations.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: list.map((item) {
                        final type = item['type'] ?? 'info';
                        final title = item['title'] ?? '';
                        final desc = item['description'] ?? '';

                        return Container(
                          margin: EdgeInsets.only(bottom: 14),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _getBorderColor(type)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: Offset(0, 3))],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: _getBorderColor(type).withValues(alpha: 0.15),
                                child: Icon(_getIcon(type), color: _getBorderColor(type), size: 20),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
                                    SizedBox(height: 4),
                                    Text(desc, style: TextStyle(color: Colors.grey[700], fontSize: 13.5, height: 1.4)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
    );
  }

  Color _getBorderColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.amber[800]!;
      case 'positive':
        return Colors.green[700]!;
      case 'goal':
        return Colors.purple[700]!;
      case 'reflection':
        return Colors.teal[700]!;
      default:
        return Color(0xFF1E3A8A);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'positive':
        return Icons.trending_up_rounded;
      case 'goal':
        return Icons.flag_rounded;
      case 'reflection':
        return Icons.psychology_outlined;
      default:
        return Icons.lightbulb_outline_rounded;
    }
  }
}
