//
//  AppDelegate.swift
//  knockknock
//
//  Created by zhangwei on 2020/5/17.
//  Copyright © 2020 CodesPaper. All rights reserved.
//

import Cocoa
import SwiftUI
import Swifter
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    @IBOutlet weak var menu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    @IBOutlet weak var quitApp: NSMenuItem!
    @IBAction func quitApp(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that) provides the window contents.
        statusItem.menu = menu
        
        if let button = statusItem.button {
            button.image = NSImage(named: "StatusIcon")
        }
        // Create the window and set the content view.
        
        DispatchQueue.global().async {
            self.newServer()
        }
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                print("Yay!")
            } else {
                print("D'oh")
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    struct NotiRequest: Decodable {
        let title: String
        let password: String?
        // let category: Category
        let content: String?
    }
    enum Error: Int, Codable {
        case ok = 0
    }
    struct NotiResponse: Codable {
        let error: Error
        let from: String
    }
    
    func scheduleNotification(_ title: String, _ sub: String, _ body: String) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = sub
        content.body = body
        content.categoryIdentifier = "alarm"
        content.userInfo = ["creator": "codespaper"]
        content.sound = UNNotificationSound.default
        // content.launchImageName = ""

        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 30
        // let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
    }
    
    func newServer() -> Void {
        let server = HttpServer()
        server.POST["/knock"] = { request in
            let data = Data(request.body)
            let decoder = JSONDecoder()

            let object = try! decoder.decode(NotiRequest.self, from: data)
            
            self.scheduleNotification(object.title, request.address ?? "no addr", object.content ?? "")
            return .ok(.text("{\"error\": 0, \"from\": \"\(request.address ?? "")\"}"))
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        do {
          try server.start(5091, forceIPv4: true)
          print("Server has started ( port = \(try server.port()) ). Try to connect now...")
          semaphore.wait()
        } catch {
          print("Server start error: \(error)")
          semaphore.signal()
        }
    }
    
    
}

