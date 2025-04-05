//
//  FileDownloadView.swift
//  ShareFileBC
//
//  Created by 古賀創臣 on 2025/03/21.
//

import SwiftUI
//
//struct FileDownloadView: View {
//    @State private var isLoading = false  // ロード中かどうか
//    @StateObject var driveManager = DriveManager.shared
//    
//    //ファイルorフォルダを取得する関数
//    private func loadFiles() {
//        isLoading = true
//        driveManager.getList(folderID: driveManager.folderIDForDownload) {
//            DispatchQueue.main.async {
//                self.isLoading = false
//            }
//        }
//    }
//        
//    var body: some View {
//        NavigationView {
//            VStack {
//                if isLoading {
//                    ProgressView("Loading...")
//                        .progressViewStyle(CircularProgressViewStyle())
//                } else {
//                    List(driveManager.FileList, id: \.id) { folder in
//                        NavigationLink(
//                            destination: FileListView(currentFolderIDForDownload: folder.id), // ファイル一覧画面に遷移
//                            label: {
//                                VStack(alignment: .leading) {
//                                    Text(folder.filename)
//                                        .font(.headline)
//                                    Text(folder.mimeType)
//                                        .font(.subheadline)
//                                        .foregroundColor(.gray)
//                                }
//                            })
//                    }
//                }
//            }
//            .onAppear {
//                loadFiles()
//            }
//}
//    }
//}
//
//#Preview {
//    FileDownloadView()
//}

struct FileDownloadView: View {
    @State private var isLoading = false  // ロード中かどうか
    @StateObject var driveManager = DriveManager.shared
    
    // ファイルまたはフォルダを取得する関数
    private func loadFiles() {
        isLoading = true
        
        guard let folderID = driveManager.folderIDForDownload else {
            print("Error: folderIDForDownload is nil")  // デバッグ用ログ
            isLoading = false
            return
        }

        driveManager.getPublicFilesList(folderID: folderID) {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
        
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if driveManager.FileList.isEmpty {
                    // ファイルリストが空のときにメッセージを表示
                    Text("共有されているファイルはありません")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(driveManager.FileList, id: \.id) { folder in
                        NavigationLink(
                            destination: FileListView(currentFolderIDForDownload: folder.id), // ファイル一覧画面に遷移
                            label: {
                                VStack(alignment: .leading) {
                                    Text(folder.filename)
                                        .font(.headline)
                                    Text(folder.mimeType)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            })
                    }
                }
            }
            .onAppear {
                loadFiles()
            }
        }
    }
}
