import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/grocery_provider.dart';
import '../providers/finances_provider.dart';
import '../models/models.dart';

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<GroceryProvider>(context, listen: false).fetchItems();
      }
    });
  }

  void _showAddItemDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1.0');
    final priceCtrl = TextEditingController(text: '50.0');
    String selectedCategory = 'Essentials';
    String selectedUnit = 'Kg';

    final categories = ['Essentials', 'Vegetables', 'Fruits', 'Dairy', 'Meat', 'Snacks', 'Beverages', 'Household', 'Other'];
    final units = ['Kg', 'g', 'Litre', 'Pcs', 'Pack', 'Dozen'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
          final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
          final estimatedTotal = qty * price;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.shopping_bag_outlined, color: Color(0xFF1E3A8A)),
                SizedBox(width: 8),
                Text('Add Grocery Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Item Name (e.g. Milk, Tomatoes, Eggs)',
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setDialogState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedUnit,
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (val) => setDialogState(() => selectedUnit = val!),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Price per Unit (₹)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 14),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E3A8A).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Estimated Total:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                        Text(
                          '₹${estimatedTotal.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E3A8A)),
                        ),
                      ],
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
                  final name = nameCtrl.text.trim();
                  final validQty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
                  final validPrice = double.tryParse(priceCtrl.text.trim()) ?? 0.0;

                  if (name.isNotEmpty) {
                    final provider = Provider.of<GroceryProvider>(context, listen: false);
                    final ok = await provider.addItem(name, selectedCategory, validQty, selectedUnit, validPrice);
                    if (ok && context.mounted) {
                      Provider.of<FinancesProvider>(context, listen: false).fetchSummaryAndTransactions();
                    }
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
                child: Text('Add Item'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groceryProvider = Provider.of<GroceryProvider>(context);

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Smart Grocery Planner', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Summary Panel
          Container(
            padding: EdgeInsets.all(20),
            color: Color(0xFF1E3A8A),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryStat('GROCERY BUDGET', '₹${groceryProvider.groceryBudget.toStringAsFixed(0)}'),
                      Container(height: 30, width: 1, color: Colors.white24),
                      _buildSummaryStat('PLANNED', '₹${groceryProvider.totalPlannedCost.toStringAsFixed(0)}'),
                      Container(height: 30, width: 1, color: Colors.white24),
                      _buildSummaryStat('PURCHASED', '₹${groceryProvider.totalPurchasedCost.toStringAsFixed(0)}'),
                      Container(height: 30, width: 1, color: Colors.white24),
                      _buildSummaryStat('REMAINING', '₹${groceryProvider.remainingGroceryBudget.toStringAsFixed(0)}'),
                    ],
                  ),
                  SizedBox(height: 12),
                  Divider(color: Colors.white24),
                  SizedBox(height: 6),
                  Text(
                    'ITEMS: ${groceryProvider.totalItems} total • ${groceryProvider.purchasedItemsCount} purchased • ${groceryProvider.remainingItemsCount} remaining',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          // Lists Section
          Expanded(
            child: groceryProvider.isLoading
                ? Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
                : groceryProvider.items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text('Your shopping list is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                              SizedBox(height: 8),
                              Text(
                                'Add items to start planning your next grocery trip.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => _showAddItemDialog(context),
                                icon: Icon(Icons.add),
                                label: Text('Add Grocery Item'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (groceryProvider.shoppingList.isNotEmpty) ...[
                              Text('Shopping List (Planned)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                              SizedBox(height: 8),
                              ...groceryProvider.shoppingList.map((item) => _buildGroceryCard(context, groceryProvider, item)),
                              SizedBox(height: 20),
                            ],

                            if (groceryProvider.purchasedList.isNotEmpty) ...[
                              Text('Purchased Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                              SizedBox(height: 8),
                              ...groceryProvider.purchasedList.map((item) => _buildGroceryCard(context, groceryProvider, item)),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('Add Grocery Item', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildGroceryCard(BuildContext context, GroceryProvider groceryProvider, GroceryItem item) {
    final itemTotal = item.quantityNeeded * item.estimatedPrice;

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Checkbox(
          value: item.isPurchased,
          activeColor: Color(0xFF1E3A8A),
          onChanged: (_) async {
            await groceryProvider.togglePurchased(item);
            if (context.mounted) {
              Provider.of<FinancesProvider>(context, listen: false).fetchSummaryAndTransactions();
            }
          },
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
            color: item.isPurchased ? Colors.grey[500] : Colors.black87,
          ),
        ),
        subtitle: Text(
          '${item.category} • ${item.quantityNeeded} ${item.unit} @ ₹${item.estimatedPrice.toStringAsFixed(0)}/${item.unit}',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${itemTotal.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: item.isPurchased ? Colors.grey[500] : Color(0xFF1E3A8A),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
              onPressed: () async {
                await groceryProvider.deleteItem(item.id);
                if (context.mounted) {
                  Provider.of<FinancesProvider>(context, listen: false).fetchSummaryAndTransactions();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
