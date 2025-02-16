import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../models/todo_item.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

class AIAssistantDialog extends StatefulWidget {
  final Function(TodoItem) onTodoCreated;

  const AIAssistantDialog({
    super.key,
    required this.onTodoCreated,
  });

  @override
  State<AIAssistantDialog> createState() => _AIAssistantDialogState();
}

class _AIAssistantDialogState extends State<AIAssistantDialog> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI 助手'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _promptController,
            decoration: const InputDecoration(
              hintText: '请描述你要创建的待办事项...',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            maxLines: 3,
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _generateTodoItem,
          child: const Text('生成'),
        ),
      ],
    );
  }

  Future<void> _generateTodoItem() async {
    if (_promptController.text.isEmpty) {
      setState(() {
        _error = '请输入描述';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 获取 AI 生成的待办事项列表
      final aiResponses = await AIService.generateTodoItems(_promptController.text);
      
      // 转换为 TodoItem 对象列表
      final todoItems = AIService.convertToTodoItems(aiResponses);
      
      if (todoItems.isEmpty) {
        throw Exception('未能生成有效的待办事项');
      }

      // 显示预览对话框
      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认创建待办事项'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('将创建以下待办事项：'),
                  const SizedBox(height: 12),
                  ...todoItems.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (item.content.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(item.content),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.deadline != null
                                    ? _formatDateTime(item.deadline!)
                                    : '未设置时间',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.timer,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '预计 ${_formatDuration(item.estimatedDuration)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (item.tags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: item.tags.map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: tag.color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tag.name,
                                  style: TextStyle(
                                    color: tag.color,
                                    fontSize: 12,
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('创建'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          // 显示导出选项
          final exportToCalendar = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('添加到系统日历'),
              content: const Text('是否同时将待办事项添加到系统日历？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('否'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('是'),
                ),
              ],
            ),
          );

          // 创建所有待办事项
          for (final item in todoItems) {
            widget.onTodoCreated(item);
            if (exportToCalendar == true) {
              try {
                final event = item.toCalendarEvent();
                final success = await Add2Calendar.addEvent2Cal(event);
                
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('添加"${item.title}"到日历失败'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('添加"${item.title}"到日历时出错：$e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          }
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '生成失败: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}月${dateTime.day}日 '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}小时${duration.inMinutes % 60}分钟';
    }
    return '${duration.inMinutes}分钟';
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }
} 