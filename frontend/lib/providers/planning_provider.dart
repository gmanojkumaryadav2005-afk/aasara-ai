import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/models.dart';

class PlanningProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<TaskItem> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TaskItem> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TaskItem> get activeTasks => _tasks.where((t) => !t.isCompleted).toList();
  List<TaskItem> get completedTasks => _tasks.where((t) => t.isCompleted).toList();

  List<TaskItem> tasksByTimeOfDay(String timeOfDay) {
    return activeTasks.where((t) => t.timeOfDay.toLowerCase() == timeOfDay.toLowerCase()).toList();
  }

  Future<void> fetchTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/planning/tasks');
      if (response != null && response is List) {
        _tasks = response.map((json) => TaskItem.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = 'Failed to load tasks';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTask(String title, String dueDate, String priority, String timeOfDay) async {
    try {
      final response = await _apiClient.post('/planning/tasks', body: {
        'title': title,
        'due_date': dueDate,
        'priority': priority,
        'time_of_day': timeOfDay,
        'is_completed': false,
      });

      if (response != null) {
        await fetchTasks();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to create task';
    }
    return false;
  }

  Future<void> toggleTask(TaskItem task) async {
    try {
      final newStatus = !task.isCompleted;
      final response = await _apiClient.put('/planning/tasks/${task.id}', body: {
        'is_completed': newStatus,
      });

      if (response != null) {
        await fetchTasks();
      }
    } catch (e) {
      _errorMessage = 'Failed to update task';
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final response = await _apiClient.delete('/planning/tasks/$taskId');
      if (response != null) {
        _tasks.removeWhere((t) => t.id == taskId);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to delete task';
    }
  }
}
