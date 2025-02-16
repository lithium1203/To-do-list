import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'add_todo_page.dart';
import 'todo_detail_page.dart';
import 'content_edit_page.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'config.dart';
import 'widgets/ai_assistant_dialog.dart';
import 'package:flutter/rendering.dart';
import 'models/todo_item.dart';
import 'exceptions/calendar_exception.dart';
import 'services/reminders_service.dart';

/**
 * 程序入口
 */
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置首选方向
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const MyApp());
}

/**
 * 应用程序根组件
 */
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '待办事项',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B8DE3),
          primary: const Color(0xFF6B8DE3),
          secondary: const Color(0xFF7EB6FF),
        ),
        useMaterial3: true,
        // 自定义卡片主题
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        // 自定义输入框主题
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6B8DE3), width: 2),
          ),
        ),
        // 自定义按钮主题
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      home: const TodoListPage(title: '我的待办'),
    );
  }
}

/**
 * 待办事项页面
 */
class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key, required this.title});

  final String title;

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final List<TodoItem> _todoItems = [];
  final TextEditingController _textController = TextEditingController();
  DateTime? _selectedDateTime;
  String _readmeContent = '';
  bool _isSelectionMode = false;
  final Set<int> _selectedIndexes = <int>{};

  @override
  void initState() {
    super.initState();
    _loadTodoItems();
    _loadReadme();
  }

  /**
   * 加载待办事项
   */
  Future<void> _loadTodoItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todoItemsJson = prefs.getString(AppConfig.storageKeyTodoItems);
    
    if (todoItemsJson != null) {
      final List<dynamic> decodedJson = jsonDecode(todoItemsJson);
      setState(() {
        _todoItems.clear();
        _todoItems.addAll(
          decodedJson.map((item) => TodoItem.fromJson(item as Map<String, dynamic>))
        );
      });
    }
  }

  /**
   * 加载 readme 文件
   */
  Future<void> _loadReadme() async {
    try {
      final String content = await rootBundle.loadString('lib/readme.md');
      setState(() {
        _readmeContent = content.replaceAll(
          'version: 1.0.0',
          'version: ${AppConfig.version}'
        );
      });
    } catch (e) {
      print('Error loading readme: $e');
      _readmeContent = 'Failed to load about information';
    }
  }

  /**
   * 保存待办事项
   */
  Future<void> _saveTodoItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedJson = jsonEncode(
      _todoItems.map((item) => item.toJson()).toList()
    );
    await prefs.setString(AppConfig.storageKeyTodoItems, encodedJson);
  }

  /**
   * 选择日期和时间
   */
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: now,
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF6B8DE3),
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFF6B8DE3),
                surface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  /**
   * 检查是否存在重复事项
   */
  bool _isDuplicate(String title) {
    return _todoItems.any((item) => item.title.toLowerCase() == title.toLowerCase());
  }

  /**
   * 添加新的待办事项
   */
  void _addTodoItem(TodoItem item) {
    if (_isDuplicate(item.title)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('提示'),
          content: const Text('已存在相同的待办事项'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _todoItems.add(item);
    });
    _saveTodoItems(); // 保存更改
  }

  /**
   * 编辑待办事项的截止时间
   */
  Future<void> _editDeadline(int index) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _todoItems[index].deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_todoItems[index].deadline ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _todoItems[index].deadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
        _saveTodoItems(); // 保存更改
      }
    }
  }

  /**
   * 切换待办事项状态
   */
  void _toggleTodoItem(TodoItem item) {
    setState(() {
      item.isDone = !item.isDone;
    });
    _saveTodoItems();
  }

  /**
   * 删除待办事项
   */
  void _removeTodoItem(int index) {
    setState(() {
      _todoItems.removeAt(index);
    });
    _saveTodoItems(); // 保存更改
  }

  /**
   * 格式化日期时间显示
   */
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未设置时间';
    return '${dateTime.year}-${dateTime.month}-${dateTime.day} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /**
   * 修改紧急度
   */
  void _editUrgency(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改紧急度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UrgencyLevel.values.map((level) {
            final isSelected = _todoItems[index].urgency == level;
            return ListTile(
              leading: Icon(
                Icons.circle,
                color: level.color.withOpacity(0.8),
                size: 16,
              ),
              title: Text(level.label),
              selected: isSelected,
              onTap: () {
                setState(() {
                  _todoItems[index].urgency = level;
                });
                _saveTodoItems(); // 保存更改
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /**
   * 选择提醒时间
   */
  Future<List<Duration>?> _selectReminders(BuildContext context) async {
    final List<Duration> selectedReminders = [];
    
    final result = await showDialog<List<Duration>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置提醒时间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('选择提前提醒的时间：'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ReminderChip(
                  label: '准时',
                  duration: Duration.zero,
                  selectedReminders: selectedReminders,
                ),
                _ReminderChip(
                  label: '5分钟',
                  duration: const Duration(minutes: 5),
                  selectedReminders: selectedReminders,
                ),
                _ReminderChip(
                  label: '15分钟',
                  duration: const Duration(minutes: 15),
                  selectedReminders: selectedReminders,
                ),
                _ReminderChip(
                  label: '30分钟',
                  duration: const Duration(minutes: 30),
                  selectedReminders: selectedReminders,
                ),
                _ReminderChip(
                  label: '1小时',
                  duration: const Duration(hours: 1),
                  selectedReminders: selectedReminders,
                ),
                _ReminderChip(
                  label: '2小时',
                  duration: const Duration(hours: 2),
                  selectedReminders: selectedReminders,
                ),
                _ReminderChip(
                  label: '1天',
                  duration: const Duration(days: 1),
                  selectedReminders: selectedReminders,
                ),
                _ReminderChip(
                  label: '2天',
                  duration: const Duration(days: 2),
                  selectedReminders: selectedReminders,
                ),
                _ReminderChip(
                  label: '1周',
                  duration: const Duration(days: 7),
                  selectedReminders: selectedReminders,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(selectedReminders);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    return result;
  }

  /**
   * 添加到日历
   */
  Future<void> _addToCalendar(TodoItem item) async {
    if (item.deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先设置开始时间')),
      );
      return;
    }

    final reminders = await _selectReminders(context);
    if (reminders == null) return; // 用户取消了选择

    final event = Event(
      title: item.title,
      description: item.content,
      location: '',
      startDate: item.deadline!,
      endDate: item.endTime ?? item.deadline!.add(const Duration(hours: 1)),
      allDay: item.isAllDay,
      iosParams: IOSParams(
        reminder: reminders.isEmpty ? null : reminders.first,
      ),
      androidParams: const AndroidParams(
        emailInvites: [],
      ),
    );

    final success = await Add2Calendar.addEvent2Cal(event);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已添加到日历')),
      );
    }
  }

  /**
   * 编辑事项详细设置
   */
  Future<void> _editEventDetails(TodoItem item) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EventDetailsSheet(item: item),
    );

    if (result != null && mounted) {
      setState(() {
        item.isAllDay = result['isAllDay'] as bool;
        item.deadline = result['startDate'] as DateTime?;
        item.endTime = result['endDate'] as DateTime?;
        item.repeat = result['repeat'] as String;
      });
      _saveTodoItems();
    }
  }

  /**
   * 导出到日历
   */
  Future<void> _exportToCalendar(TodoItem item) async {
    try {
      final event = item.toCalendarEvent();
      final success = await Add2Calendar.addEvent2Cal(event);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已成功添加到系统日历'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showErrorDialog(
          'E002',
          '添加失败',
          '无法添加到系统日历，请检查日历权限设置。'
        );
      }
    } on CalendarException catch (e) {
      _showErrorDialog(e.code, e.message, e.details);
    } catch (e) {
      _showErrorDialog(
        'E999',
        '未知错误',
        '添加到日历时发生错误：$e'
      );
    }
  }

  /**
   * 导出到提醒事项
   */
  Future<void> _exportToReminders(TodoItem item) async {
    try {
      final success = await RemindersService.addToReminders(item);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已成功添加到系统提醒事项'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on RemindersException catch (e) {
      _showErrorDialog(e.code, e.message, e.details);
    } catch (e) {
      _showErrorDialog(
        'E999',
        '未知错误',
        '添加到提醒事项时发生错误：$e'
      );
    }
  }

  void _showErrorDialog(String code, String message, [String? details]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text('错误 $code'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /**
   * 显示操作菜单
   */
  void _showActionMenu(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ...ListTile.divideTiles(
              context: context,
              tiles: [
                _buildActionTile(
                  icon: Icons.flag,
                  title: '修改紧急度',
                  subtitle: _todoItems[index].urgency.label,
                  subtitleColor: _todoItems[index].urgency.color,
                  onTap: () {
                    Navigator.pop(context);
                    _editUrgency(index);
                  },
                ),
                _buildActionTile(
                  icon: Icons.access_time,
                  title: '修改时间',
                  onTap: () {
                    Navigator.pop(context);
                    _editDeadline(index);
                  },
                ),
                _buildActionTile(
                  icon: Icons.label,
                  title: '修改标签',
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddTodoPage.editTags(
                          tags: _todoItems[index].tags,
                        ),
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() {
                        _todoItems[index].tags = result['tags'] as List<TodoTag>;
                      });
                      _saveTodoItems(); // 保存更改
                    }
                  },
                ),
                _buildActionTile(
                  icon: Icons.calendar_today,
                  title: '添加到日历',
                  onTap: () {
                    Navigator.pop(context);
                    _addToCalendar(_todoItems[index]);
                  },
                ),
                _buildActionTile(
                  icon: Icons.edit,
                  title: '编辑详细设置',
                  onTap: () {
                    Navigator.pop(context);
                    _editEventDetails(_todoItems[index]);
                  },
                ),
                _buildActionTile(
                  icon: Icons.calendar_today,
                  title: '添加到系统日历',
                  onTap: () {
                    Navigator.pop(context);
                    _exportToCalendar(_todoItems[index]);
                  },
                ),
                _buildActionTile(
                  icon: Icons.notifications,
                  title: '添加到提醒事项',
                  onTap: () {
                    Navigator.pop(context);
                    _exportToReminders(_todoItems[index]);
                  },
                ),
                _buildActionTile(
                  icon: Icons.delete,
                  title: '删除',
                  onTap: () {
                    Navigator.pop(context);
                    _removeTodoItem(index);
                  },
                ),
              ],
            ).toList(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? subtitleColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF6B8DE3)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: subtitleColor ?? Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /**
   * 对待办事项进行排序
   */
  List<TodoItem> _getSortedItems() {
    final items = List<TodoItem>.from(_todoItems);
    items.sort((a, b) {
      // 首先按紧急度排序（非常紧急 > 紧急 > 普通）
      final urgencyComparison = b.urgency.index.compareTo(a.urgency.index);
      if (urgencyComparison != 0) return urgencyComparison;
      
      // 紧急度相同时，按截止时间排序
      if (a.deadline == null && b.deadline == null) return 0;
      if (a.deadline == null) return 1; // 没有截止时间的排在后面
      if (b.deadline == null) return -1;
      
      // 比较截止时间
      final timeComparison = a.deadline!.compareTo(b.deadline!);
      if (timeComparison != 0) return timeComparison;
      
      // 如果截止时间也相同，保持原有顺序
      return 0;
    });
    return items;
  }

  // 添加多选操作栏
  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF6B8DE3),
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () {
          setState(() {
            _isSelectionMode = false;
            _selectedIndexes.clear();
          });
        },
      ),
      title: Text(
        '已选择 ${_selectedIndexes.length} 项',
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.white),
          onPressed: _selectedIndexes.isEmpty ? null : _exportSelectedToCalendar,
        ),
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: _selectedIndexes.isEmpty ? null : _exportSelectedToReminders,
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.white),
          onPressed: _selectedIndexes.isEmpty ? null : _deleteSelectedItems,
        ),
      ],
    );
  }

  // 导出选中项到日历
  Future<void> _exportSelectedToCalendar() async {
    final items = _selectedIndexes.map((index) => _todoItems[index]).toList();
    for (final item in items) {
      await _exportToCalendar(item);
    }
    setState(() {
      _isSelectionMode = false;
      _selectedIndexes.clear();
    });
  }

  // 导出选中项到提醒事项
  Future<void> _exportSelectedToReminders() async {
    final items = _selectedIndexes.map((index) => _todoItems[index]).toList();
    for (final item in items) {
      await _exportToReminders(item);
    }
    setState(() {
      _isSelectionMode = false;
      _selectedIndexes.clear();
    });
  }

  // 删除选中项
  void _deleteSelectedItems() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedIndexes.length} 个待办事项吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                final sortedIndexes = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));
                for (final index in sortedIndexes) {
                  _todoItems.removeAt(index);
                }
                _isSelectionMode = false;
                _selectedIndexes.clear();
              });
              _saveTodoItems();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedItems = _getSortedItems();
    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AIAssistantDialog(
                  onTodoCreated: (todoItem) {
                    setState(() {
                      _todoItems.add(todoItem);
                    });
                    _saveTodoItems();
                  },
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'about') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('关于'),
                    content: SingleChildScrollView(
                      child: Text(_readmeContent),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('关闭'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF6B8DE3)),
                    SizedBox(width: 8),
                    Text('关于'),
                  ],
                ),
              ),
            ],
          ),
        ],
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F4FF),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedItems.length,
          itemBuilder: (context, index) {
            final item = sortedItems[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onLongPress: () {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedIndexes.add(index);
                  });
                },
                onTap: _isSelectionMode
                    ? () {
                        setState(() {
                          if (_selectedIndexes.contains(index)) {
                            _selectedIndexes.remove(index);
                            if (_selectedIndexes.isEmpty) {
                              _isSelectionMode = false;
                            }
                          } else {
                            _selectedIndexes.add(index);
                          }
                        });
                      }
                    : () => _showActionMenu(context, index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      if (_isSelectionMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            _selectedIndexes.contains(index)
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: const Color(0xFF6B8DE3),
                          ),
                        )
                      else
                        Material(
                          type: MaterialType.transparency,
                          child: Checkbox(
                            value: item.isDone,
                            onChanged: (bool? value) {
                              _toggleTodoItem(item);
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        decoration: item.isDone
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: item.isDone
                                            ? Colors.grey
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (item.urgency != UrgencyLevel.normal)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.urgency.color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        item.urgency.label,
                                        style: TextStyle(
                                          color: item.urgency.color,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (item.tags.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: item.tags.map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
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
                                      );
                                    }).toList(),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: item.deadline != null &&
                                              item.deadline!.isBefore(DateTime.now())
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDateTime(item.deadline),
                                      style: TextStyle(
                                        color: item.deadline != null &&
                                                item.deadline!.isBefore(DateTime.now())
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!_isSelectionMode)
                        Material(
                          type: MaterialType.transparency,
                          child: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showActionMenu(context, index),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTodoPage()),
          );
          
          if (result != null && mounted) {
            final title = result['title'] as String;
            final deadline = result['deadline'] as DateTime?;
            final tags = result['tags'] as List<TodoTag>;
            final urgency = result['urgency'] as UrgencyLevel;  // 获取紧急度
            
            if (_isDuplicate(title)) {
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('提示'),
                    content: const Text('已存在相同的待办事项'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
              }
              return;
            }
            
            setState(() {
              _todoItems.add(TodoItem(
                title: title,
                deadline: deadline,
                tags: tags,
                urgency: urgency,  // 设置紧急度
              ));
            });
            _saveTodoItems(); // 保存更改
          }
        },
        backgroundColor: const Color(0xFF6B8DE3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

/**
 * 提醒时间选择组件
 */
class _ReminderChip extends StatefulWidget {
  final String label;
  final Duration duration;
  final List<Duration> selectedReminders;

  const _ReminderChip({
    required this.label,
    required this.duration,
    required this.selectedReminders,
  });

  @override
  State<_ReminderChip> createState() => _ReminderChipState();
}

class _ReminderChipState extends State<_ReminderChip> {
  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedReminders.contains(widget.duration);

    return FilterChip(
      label: Text(widget.label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            widget.selectedReminders.add(widget.duration);
            // 按时间从大到小排序
            widget.selectedReminders.sort((a, b) => b.compareTo(a));
          } else {
            widget.selectedReminders.remove(widget.duration);
          }
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: const Color(0xFF6B8DE3).withOpacity(0.2),
      checkmarkColor: const Color(0xFF6B8DE3),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF6B8DE3) : Colors.black87,
      ),
    );
  }
}

