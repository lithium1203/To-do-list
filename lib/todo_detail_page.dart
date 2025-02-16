import 'package:flutter/material.dart';
import 'models/todo_item.dart';

class TodoDetailPage extends StatefulWidget {
  final TodoItem item;
  final bool isEditing;

  const TodoDetailPage({
    super.key,
    required this.item,
    this.isEditing = false,
  });

  @override
  State<TodoDetailPage> createState() => _TodoDetailPageState();
}

class _TodoDetailPageState extends State<TodoDetailPage> {
  late bool _isEditing;
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isEditing;
    _titleController = TextEditingController(text: widget.item.title);
    _contentController = TextEditingController(text: widget.item.content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B8DE3),
        title: _isEditing
            ? TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '输入标题',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : Text(
                widget.item.title,
                style: const TextStyle(color: Colors.white),
              ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              if (_isEditing) {
                // 保存更改
                widget.item.title = _titleController.text;
                widget.item.content = _contentController.text;
                Navigator.of(context).pop(true); // 返回 true 表示有更改
              } else {
                // 进入编辑模式
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 标签和时间信息
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (widget.item.urgency != UrgencyLevel.normal)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.item.urgency.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.item.urgency.label,
                      style: TextStyle(
                        color: widget.item.urgency.color,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (widget.item.deadline != null)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: widget.item.deadline!.isBefore(DateTime.now())
                            ? Colors.red
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(widget.item.deadline!),
                        style: TextStyle(
                          color: widget.item.deadline!.isBefore(DateTime.now())
                              ? Colors.red
                              : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // 内容编辑/显示区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isEditing
                  ? TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: '输入内容...',
                        border: InputBorder.none,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        widget.item.content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month}-${dateTime.day} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
} 