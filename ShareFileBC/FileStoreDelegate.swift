//
//  FileStoreDelegate.swift
//  ShareFileBC
//
//  Created by 古賀創臣 on 2025/03/21.
//

import UIKit

class FileStoreDelegate: NSObject, UIDocumentPickerDelegate {
    var data: Data?
    var fileName: String
    var completion: ((URL) -> Void)?

    init(data: Data, fileName: String, completion: @escaping (URL) -> Void) {
        self.data = data
        self.fileName = fileName
        self.completion = completion
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            do {
                try data?.write(to: url)
                print("ファイルが保存されました: \(url.path)")
                completion?(url)  // 成功時にcompletionを呼び出す
            } catch {
                print("保存に失敗しました: \(error.localizedDescription)")
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("ユーザーがキャンセルしました")
    }
}
