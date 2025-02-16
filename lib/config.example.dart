/**
 * 应用配置示例
 * 使用时请复制此文件为 config.dart 并填入实际的值
 */
class AppConfig {
  AppConfig._();

  static const String version = '1.0.0';
  static const String developer = '：name：';

  // 请替换为实际的密钥
  static const String appKey = 'your_app_key';
  static const String appSecret = 'your_app_secret';

  static const bool isDebug = true;
  static const String apiBaseUrl = 'https://api.example.com';
  
  static const String storageKeyTodoItems = 'todoItems';
  static const String storageKeySettings = 'appSettings';
  
  static const Duration defaultEventDuration = Duration(hours: 1);
  static const Duration defaultReminderTime = Duration(minutes: 30);
} 