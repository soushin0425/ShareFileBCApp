//
//  ShareFileBCtestApp.swift
//  ShareFileBCtest
//
//  Created by 古賀創臣 on 2025/03/08.
//

import SwiftUI
import GoogleSignIn

@main
struct ShareFileBCApp: App {
    @StateObject var driveManager = DriveManager.shared // DriveManager を初期化
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
            //外部アプリ(Safariなど)からのリダイレクトを受け取る
                .onOpenURL{ url in
                    print(url)
                    GIDSignIn.sharedInstance.handle(url)
                }
            //以前のログイン情報があれば、自動的にログインを復元
                .onAppear{
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        if let error = error {
                            print("ログイン復元失敗: \(error.localizedDescription)")
                        } else if let user = user {
                            print("ログイン復元成功: \(user.profile?.name ?? "Unknown")")
                            
                            // ★ ログイン復元後にルートフォルダの取得・作成
                            driveManager.getOrCreateFolder(named: "ShareFileBCApp", parentID: nil) { folderID in
                                guard let folderID = folderID else {
                                    print("ルートフォルダの作成に失敗しました")
                                    return
                                }
                                driveManager.rootFolderID = folderID
                                print("rootFolderIDの確認：\(driveManager.rootFolderID!)")
                                print("アプリ起動時のルートフォルダのID取得成功: \(folderID)")
                                driveManager.isSignedIn = true
//                                driveManager.getList(folderID: driveManager.rootFolderID) {
//                                    DispatchQueue.main.async {
//                                        print("共有相手リスト取得完了")
//                                        driveManager.isSignedIn = true
//                                    }
//                                }
                            }
                            //driveManager.getOrCreateFolderの処理は非同期であるため、この処理が終わる前にdriveManager.getListが実行されるため、外に定義したらうまくいかない
                        }
                    }
                }
            }
        }
    }
