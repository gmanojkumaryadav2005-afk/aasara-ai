import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/goals_provider.dart';
import '../models/models.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<GoalsProvider>(context, listen: false).fetchGoals();
      }
    });
  }

  void _showAddGoalDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '4000000');
    final savingsCtrl = TextEditingController(text: '500000');
    final contribCtrl = TextEditingController(text: '25000');
    final dateCtrl = TextEditingController(text: '2030-12-31');
    String selectedCategory = 'House';

    final categories = ['House', 'Car', 'Emergency Fund', 'Education', 'Vacation', 'Business', 'Custom Goal'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.flag_rounded, color: Color(0xFF1E3A8A)),
                SizedBox(width: 8),
                Text('Create Financial Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Goal Title (e.g. Buy a House)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setDialogState(() => selectedCategory = val!),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Target Amount (₹)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: savingsCtrl,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Current Savings (₹)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: contribCtrl,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Monthly Saving (₹)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: dateCtrl,
                    decoration: InputDecoration(
                      labelText: 'Target Date (YYYY-MM-DD)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final target = double.tryParse(targetCtrl.text.trim()) ?? 0.0;
                  final savings = double.tryParse(savingsCtrl.text.trim()) ?? 0.0;
                  final contrib = double.tryParse(contribCtrl.text.trim()) ?? 0.0;
                  final date = dateCtrl.text.trim();

                  if (title.isNotEmpty && target > 0) {
                    final provider = Provider.of<GoalsProvider>(context, listen: false);
                    await provider.addGoal(title, selectedCategory, target, savings, contrib, date);
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Save Goal'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUpdateSavingsDialog(BuildContext context, Goal goal) {
    final savingsCtrl = TextEditingController(text: goal.currentSavings.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update Savings: ${goal.title}', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: savingsCtrl,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'New Current Savings Amount (₹)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newSavings = double.tryParse(savingsCtrl.text.trim()) ?? goal.currentSavings;
              final provider = Provider.of<GoalsProvider>(context, listen: false);
              await provider.updateGoalSavings(goal, newSavings);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1E3A8A), foregroundColor: Colors.white),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsProvider = Provider.of<GoalsProvider>(context);

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Financial Goals Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: goalsProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        Text('Overall Goals Target Progress', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${goalsProvider.totalCurrentSavings.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            Text(
                              'Target: ₹${goalsProvider.totalTargetAmount.toStringAsFixed(0)}',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (goalsProvider.overallProgressPercentage / 100).clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${goalsProvider.overallProgressPercentage.toStringAsFixed(1)}% of total targets saved',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Active Financial Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      ElevatedButton.icon(
                        onPressed: () => _showAddGoalDialog(context),
                        icon: Icon(Icons.add, size: 18),
                        label: Text('New Goal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  goalsProvider.goals.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(32),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              Icon(Icons.flag_outlined, size: 56, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text('No financial goals yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                              SizedBox(height: 8),
                              Text(
                                'Create a goal such as a house, emergency fund, education or vacation.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => _showAddGoalDialog(context),
                                icon: Icon(Icons.add),
                                label: Text('Create Goal'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: goalsProvider.goals.length,
                          itemBuilder: (context, index) {
                            final goal = goalsProvider.goals[index];
                            final pct = goal.progressPercentage;
                            final remMonths = goal.estimatedMonthsRemaining;

                            return Card(
                              margin: EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF1E3A8A).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(_getCategoryIcon(goal.category), color: Color(0xFF1E3A8A), size: 24),
                                        ),
                                        SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(goal.title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                              SizedBox(height: 2),
                                              Text('${goal.category} • Target Date: ${goal.targetDate}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit_outlined, color: Color(0xFF1E3A8A), size: 20),
                                          onPressed: () => _showUpdateSavingsDialog(context, goal),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
                                          onPressed: () => goalsProvider.deleteGoal(goal.id),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildGoalStat('Target', '₹${goal.targetAmount.toStringAsFixed(0)}'),
                                        _buildGoalStat('Saved', '₹${goal.currentSavings.toStringAsFixed(0)}'),
                                        _buildGoalStat('Monthly', '₹${goal.monthlyContribution.toStringAsFixed(0)}/mo'),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: (pct / 100).clamp(0.0, 1.0),
                                        minHeight: 8,
                                        backgroundColor: Colors.grey[200],
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${pct.toStringAsFixed(1)}% complete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
                                        Text(
                                          remMonths > 0 ? 'Approx ${remMonths.toStringAsFixed(1)} months remaining' : 'Target reached!',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildGoalStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'house':
        return Icons.home_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'emergency fund':
        return Icons.health_and_safety_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'vacation':
        return Icons.flight_takeoff_rounded;
      case 'business':
        return Icons.business_center_rounded;
      default:
        return Icons.flag_rounded;
    }
  }
}
