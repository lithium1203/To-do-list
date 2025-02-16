import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'main.dart';  // 导入主文件以使用 TodoTag
import 'models/todo_item.dart';  // 添加这个导入

class AddTodoPage extends StatefulWidget {
  final List<TodoTag>? initialTags; // 添加初始标签参数
  final bool isEditingTags; // 是否是编辑标签模式

  const AddTodoPage({super.key})
      : initialTags = null,
        isEditingTags = false;

  // 添加编辑标签的构造函数
  const AddTodoPage.editTags({super.key, required List<TodoTag> tags})
      : initialTags = tags,
        isEditingTags = true;

  @override
  State<AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDateTime;
  final List<TodoTag> _selectedTags = [];  // 选中的标签列表
  final TextEditingController _customTagController = TextEditingController();
  Color _selectedColor = Colors.blue; // 默认颜色
  UrgencyLevel _selectedUrgency = UrgencyLevel.normal;

  @override
  void initState() {
    super.initState();
    if (widget.initialTags != null) {
      _selectedTags.addAll(widget.initialTags!);
    }
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

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未设置时间';
    return '${dateTime.year}-${dateTime.month}-${dateTime.day} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /**
   * 切换标签选择状态
   */
  void _toggleTag(TodoTag tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  /**
   * 显示颜色选择器
   */
  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择颜色'),
        content: SingleChildScrollView(
          child: MaterialPicker(  // 改用 MaterialPicker 更简单直观
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddTagDialog();
            },
            child: const Text('下一步'),
          ),
        ],
      ),
    );
  }

  /**
   * 显示添加标签对话框
   */
  void _showAddTagDialog() {
    _customTagController.clear(); // 清空之前的输入
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建标签'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customTagController,
              decoration: const InputDecoration(
                hintText: '输入标签名称',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Container(
              height: 24,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(12),
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
            onPressed: () {
              if (_customTagController.text.isNotEmpty) {
                final newTag = TodoTag(
                  name: _customTagController.text,
                  color: _selectedColor,
                  icon: Icons.label, // 添加默认图标
                );
                setState(() {
                  _selectedTags.add(newTag);
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B8DE3),
        title: Text(
          widget.isEditingTags ? '编辑标签' : '添加待办事项',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (widget.isEditingTags) {
                Navigator.of(context).pop({
                  'tags': _selectedTags,
                });
              } else if (_titleController.text.isNotEmpty) {
                Navigator.of(context).pop({
                  'title': _titleController.text,
                  'deadline': _selectedDateTime,
                  'tags': _selectedTags,
                  'urgency': _selectedUrgency,
                });
              }
            },
            child: const Text(
              '保存',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isEditingTags) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '标题',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: '输入待办事项标题',
                        filled: true,
                        fillColor: Colors.grey[50],
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
                          borderSide: const BorderSide(color: Color(0xFF6B8DE3)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '紧急度',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: UrgencyLevel.values.map((level) {
                        final isSelected = _selectedUrgency == level;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedUrgency = level;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? level.color.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: isSelected
                                      ? Border.all(color: level.color)
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isSelected)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 4),
                                        child: Icon(
                                          Icons.check,
                                          size: 16,
                                          color: level.color,
                                        ),
                                      ),
                                    Text(
                                      level.label,
                                      style: TextStyle(
                                        color: isSelected ? level.color : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _selectDateTime(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF6B8DE3)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '截止时间',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateTime(_selectedDateTime),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
            ],
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '标签',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showColorPicker,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('新建标签'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6B8DE3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...predefinedTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag.name),
                          selected: isSelected,
                          onSelected: (_) => _toggleTag(tag),
                          backgroundColor: tag.color.withOpacity(0.1),
                          selectedColor: tag.color.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? tag.color : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                          ),
                          checkmarkColor: tag.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      }),
                      ..._selectedTags
                          .where((tag) => !predefinedTags.contains(tag))
                          .map((tag) {
                        return Chip(
                          label: Text(tag.name),
                          backgroundColor: tag.color.withOpacity(0.1),
                          labelStyle: TextStyle(color: tag.color),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _toggleTag(tag),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      }),
                    ],
                  ),
                  if (_selectedTags.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '点击"新建标签"添加自定义标签',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customTagController.dispose();
    super.dispose();
  }
} 