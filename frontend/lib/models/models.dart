class User {
  final String id;
  final String email;
  final String fullName;
  final double familySize;
  final double monthlyIncome;
  final double monthlyBudget;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.familySize,
    required this.monthlyIncome,
    required this.monthlyBudget,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? 'User',
      familySize: (json['family_size'] ?? 1.0).toDouble(),
      monthlyIncome: (json['monthly_income'] ?? 60000.0).toDouble(),
      monthlyBudget: (json['monthly_budget'] ?? 30000.0).toDouble(),
    );
  }
}

class GroceryItem {
  final String id;
  final String name;
  final String category;
  final double quantityNeeded;
  final String unit;
  final double estimatedPrice;
  final bool isPurchased;
  final String? datePurchased;

  GroceryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantityNeeded,
    required this.unit,
    required this.estimatedPrice,
    this.isPurchased = false,
    this.datePurchased,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Essentials',
      quantityNeeded: (json['quantity_needed'] ?? 1.0).toDouble(),
      unit: json['unit'] ?? 'Kg',
      estimatedPrice: (json['estimated_price_per_unit'] ?? 0.0).toDouble(),
      isPurchased: json['is_purchased'] ?? false,
      datePurchased: json['date_purchased'],
    );
  }
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String type; // 'expense' or 'income'
  final String date;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      category: json['category'] ?? 'General',
      type: json['type'] ?? 'expense',
      date: json['date'] ?? '',
    );
  }
}

class Goal {
  final String id;
  final String title;
  final String category;
  final double targetAmount;
  final double currentSavings;
  final double monthlyContribution;
  final String targetDate;

  Goal({
    required this.id,
    required this.title,
    required this.category,
    required this.targetAmount,
    required this.currentSavings,
    required this.monthlyContribution,
    required this.targetDate,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'Custom Goal',
      targetAmount: (json['target_amount'] ?? 0.0).toDouble(),
      currentSavings: (json['current_savings'] ?? 0.0).toDouble(),
      monthlyContribution: (json['monthly_contribution'] ?? 0.0).toDouble(),
      targetDate: json['target_date'] ?? '',
    );
  }

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentSavings / targetAmount * 100.0).clamp(0.0, 100.0);
  }

  double get remainingAmount => (targetAmount - currentSavings).clamp(0.0, double.infinity);

  double get estimatedMonthsRemaining {
    if (monthlyContribution <= 0) return 0.0;
    return (remainingAmount / monthlyContribution);
  }
}

class JournalEntry {
  final String id;
  final String title;
  final String content;
  final String mood;
  final String createdAt;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.createdAt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      mood: json['mood'] ?? 'Neutral',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  final String dueDate;
  final String dueTime;
  final bool isCompleted;
  final String priority; // 'High', 'Medium', 'Low'
  final String timeOfDay; // 'Morning', 'Afternoon', 'Evening'

  TaskItem({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.dueTime,
    required this.isCompleted,
    this.priority = 'Medium',
    this.timeOfDay = 'Morning',
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      dueDate: json['due_date'] ?? '',
      dueTime: json['due_time'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      priority: json['priority'] ?? 'Medium',
      timeOfDay: json['time_of_day'] ?? 'Morning',
    );
  }
}

class ChatSession {
  final String id;
  final String title;

  ChatSession({required this.id, required this.title});

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(id: json['id'] ?? '', title: json['title'] ?? 'AASARA Session');
  }
}

class ChatMessage {
  final String id;
  final String role;
  final String content;

  ChatMessage({required this.id, required this.role, required this.content});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
    );
  }
}
