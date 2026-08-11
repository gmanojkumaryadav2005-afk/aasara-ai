import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/models.dart';

class GroceryProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<GroceryItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  final double _groceryBudget = 5000.0;

  List<GroceryItem> get items => _items;
  List<GroceryItem> get shoppingList => _items.where((i) => !i.isPurchased).toList();
  List<GroceryItem> get purchasedList => _items.where((i) => i.isPurchased).toList();
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get groceryBudget => _groceryBudget;

  double get totalPlannedCost => _items.where((i) => !i.isPurchased).fold(0.0, (sum, i) => sum + (i.quantityNeeded * i.estimatedPrice));
  double get totalPurchasedCost => _items.where((i) => i.isPurchased).fold(0.0, (sum, i) => sum + (i.quantityNeeded * i.estimatedPrice));
  double get remainingGroceryBudget => (_groceryBudget - totalPurchasedCost).clamp(0.0, double.infinity);

  int get totalItems => _items.length;
  int get purchasedItemsCount => purchasedList.length;
  int get remainingItemsCount => shoppingList.length;

  Future<void> fetchItems() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/groceries/');
      if (response != null && response is List) {
        _items = response.map((json) => GroceryItem.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = 'Failed to load grocery list';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem(String name, String category, double quantity, String unit, double price) async {
    try {
      final response = await _apiClient.post('/groceries/', body: {
        'name': name,
        'category': category,
        'quantity_needed': quantity,
        'unit': unit,
        'estimated_price_per_unit': price,
        'is_purchased': false,
      });

      if (response != null) {
        await fetchItems();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to add grocery item';
    }
    return false;
  }

  Future<void> togglePurchased(GroceryItem item) async {
    try {
      final newStatus = !item.isPurchased;
      final response = await _apiClient.put('/groceries/${item.id}', body: {
        'is_purchased': newStatus,
        'date_purchased': newStatus ? DateTime.now().toIso8601String().split('T').first : null,
      });

      if (response != null) {
        await fetchItems();
      }
    } catch (e) {
      _errorMessage = 'Failed to update item';
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      final response = await _apiClient.delete('/groceries/$itemId');
      if (response != null) {
        _items.removeWhere((item) => item.id == itemId);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to delete item';
    }
  }
}
