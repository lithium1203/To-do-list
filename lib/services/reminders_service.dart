import 'package:flutter/services.dart';
import '../models/todo_item.dart';

class RemindersService {
  static const platform = MethodChannel('com.example.todo_list/reminders');

  /// 添加待办事项到系统提醒事项
  static Future<bool> addToReminders(TodoItem item) async {
    try {
      final bool result = await platform.invokeMethod('addReminder', {
        'title': item.title,
        'notes': item.content,
        'dueDate': item.deadline?.millisecondsSinceEpoch,
        'priority': _getPriorityValue(item.urgency),
        'isAllDay': item.isAllDay,
        'hasAlarm': true,
        'alarmDate': item.deadline?.subtract(const Duration(minutes: 30)).millisecondsSinceEpoch,
      });
      return result;
    } on PlatformException catch (e) {
      throw RemindersException(
        code: e.code,
        message: e.message ?? '未知错误',
        details: e.details?.toString(),
      );
    }
  }

  /// 将紧急度转换为系统提醒事项的优先级
  static int _getPriorityValue(UrgencyLevel urgency) {
    switch (urgency) {
      case UrgencyLevel.veryUrgent:
        return 1; // High priority
      case UrgencyLevel.urgent:
        return 5; // Medium priority
      case UrgencyLevel.normal:
        return 9; // Low priority
      default:
        return 5;
    }
  }
}

class RemindersException implements Exception {
  final String code;
  final String message;
  final String? details;

  RemindersException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'RemindersException($code): $message${details != null ? '\n$details' : ''}';
} 