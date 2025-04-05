//
//  FileListView.swift
//  ShareFileBC
//
//  Created by 古賀創臣 on 2025/03/21.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct FileListView: View {
    @State private var isLoading = false  // ロード中かどうか
    @StateObject var driveManager = DriveManager.shared
    var currentFolderIDForDownload: String
    
    //ファイルorフォルダを取得する関数
    private func loadFiles() {
        isLoading = true

        let folderID = currentFolderIDForDownload  // そのまま代入
        driveManager.getPublicFilesList(folderID: folderID) {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    func downloadFile(fileID: String, fileName: String, mimeType: String) {
        // ファイルをダウンロードする処理を呼び出す
        driveManager.downloadFile(fileID: fileID) { data, error in
            guard let data = data else {
                print("ダウンロード失敗: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            print("ファイル名:\(fileName)")
            print("mime:\(mimeType)")
            // ダウンロード成功後にユーザーに保存場所を選ばせる
            presentDocumentPicker(for: data, fileName: fileName, mimeType: mimeType)
        }
    }
    
    //MIMEタイプから拡張子を取得する関数
    func getFileExtension(from mimeType: String) -> String? {
        // MIMEタイプからUTTypeを取得
        if let utType = UTType(mimeType: mimeType) {
            // UTTypeから拡張子を取得
            return utType.preferredFilenameExtension
        }
        return nil
    }
    
    func presentDocumentPicker(for data: Data, fileName: String, mimeType: String) {
        // 現在のウィンドウシーンを取得
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let viewController = windowScene.windows.first?.rootViewController {
                
                // MIMEタイプから拡張子を取得
                guard let fileExtension = getFileExtension(from: mimeType) else {
                    print("拡張子の取得に失敗しました。")
                    return
                }
                
                var finalFileName = fileName
                if !fileName.lowercased().hasSuffix(fileExtension) {
                    finalFileName += ".\(fileExtension)"
                }
                
                // 一時ファイルを保存
                let temporaryDirectory = FileManager.default.temporaryDirectory
                let fileURL = temporaryDirectory.appendingPathComponent(finalFileName)
                
                do {
                    try data.write(to: fileURL)
                    
                    // Document Pickerのdelegateを設定
                    let delegate = FileStoreDelegate(data: data, fileName: finalFileName) { url in
                        // ファイル保存が成功した場合
                        print("ファイルが保存されました: \(url.path)")
                    }

                    let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
                    documentPicker.delegate = delegate
                    documentPicker.allowsMultipleSelection = false

                    // ドキュメントピッカーを表示
                    viewController.present(documentPicker, animated: true, completion: nil)
                    
                } catch {
                    print("一時ファイルの保存に失敗しました: \(error.localizedDescription)")
                }
            }
        }
    }


    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                List(driveManager.FileList, id: \.id) { file in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(file.filename)
                                .font(.headline)
                            Text(file.mimeType)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: {
                            downloadFile(fileID: file.id, fileName: file.filename, mimeType: file.mimeType)
                        }) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadFiles()
        }
        .navigationTitle("ファイル一覧")
    }
}

//#Preview {
//    FileListView()
//}
