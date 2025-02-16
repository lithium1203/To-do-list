import 'package:flutter/material.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import '../exceptions/calendar_exception.dart';

enum Priority { low, medium, high }

enum UrgencyLevel {
  normal('普通', Color(0xFF8E8E93)),
  urgent('紧急', Color(0xFFFFA726)),
  veryUrgent('非常紧急', Color(0xFFE53935));

  final String label;
  final Color color;
  const UrgencyLevel(this.label, this.color);
}

class TodoTag {
  final String name;
  final IconData icon;
  final Color color;

  const TodoTag({
    required this.name,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'color': color.value,
  };

  factory TodoTag.fromJson(Map<String, dynamic> json) => TodoTag(
    name: json['name'] as String,
    icon: Icons.label, // 默认图标
    color: Color(json['color'] as int),
  );
}

class TodoItem {
  String title;
  String content;
  bool isDone;
  DateTime? deadline;
  DateTime? endTime;
  bool isAllDay;
  String repeat;
  List<TodoTag> tags;
  UrgencyLevel urgency;
  
  // AI Service 需要的字段
  DateTime dueTime;
  Priority priority;
  String description;
  Duration estimatedDuration;
  String category;
  String? location;

  TodoItem({
    required this.title,
    this.content = '',
    this.isDone = false,
    this.deadline,
    this.endTime,
    this.isAllDay = false,
    this.repeat = 'never',
    this.tags = const [],
    this.urgency = UrgencyLevel.normal,
    DateTime? dueTime,
    this.priority = Priority.low,
    this.description = '',
    this.estimatedDuration = const Duration(minutes: 30),
    this.category = '其他',
    this.location,
  }) : dueTime = dueTime ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'isDone': isDone,
    'deadline': deadline?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'isAllDay': isAllDay,
    'repeat': repeat,
    'tags': tags.map((tag) => tag.toJson()).toList(),
    'urgency': urgency.index,
    'dueTime': dueTime.toIso8601String(),
    'priority': priority.index,
    'description': description,
    'estimatedDuration': estimatedDuration.inMinutes,
    'category': category,
    'location': location,
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
    title: json['title'] as String,
    content: json['content'] as String? ?? '',
    isDone: json['isDone'] as bool? ?? false,
    deadline: json['deadline'] == null 
        ? null 
        : DateTime.parse(json['deadline'] as String),
    endTime: json['endTime'] == null 
        ? null 
        : DateTime.parse(json['endTime'] as String),
    isAllDay: json['isAllDay'] as bool? ?? false,
    repeat: json['repeat'] as String? ?? 'never',
    tags: (json['tags'] as List?)?.map((tagJson) => 
      TodoTag.fromJson(tagJson as Map<String, dynamic>)
    ).toList() ?? [],
    urgency: UrgencyLevel.values[json['urgency'] as int? ?? 0],
    dueTime: json['dueTime'] == null 
        ? DateTime.now() 
        : DateTime.parse(json['dueTime'] as String),
    priority: Priority.values[json['priority'] as int? ?? 0],
    description: json['description'] as String? ?? '',
    estimatedDuration: Duration(minutes: json['estimatedDuration'] as int? ?? 30),
    category: json['category'] as String? ?? '其他',
    location: json['location'] as String?,
  );

  Event toCalendarEvent() {
    if (deadline == null) {
      throw CalendarException(
        'E001',
        '未设置开始时间',
        '请先设置待办事项的开始时间再添加到日历。'
      );
    }

    return Event(
      title: title,
      description: '$content\n$description',
      location: location ?? '',
      startDate: deadline!,
      endDate: endTime ?? deadline!.add(estimatedDuration),
      allDay: isAllDay,
      iosParams: IOSParams(
        reminder: Duration(minutes: 30), // 默认提前30分钟提醒
      ),
      androidParams: const AndroidParams(
        emailInvites: [],
      ),
    );
  }

  String? _getRecurrenceRule() {
    switch (repeat) {
      case 'daily':
        return 'FREQ=DAILY';
      case 'weekly':
        return 'FREQ=WEEKLY';
      case 'monthly':
        return 'FREQ=MONTHLY';
      case 'yearly':
        return 'FREQ=YEARLY';
      default:
        return null;
    }
  }
}

// 预定义标签
const List<TodoTag> predefinedTags = [
  TodoTag(
    name: '工作',
    icon: Icons.work,
    color: Colors.blue,
  ),
  TodoTag(
    name: '生活',
    icon: Icons.home,
    color: Colors.green,
  ),
  TodoTag(
    name: '学习',
    icon: Icons.school,
    color: Colors.orange,
  ),
  TodoTag(
    name: '重要',
    icon: Icons.star,
    color: Colors.red,
  ),
]; 