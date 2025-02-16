import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/todo_item.dart';
import 'package:flutter/material.dart';


String extractTitle(String line) {
  final match = RegExp(r'[.、]\s*(.+?)(?=（|\(|$)').firstMatch(line);
  return match?.group(1)?.trim() ?? line.trim();
}

DateTime extractTime(String line) {
  final timeMatch = RegExp(r'(\d{1,2}[:：]\d{2})').firstMatch(line);
  if (timeMatch != null) {
    final timeStr = timeMatch.group(1)?.replaceAll('：', ':') ?? '';
    final now = DateTime.now();
    final parts = timeStr.split(':');
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
  return DateTime.now();
}

Priority extractPriority(String line) {
  if (line.contains('优先级：高') || line.contains('🔥')) {
    return Priority.high;
  }
  if (line.contains('优先级：中')) {
    return Priority.medium;
  }
  return Priority.low;
}

String extractDescription(String line) {
  final match = RegExp(r'[（(](.*?)[）)]').firstMatch(line);
  return match?.group(1) ?? '';
}

String determineCategory(String line) {
  if (line.contains('会议')) return '会议';
  if (line.contains('报告')) return '文档';
  if (line.contains('阅读')) return '学习';
  return '其他';
}

String? extractLocation(String line) {
  final match = RegExp(r'地点[：:]\s*([^，。）)]+)').firstMatch(line);
  return match?.group(1);
}

List<TodoTag> extractTags(String line) {
  final tags = <TodoTag>[];
  

  final emojiRegex = RegExp(r'[\p{Emoji}]', unicode: true);
  final emojis = emojiRegex.allMatches(line).map((m) => m.group(0)!);
  

  for (var emoji in emojis) {
    tags.add(TodoTag(
      name: emoji,
      icon: Icons.label,
      color: Colors.blue,
    ));
  }
  

  final keywords = ['会议', '报告', '阅读', '采购'];
  for (var keyword in keywords) {
    if (line.contains(keyword)) {
      final predefinedTag = predefinedTags.firstWhere(
        (tag) => tag.name == keyword,
        orElse: () => TodoTag(
          name: keyword,
          icon: Icons.label,
          color: Colors.grey,
        ),
      );
      tags.add(predefinedTag);
    }
  }
  
  return tags;
}

String formatDuration(Duration duration) {
  if (duration.inHours > 0) {
    return '${duration.inHours}小时${duration.inMinutes % 60}分钟';
  }
  return '${duration.inMinutes}分钟';
}

String extractPreparations(String description) {
  final items = <String>[];
  final matches = RegExp(r'携带|准备(.*?)(?=。|，|；|$)').allMatches(description);
  for (var match in matches) {
    items.add(match.group(0)!);
  }
  return items.join('、');
}

String formatDateTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

class AIService {
  static Future<List<Map<String, dynamic>>> generateTodoItems(String prompt) async {
    final modelConfig = AppConfig.aiModels[AppConfig.currentAIModel]!;

    try {
      final requestBody = {
        'model': modelConfig.model,
        'messages': [
          {
            'role': 'system',
            'content': modelConfig.systemPrompt ?? '你是一个待办事项助手...',
          },
          {
            'role': 'user',
            'content': '请帮我创建一个待办事项，内容是：$prompt\n'
                '请确保返回的是一个有效的 JSON 对象，包含所有必需字段。',
          }
        ],
        'temperature': modelConfig.temperature,
        'max_tokens': modelConfig.maxTokens,
        'stream': false,
        'top_p': 0.8,
        'presence_penalty': 0,
        'frequency_penalty': 0,
      };

      print('\n=== API 请求开始 ===');
      print('URL: ${modelConfig.apiUrl}');
      print('Headers: ${jsonEncode({
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer ${modelConfig.apiKey.substring(0, 10)}...',
        'X-DashScope-SSE': 'disable',
      })}');
      print('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(modelConfig.apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer ${modelConfig.apiKey}',
          'X-DashScope-SSE': 'disable',
          'Accept-Charset': 'utf-8',
        },
        body: jsonEncode(requestBody),
      );

      print('\n=== API 响应 ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      
      final responseBody = utf8.decode(response.bodyBytes);
      print('Response Body: $responseBody');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        String aiResponse;
        
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          final choice = data['choices'][0];
          if (choice['message'] != null) {
            aiResponse = choice['message']['content'].toString().trim();
            
            try {
              final List<dynamic> jsonResult = jsonDecode(aiResponse);
              return List<Map<String, dynamic>>.from(jsonResult);
            } catch (e) {
              print('\n=== JSON 解析失败，尝试提取 JSON ===');
              final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(aiResponse);
              if (jsonMatch != null) {
                final jsonStr = jsonMatch.group(0)!;
                try {
                  final List<dynamic> extractedJson = jsonDecode(jsonStr);
                  return List<Map<String, dynamic>>.from(extractedJson);
                } catch (e) {
                  throw Exception('提取的 JSON 格式无效: $jsonStr');
                }
              }
              throw Exception('无法从响应中提取有效的 JSON 数组');
            }
          }
        }
      }
      throw Exception('API 响应格式错误');
    } catch (e) {
      throw Exception('AI 服务错误: $e');
    }
  }

  static List<TodoItem> convertToTodoItems(List<Map<String, dynamic>> aiResponses) {
    return aiResponses.map((response) {
      final List<TodoTag> tags = (response['tags'] as List)
          .map((tag) => predefinedTags.firstWhere(
                (predefined) => predefined.name == tag,
                orElse: () => predefinedTags[0],
              ))
          .toList();

      final preparations = (response['preparations'] as List?)?.join('\n') ?? '';

      return TodoItem(
        title: response['title'],
        content: response['content'] ?? '',
        deadline: response['deadline'] != null 
            ? DateTime.parse(response['deadline'])
            : null,
        isAllDay: response['isAllDay'] ?? false,
        tags: tags,
        urgency: UrgencyLevel.values.firstWhere(
          (level) => level.name == response['urgency'],
          orElse: () => UrgencyLevel.normal,
        ),
        dueTime: DateTime.now(),
        estimatedDuration: Duration(minutes: response['estimatedDuration'] as int? ?? 30),
        location: response['location'],
        description: '$preparations\n${response['content'] ?? ''}',
      );
    }).toList();
  }
}


