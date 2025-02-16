import 'package:flutter/material.dart';

class ContentEditPage extends StatefulWidget {
  final String initialContent;

  const ContentEditPage({
    super.key,
    required this.initialContent,
  });

  @override
  State<ContentEditPage> createState() => _ContentEditPageState();
}

class _ContentEditPageState extends State<ContentEditPage> {
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B8DE3),
        title: const Text(
          '编辑内容',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_contentController.text);
            },
            child: const Text(
              '保存',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _contentController,
          maxLines: null,
          expands: true,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
          decoration: const InputDecoration(
            hintText: '在此输入内容...',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
} 