import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/finances_provider.dart';
import '../providers/grocery_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/planning_provider.dart';
import '../providers/journal_provider.dart';
import 'grocery_screen.dart';
import 'chat_screen.dart';
import 'financial_screen.dart';
import 'goals_screen.dart';
import 'journal_screen.dart';
import 'planning_screen.dart';
import 'insights_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<FinancesProvider>(context, listen: false).fetchSummaryAndTransactions();
        Provider.of<GroceryProvider>(context, listen: false).fetchItems();
        Provider.of<GoalsProvider>(context, listen: false).fetchGoals();
        Provider.of<PlanningProvider>(context, listen: false).fetchTasks();
        Provider.of<JournalProvider>(context, listen: false).fetchEntries();
      }
    });
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: Color(0xFF1E3A8A)),
            SizedBox(width: 8),
            Text('Notifications & Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
            SizedBox(height: 12),
            Text("You're all caught up!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            SizedBox(height: 4),
            Text('No urgent financial warnings or budget alerts at this time.', style: TextStyle(color: Colors.grey[600], fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))));
    }

    final pages = [
      _buildDashboardHome(context, user),
      GoalsScreen(),
      GroceryScreen(),
      ChatScreen(),
      JournalScreen(),
      PlanningScreen(),
      InsightsScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'AASARA',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1, fontSize: 19),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded),
            onPressed: () => _showNotificationsDialog(context),
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: Icon(Icons.person_outline_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen())),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded),
            onPressed: () => auth.logout(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey[500],
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.flag_rounded), label: 'Goals'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_rounded), label: 'Groceries'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology_rounded), label: 'Confidant'),
          BottomNavigationBarItem(icon: Icon(Icons.book_rounded), label: 'Journal'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Planning'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb_rounded), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDashboardHome(BuildContext context, user) {
    final finances = Provider.of<FinancesProvider>(context);
    final groceries = Provider.of<GroceryProvider>(context);
    final goals = Provider.of<GoalsProvider>(context);
    final planning = Provider.of<PlanningProvider>(context);
    final journal = Provider.of<JournalProvider>(context);

    final summary = finances.summary;
    final budget = (summary['monthly_budget'] ?? user.monthlyBudget).toDouble();
    final spent = (summary['total_spent'] ?? 0.0).toDouble();
    final remaining = (summary['remaining_budget'] ?? (budget - spent)).toDouble();
    final pct = (summary['percentage_used'] ?? 0.0).toDouble();
    final savingsRate = (summary['savings_rate'] ?? 0.0).toDouble();

    final topGoal = goals.goals.isNotEmpty ? goals.goals.first : null;
    final pendingTasks = planning.activeTasks.length;
    final latestMood = journal.entries.isNotEmpty ? journal.entries.first.mood : 'Good';

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Welcome Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.15), blurRadius: 12, offset: Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good day, ${user.fullName} 👋',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                SizedBox(height: 6),
                Text(
                  "Here's your financial & wellbeing overview.",
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Financial Health Overview Card
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FinancialScreen())),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF1E3A8A), size: 24),
                            SizedBox(width: 8),
                            Text('Financial Health', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                          ],
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryStat('Monthly Budget', '₹${budget.toStringAsFixed(0)}'),
                        _buildSummaryStat('Spent', '₹${spent.toStringAsFixed(0)}'),
                        _buildSummaryStat('Remaining', '₹${remaining.toStringAsFixed(0)}'),
                        _buildSummaryStat('Savings Rate', '$savingsRate%'),
                      ],
                    ),
                    SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(pct > 90 ? Colors.red : Color(0xFF1E3A8A)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Modules Summary Highlights Row
          Row(
            children: [
              // Savings Goal Summary
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = 1),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.flag_rounded, color: Colors.purple, size: 20),
                            SizedBox(width: 6),
                            Text('Savings Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          topGoal != null ? topGoal.title : 'No Goal Set',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          topGoal != null ? '${topGoal.progressPercentage.toStringAsFixed(1)}% complete' : 'Tap to set house goal',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),

              // Grocery Budget Summary
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = 2),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shopping_cart_outlined, color: Colors.orange[800], size: 20),
                            SizedBox(width: 6),
                            Text('Grocery Budget', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '₹${groceries.totalPurchasedCost.toStringAsFixed(0)} / ₹${groceries.groceryBudget.toStringAsFixed(0)}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${groceries.remainingItemsCount} planned items',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          Row(
            children: [
              // Today's Plan Summary
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = 5),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.checklist_rounded, color: Colors.green[700], size: 22),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Today's Plan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                            Text('$pendingTasks tasks remaining', style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),

              // Wellbeing Mood Summary
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = 4),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.favorite_outline_rounded, color: Colors.pink[400], size: 22),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Wellbeing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                            Text('Mood: $latestMood', style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 28),

          Text('Key Companion Modules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          SizedBox(height: 12),

          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildFeatureTile(
                context,
                'Financial Goals',
                'House, Car & Target Fund',
                Icons.flag_rounded,
                Color(0xFF7C3AED),
                () => setState(() => _selectedIndex = 1),
              ),
              _buildFeatureTile(
                context,
                'Grocery Planner',
                'Shopping List & Costs',
                Icons.shopping_cart_outlined,
                Color(0xFFEA580C),
                () => setState(() => _selectedIndex = 2),
              ),
              _buildFeatureTile(
                context,
                'AASARA Confidant',
                'Contextual AI Companion',
                Icons.psychology_outlined,
                Color(0xFF2563EB),
                () => setState(() => _selectedIndex = 3),
              ),
              _buildFeatureTile(
                context,
                'Reflections Journal',
                'Mindfulness reflections',
                Icons.menu_book_rounded,
                Color(0xFF059669),
                () => setState(() => _selectedIndex = 4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A))),
      ],
    );
  }

  Widget _buildFeatureTile(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 26, color: color),
            ),
            SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A))),
            SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
