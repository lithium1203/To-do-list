class AppConfig {

  AppConfig._();


  static const String version = '1.0.0';


  static const String developer = 'None';


  static const String appKey = 'your_app_key_here';
  static const String appSecret = 'your_app_secret_here';

  static const bool isDebug = false;  // 是否为调试模式
  static const String apiBaseUrl = 'https://api.example.com'; 

  static const String storageKeyTodoItems = 'todoItems'; 
  static const String storageKeySettings = 'appSettings';  
  

  static const Duration defaultEventDuration = Duration(hours: 1);
  static const Duration defaultReminderTime = Duration(minutes: 30);  


  static const Map<String, AIModelConfig> aiModels = {
    'deepseek-v3': AIModelConfig(
      name: 'Your-model-name',
      apiUrl: 'Your-API-base-url',
      apiKey: 'Your-API-Key',
      model: 'Your-model',
      temperature: 0.7,
      maxTokens: 4000,
      systemPrompt: '''你是一个待办事项助手。请分析用户输入的文本,提取所有待办事项并生成结构化信息。

请将每个待办事项转换为以下格式的 JSON 对象,并返回一个 JSON 数组:
[
  {
    "title": "标题（简短）",
    "content": "详细描述",
    "deadline": "2024-02-15T14:00:00+08:00",
    "isAllDay": false,
    "tags": ["工作"],
    "urgency": "normal",
    "estimatedDuration": 30,
    "location": "地点信息",
    "preparations": ["需要准备的物品1", "需要准备的物品2"]
  },
  // ... 更多待办事项
]

规则说明：
1. 标题：简短明确的描述
2. 内容：详细的任务描述,包括注意事项
3. deadline：必须是 ISO8601 格式,包含时区信息
4. isAllDay：全天事项为 true,特定时间为 false
5. tags：从以下选项中选择最相关的标签：["工作", "学习", "生活", "重要", "娱乐"]
6. urgency：根据优先级和时间紧迫度判断,可选值: normal、urgent、veryUrgent
7. estimatedDuration：预估完成时间(分钟)
8. location：地点信息,如果有的话
9. preparations：需要准备的物品清单

对于每个待办事项,请根据:
1. 任务类型和复杂度评估所需时间
2. 根据描述中的关键词和时间判断紧急程度
3. 根据任务性质选择合适的标签
4. 提取相关的准备事项和地点信息

请确保返回的是一个格式正确的 JSON 数组,不要添加任何额外的文字说明。''',
    ),
  };


  static const String currentAIModel = 'change-to-your-model';
}


class AIModelConfig {
  final String name;       
  final String apiUrl;    
  final String apiKey;    
  final String model;     
  final double temperature;
  final int maxTokens;     
  final String? systemPrompt; 

  const AIModelConfig({
    required this.name,
    required this.apiUrl,
    required this.apiKey,
    required this.model,
    required this.temperature,
    required this.maxTokens,
    this.systemPrompt,
  });
} 