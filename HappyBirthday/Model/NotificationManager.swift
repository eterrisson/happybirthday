//
//  NotificationManager.swift
//  HappyBirthday
//
//  Created by Eric Terrisson on 10/05/2024.
//

import Foundation
import UserNotifications

class NotificationManager {

    var isPermited: Bool // user permission

    init() {
        if UserDefaults.standard.object(forKey: "UserLocalNotificationPermission") != nil {
            let permission = UserDefaults.standard.bool(forKey: "UserLocalNotificationPermission")
            self.isPermited = permission
        } else {
            self.isPermited = false
            self.askPermission()
        }
    }

    /// Ask user permission to use local notifications
    private func askPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("All set!")
                // Save the choice
                self.isPermited = true
                UserDefaults.standard.set(true, forKey: "UserLocalNotificationPermission")
            } else if let error {
                self.isPermited = false
                print(error.localizedDescription)
            } else {
                // user refused permission
                self.isPermited = false
                UserDefaults.standard.set(false, forKey: "UserLocalNotificationPermission")
            }
        }
    }

    /// Add local notification
    func addLocalNotification(birthday: Birthday) {
        if isPermited {
            print("Adding notification")
            let content = UNMutableNotificationContent()
            if let birthDate = birthday.birth {
                let age = calculateAge(birthDate: birthDate)
                content.title = "\(birthday.firstName!) \(birthday.firstName!) a \(age) ans !"
                content.subtitle = "Fêtez lui son anniversaire 🥳"
                content.sound = UNNotificationSound.default

                // specific
                var dateComponents = Calendar.current.dateComponents([.month, .day], from: birthDate)
                dateComponents.hour = 10
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

                // choose a random identifier
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                // add our notification request
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    private func calculateAge(birthDate: Date) -> Int {
        let calendar = Calendar.current
        let currentDate = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: currentDate)
        return ageComponents.year!
    }
}
