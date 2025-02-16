import Flutter
import UIKit
import EventKit

// 添加 RemindersPlugin 类定义
@objc class RemindersPlugin: NSObject {
    private let store = EKEventStore()
    
    @objc func addReminder(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        
        store.requestAccess(to: .reminder) { [weak self] granted, error in
            guard granted else {
                result(FlutterError(
                    code: "PERMISSION_DENIED",
                    message: "Permission denied",
                    details: error?.localizedDescription
                ))
                return
            }
            
            self?.createReminder(args, result: result)
        }
    }
    
    private func createReminder(_ args: [String: Any], result: @escaping FlutterResult) {
        let reminder = EKReminder(eventStore: store)
        reminder.title = args["title"] as? String
        reminder.notes = args["notes"] as? String
        reminder.calendar = store.defaultCalendarForNewReminders()
        
        // 设置截止日期
        if let dueDate = args["dueDate"] as? Int {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: Date(timeIntervalSince1970: TimeInterval(dueDate / 1000))
            )
        }
        
        // 设置优先级
        if let priority = args["priority"] as? Int {
            reminder.priority = priority
        }
        
        // 设置提醒
        if let alarmDate = args["alarmDate"] as? Int {
            let alarm = EKAlarm(absoluteDate: Date(timeIntervalSince1970: TimeInterval(alarmDate / 1000)))
            reminder.addAlarm(alarm)
        }
        
        do {
            try store.save(reminder, commit: true)
            result(true)
        } catch {
            result(FlutterError(
                code: "SAVE_FAILED",
                message: "Failed to save reminder",
                details: error.localizedDescription
            ))
        }
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let remindersChannel = FlutterMethodChannel(
      name: "com.example.todo_list/reminders",
      binaryMessenger: controller.binaryMessenger
    )
    
    let remindersPlugin = RemindersPlugin()
    remindersChannel.setMethodCallHandler { call, result in
      if call.method == "addReminder" {
        remindersPlugin.addReminder(call, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
