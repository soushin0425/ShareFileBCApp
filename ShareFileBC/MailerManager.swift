//
//  MailerManager.swift
//  ShareFileBC
//
//  Created by 古賀創臣 on 2025/03/20.
//

import Foundation

import UIKit

class MailerManager : ObservableObject {
    // シングルトンインスタンスを取得するための共有インスタンス
    static let shared = MailerManager()
    @Published var email: String = ""
    @Published var subject: String = ""
    @Published var body: String = ""
    
    
    private init() {} // 外部からインスタンス化されないようにする
    
    // Gmailアプリを開く関数
    func openGmail(to email: String, subject: String, body: String) {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let gmailURLString = "googlegmail://co?to=\(email)&subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let gmailURL = URL(string: gmailURLString), UIApplication.shared.canOpenURL(gmailURL) {
            // Gmailアプリがインストールされている場合はGmailアプリを開く
            UIApplication.shared.open(gmailURL)
        } else {
            print("Gmailアプリを開けません")
        }
    }
    
    //iOSのメーラーを開く関数
    func openMail(to email: String, subject: String, body: String) {
        // URLエンコード
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // メールのURLを作成
        let mailURLString = "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)"

        // URLオブジェクトを作成してメールアプリが開けるか確認
        if let mailURL = URL(string: mailURLString), UIApplication.shared.canOpenURL(mailURL) {
            // 既存のメーラーアプリがインストールされていれば開く
            UIApplication.shared.open(mailURL)
        } else {
            print("メールアプリを開けません")
        }
    }
}
