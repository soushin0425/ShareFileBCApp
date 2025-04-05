//
//  ContentView.swift
//  ShareFileBCtest
//
//  Created by 古賀創臣 on 2025/03/08.
//


import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import GoogleAPIClientForREST_Drive
import UniformTypeIdentifiers
import CoreData

struct ContentView: View {
    
    @StateObject var driveManager = DriveManager.shared
    // タブの選択項目を保持する
    @State var selection = 1
    @State var folderID: String = ""
    
    func handleIncomingURL(_ url: URL) {
        guard url.scheme == "sharefilebcapp",
              url.host == "folder",
              let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems,
              let folderID = queryItems.first(where: { $0.name == "folderID" })?.value else {
            return
        }

        driveManager.folderIDForDownload = folderID // `folderID` を保存
        selection = 2 // `FileDownloadView` のタブへ移動
    }
    
    //画面の表示
    var body: some View {
//        NavigationView {
//            if driveManager.isSignedIn {
//                TabView(selection: $selection) {
//                    HomeView() //ログイン後にホーム画面を表示
//                        .tabItem {
//                            Label("Page1", systemImage: "1.circle")
//                        }
//                        .tag(1)
//                    
//
//                    FileDownloadView() // ファイルダウンロード画面
//                        .tabItem {
//                            Label("Page2", systemImage: "2.circle")
//                        }
//                        .tag(2)
//                }
//            } else {
//                LoginView() //ログイン画面を表示
//            }
//        }
        NavigationView {
            if driveManager.isSignedIn {
                TabView(selection: $selection) {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }
                        .tag(1)

                    FileDownloadView()
                        .tabItem {
                            Label("Download", systemImage: "arrow.down.circle")
                        }
                        .tag(2)
//                    TestView()
//                        .tabItem {
//                            Label("Test", systemImage: "arrow.down.circle")
//                        }
//                        .tag(3)
                }
            } else {
                LoginView()
            }
        }
        .onOpenURL { url in
            handleIncomingURL(url)
        }
    }
}

#Preview {
    ContentView()
}

