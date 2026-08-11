import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finances_provider.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key});

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<FinancesProvider>(context, listen: false).fetchSummaryAndTransactions();
      }
    });
  }

  void _showAddTransactionDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'Groceries';
    String type = 'expense';

    final categories = ['Groceries', 'Housing', 'Food', 'Utilities', 'Entertainment', 'Healthcare', 'Transport', 'Education', 'Goals', 'Other'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: 'Title / Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setDialogState(() => category = v!),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: InputDecoration(labelText: 'Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        items: const [
                          DropdownMenuItem(value: 'expense', child: Text('Expense')),
                          DropdownMenuItem(value: 'income', child: Text('Income')),
                        ],
                        onChanged: (v) => setDialogState(() => type = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                  if (title.isNotEmpty && amount > 0) {
                    final provider = Provider.of<FinancesProvider>(context, listen: false);
                    await provider.addTransaction(title, amount, category, type);
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1E3A8A), foregroundColor: Colors.white),
                child: Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finances = Provider.of<FinancesProvider>(context);
    final summary = finances.summary;
    final weekly = finances.weeklyReview;

    final income = (summary['monthly_income'] ?? 60000.0).toDouble();
    final budget = (summary['monthly_budget'] ?? 30000.0).toDouble();
    final spent = (summary['total_spent'] ?? 0.0).toDouble();
    final savings = (summary['savings'] ?? (income - spent)).toDouble();
    final savingsRate = (summary['savings_rate'] ?? 0.0).toDouble();

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Financial Health Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: finances.isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 15, offset: Offset(0, 8))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Financial Summary Overview', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatColumn('Monthly Income', '₹${income.toStringAsFixed(0)}'),
                            _buildStatColumn('Expenses', '₹${spent.toStringAsFixed(0)}'),
                            _buildStatColumn('Savings', '₹${savings.toStringAsFixed(0)}'),
                            _buildStatColumn('Savings Rate', '$savingsRate%'),
                          ],
                        ),
                        SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (spent / budget).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(spent > budget ? Colors.redAccent : Colors.lightGreenAccent),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '₹${spent.toStringAsFixed(0)} spent of ₹${budget.toStringAsFixed(0)} planned budget',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Weekly Financial Review Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1,
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.date_range_rounded, color: Color(0xFF1E3A8A)),
                              SizedBox(width: 8),
                              Text('Weekly Financial Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
                              Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  weekly['status'] ?? 'Within Budget',
                                  style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('This Week Spending: ₹${(weekly['weekly_spending'] ?? 0.0).toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              Text('Top Category: ${weekly['top_spending_category'] ?? "Groceries"}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            weekly['recommendation'] ?? 'Keep monitoring discretionary spending.',
                            style: TextStyle(color: Colors.grey[700], fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      ElevatedButton.icon(
                        onPressed: () => _showAddTransactionDialog(context),
                        icon: Icon(Icons.add, size: 18),
                        label: Text('Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  finances.transactions.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(32),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey[400]),
                                SizedBox(height: 12),
                                Text('No transactions recorded yet', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                SizedBox(height: 4),
                                Text('Tap + Add to record income or expenses.', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: finances.transactions.length,
                          itemBuilder: (context, index) {
                            final item = finances.transactions[index];
                            final isExpense = item.type == 'expense';

                            return Card(
                              margin: EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isExpense ? Colors.red[50] : Colors.green[50],
                                  child: Icon(
                                    isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isExpense ? Colors.red : Colors.green,
                                    size: 20,
                                  ),
                                ),
                                title: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${item.category} • ${item.date}', style: TextStyle(fontSize: 12)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${isExpense ? '-' : '+'}₹${item.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isExpense ? Colors.red[700] : Colors.green[700],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, color: Colors.grey[400], size: 20),
                                      onPressed: () => finances.deleteTransaction(item.id),
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

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 11)),
        SizedBox(height: 2),
        Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
      ],
    );
  }
}
