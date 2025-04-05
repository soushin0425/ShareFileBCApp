//
//  FilePickerDelegate.swift
//  ShareFileBCtest
//
//  Created by 古賀創臣 on 2025/03/15.
//

import UIKit

// ファイルアプリでの処理を記述するクラス
class FilePickerDelegate: NSObject, UIDocumentPickerDelegate {
    // クラスのインスタンスを1つだけ作成し、アプリ内で再利用される（シングルトン）
    static let shared = FilePickerDelegate()
    
    var driveManager = DriveManager.shared
    var mailerManager = MailerManager.shared
    
    // UIDocumentPickerDelegateプロトコルで定義されている
    // ファイル選択後に呼び出される
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("選択したファイル: \(urls.first?.absoluteString ?? "なし")")
        guard let fileURL = urls.first else { return }
        
        // 選択したファイルの情報を取得
        let fileName = fileURL.lastPathComponent
        guard let fileData = try? Data(contentsOf: fileURL) else { return }
        let mimeType = "application/octet-stream" // 必要に応じてMIMEタイプを変更
        
        //共有日付を設定
        let shareDate = getCurrentDate() // 現在の日付を取得する関数を呼び出す
        
        // ファイルをアップロード（userNameとshareDateを渡す）
        driveManager.uploadFile(fileName: fileName, fileData: fileData, mimeType: mimeType, shareDate: shareDate, userFolderID: driveManager.currentFolderID!)
        
        // Gmailを開く
        mailerManager.openGmail(to: mailerManager.email, subject: mailerManager.subject, body: mailerManager.body)
        //iOSメールアプリを開く
        //mailerManager.openMail(to: mailerManager.email, subject: mailerManager.subject, body: mailerManager.body)
        
    }
    
    // ファイル選択をキャンセルした場合に呼ばれる
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("ファイル選択がキャンセルされました")
        // Gmailは開かないので何もしない
    }
    
    // 現在の日付を取得する関数
    private func getCurrentDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: Date())
    }
}
