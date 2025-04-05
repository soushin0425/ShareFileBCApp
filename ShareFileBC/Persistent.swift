//
//  Persistent.swift
//  ShareFileBC
//
//  Created by 古賀創臣 on 2025/03/18.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController() // シングルトン（アプリ全体で1つのインスタンス）
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "ShareFileBC")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error)")
            }
        })
    }
}