List<TodoItem> analyzeTodoItems(String text) {
  final List<TodoItem> todos = [];
  
  final lines = text.split('\n');
  for (var line in lines) {
    if (line.trim().isEmpty) continue;
    
    final todo = TodoItem(
      title: extractTitle(line),
      dueTime: extractTime(line),
      priority: extractPriority(line),
      description: extractDescription(line),
      estimatedDuration: calculateEstimatedDuration(line),
      category: determineCategory(line),
      location: extractLocation(line),
      tags: extractTags(line)
    );
    
    todos.add(todo);
  }
  
  return todos;
}


Duration calculateEstimatedDuration(String description) {

  if (description.contains('会议')) {
    return Duration(hours: 1);
  }
  if (description.contains('报告') || description.contains('方案')) {
    return Duration(hours: 2);
  }
  if (description.contains('阅读')) {
    return Duration(minutes: 45); 
  }
  // 其他任务默认30分钟
  return Duration(minutes: 30);
}


String generateTaskSummary(TodoItem todo) {
  final buffer = StringBuffer();
  
  buffer.writeln('📝 ${todo.title}');
  buffer.writeln('⏰ 开始时间: ${formatDateTime(todo.dueTime)}');
  
  buffer.writeln('⌛ 预计耗时: ${formatDuration(todo.estimatedDuration)}');
  
  if (todo.priority == Priority.high) {
    buffer.writeln('🔥 优先级: 高');
  }
  
  if (todo.location != null) {
    buffer.writeln('📍 地点: ${todo.location}');
  }
  
  if (todo.tags.isNotEmpty) {
    buffer.writeln('🏷️ 标签: ${todo.tags.join(', ')}');
  }
  
  if (todo.description.contains('携带') || todo.description.contains('准备')) {
    buffer.writeln('📋 注意事项: ${extractPreparations(todo.description)}');
  }
  
  return buffer.toString();
} 