import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planning_provider.dart';
import '../models/models.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<PlanningProvider>(context, listen: false).fetchTasks();
      }
    });
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T').first);
    String selectedPriority = 'Medium';
    String selectedTimeOfDay = 'Morning';

    final priorities = ['High', 'Medium', 'Low'];
    final times = ['Morning', 'Afternoon', 'Evening'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Add Planned Task', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: 'Task Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedPriority,
                        decoration: InputDecoration(labelText: 'Priority', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        items: priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (v) => setDialogState(() => selectedPriority = v!),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedTimeOfDay,
                        decoration: InputDecoration(labelText: 'Time of Day', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        items: times.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setDialogState(() => selectedTimeOfDay = v!),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                TextField(
                  controller: dateCtrl,
                  decoration: InputDecoration(labelText: 'Target Date (YYYY-MM-DD)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final date = dateCtrl.text.trim();
                  if (title.isNotEmpty) {
                    final provider = Provider.of<PlanningProvider>(context, listen: false);
                    await provider.addTask(title, date, selectedPriority, selectedTimeOfDay);
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1E3A8A), foregroundColor: Colors.white),
                child: Text('Add Task'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planning = Provider.of<PlanningProvider>(context);

    final morningTasks = planning.tasksByTimeOfDay('Morning');
    final afternoonTasks = planning.tasksByTimeOfDay('Afternoon');
    final eveningTasks = planning.tasksByTimeOfDay('Evening');

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Daily Activity & Schedule Planning', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: planning.isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Plan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  SizedBox(height: 12),

                  _buildTimeSection(planning, '🌅 Morning', morningTasks),
                  SizedBox(height: 16),
                  _buildTimeSection(planning, '☀️ Afternoon', afternoonTasks),
                  SizedBox(height: 16),
                  _buildTimeSection(planning, '🌙 Evening', eveningTasks),
                  SizedBox(height: 24),

                  if (planning.completedTasks.isNotEmpty) ...[
                    _buildSectionHeader('Completed Tasks', planning.completedTasks.length),
                    SizedBox(height: 8),
                    Column(
                      children: planning.completedTasks.map((task) => _buildTaskCard(planning, task)).toList(),
                    ),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: Icon(Icons.add_task_rounded),
        label: Text('New Task', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTimeSection(PlanningProvider planning, String title, List<TaskItem> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        SizedBox(height: 6),
        tasks.isEmpty
            ? Container(
                width: double.infinity,
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Text('No tasks planned for this period.', style: TextStyle(color: Colors.grey[400], fontSize: 13, fontStyle: FontStyle.italic)),
              )
            : Column(
                children: tasks.map((task) => _buildTaskCard(planning, task)).toList(),
              ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
          child: Text('$count', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildTaskCard(PlanningProvider planning, TaskItem task) {
    final isHigh = task.priority == 'High';
    final isMedium = task.priority == 'Medium';

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          activeColor: Color(0xFF1E3A8A),
          onChanged: (_) => planning.toggleTask(task),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey[500] : Colors.black87,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isHigh ? Colors.red[50] : (isMedium ? Colors.amber[50] : Colors.green[50]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${isHigh ? "🔴" : (isMedium ? "🟡" : "🟢")} ${task.priority}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isHigh ? Colors.red[800] : (isMedium ? Colors.amber[900] : Colors.green[800])),
              ),
            ),
            if (task.dueDate.isNotEmpty) ...[
              SizedBox(width: 8),
              Text('Due: ${task.dueDate}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
          onPressed: () => planning.deleteTask(task.id),
        ),
      ),
    );
  }
}