// 创建新的事项详细设置页面组件
class EventDetailsSheet extends StatefulWidget {
  final TodoItem item;

  const EventDetailsSheet({
    super.key,
    required this.item,
  });

  @override
  State<EventDetailsSheet> createState() => _EventDetailsSheetState();
}

class _EventDetailsSheetState extends State<EventDetailsSheet> {
  late bool _isAllDay;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late String _repeat;

  @override
  void initState() {
    super.initState();
    _isAllDay = widget.item.isAllDay;
    _startDate = widget.item.deadline;
    _endDate = widget.item.endTime;
    _repeat = widget.item.repeat;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 全天事项开关
          SwitchListTile(
            title: const Text('全天'),
            value: _isAllDay,
            onChanged: (value) {
              setState(() {
                _isAllDay = value;
              });
            },
          ),
          // 开始时间选择
          ListTile(
            title: const Text('开始时间'),
            subtitle: Text(_startDate == null ? '未设置' : 
              _formatDateTime(_startDate!, _isAllDay)),
            onTap: () => _selectDateTime(true),
          ),
          // 结束时间选择
          ListTile(
            title: const Text('结束时间'),
            subtitle: Text(_endDate == null ? '未设置' : 
              _formatDateTime(_endDate!, _isAllDay)),
            onTap: () => _selectDateTime(false),
          ),
          // 重复选项
          ListTile(
            title: const Text('重复'),
            subtitle: Text(_getRepeatText(_repeat)),
            onTap: _selectRepeat,
          ),
          // 保存按钮
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'isAllDay': _isAllDay,
                'startDate': _startDate,
                'endDate': _endDate,
                'repeat': _repeat,
              });
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime, bool isAllDay) {
    if (isAllDay) {
      return '${dateTime.year}-${dateTime.month}-${dateTime.day}';
    }
    return '${dateTime.year}-${dateTime.month}-${dateTime.day} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getRepeatText(String repeat) {
    switch (repeat) {
      case 'never': return '从不';
      case 'daily': return '每天';
      case 'weekly': return '每周';
      case 'monthly': return '每月';
      case 'yearly': return '每年';
      default: return '从不';
    }
  }

  Future<void> _selectDateTime(bool isStart) async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate ?? now : _endDate ?? now,
      firstDate: now,
      lastDate: DateTime(2101),
    );

    if (date != null && !_isAllDay) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isStart ? _startDate ?? now : _endDate ?? now,
        ),
      );

      if (time != null) {
        setState(() {
          final newDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          if (isStart) {
            _startDate = newDateTime;
            if (_endDate == null || _endDate!.isBefore(newDateTime)) {
              _endDate = newDateTime.add(const Duration(hours: 1));
            }
          } else {
            _endDate = newDateTime;
          }
        });
      }
    } else if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = DateTime(date.year, date.month, date.day);
          if (_endDate == null || _endDate!.isBefore(_startDate!)) {
            _endDate = DateTime(date.year, date.month, date.day, 23, 59);
          }
        } else {
          _endDate = DateTime(date.year, date.month, date.day, 23, 59);
        }
      });
    }
  }

  Future<void> _selectRepeat() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('重复'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'never'),
            child: const Text('从不'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'daily'),
            child: const Text('每天'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'weekly'),
            child: const Text('每周'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'monthly'),
            child: const Text('每月'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'yearly'),
            child: const Text('每年'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _repeat = result;
      });
    }
  }
} 