//
//  HomeView.swift
//  ShareFileBCtest
//
//  Created by 古賀創臣 on 2025/03/17.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import GoogleAPIClientForREST_Drive
import UniformTypeIdentifiers

struct HomeView: View {
    @StateObject var driveManager = DriveManager.shared
    @StateObject var mailerManager = MailerManager.shared
    @FocusState private var isFocused: Bool
    @State var userEmail: String = ""
    
    
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(sortDescriptors: [])
    var users: FetchedResults<User>
    
    //ユーザーのデータをCoreDataに保存
    func saveUserInfo(name: String, email: String, folderID: String) {
        let newUser = User(context: viewContext) // CoreData の新しいエンティティを作成
        newUser.name = name
        newUser.email = email
        newUser.folderID = folderID

        do {
            try viewContext.save() // データを保存
            print("ユーザー情報を保存しました: \(name), \(email), \(folderID)")
        } catch {
            print("保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    //ファイルアプリを開く関数
    func selectFileFromFileApp() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.item], asCopy: true)
        //FilePickerDelegateがdocumentPickerの動作を待ち受ける（delegateとは処理を他のオブジェクトに委任すること）
        //ユーザーがdocumentPickerでファイルを選択するとdelegateのメソッドが呼び出される
        documentPicker.delegate = FilePickerDelegate.shared
        //ファイルの複数選択を不可
        documentPicker.allowsMultipleSelection = false

        //現在アプリで動作しているシーンを全て取得→最初のUIWindowSceneのみ取得
        if let viewController = UIApplication.shared.connectedScenes
            .first(where: { $0 is UIWindowScene }) as? UIWindowScene {
            //アプリが起動して最初作成されるウィンドウのコントローラーで遷移の際などの起点となる
            viewController.windows.first?.rootViewController?.present(documentPicker, animated: true)
        }
    }
    
    // キーボードを閉じる処理
    private func hideKeyboard() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.filter { $0.isKeyWindow }.first?.endEditing(true)
        }
    }
    
    //送信相手のフォルダを作成する
    func createUserFolder() {
        guard !driveManager.userName.isEmpty else { return }
        driveManager.getOrCreateFolder(named: driveManager.userName, parentID: driveManager.rootFolderID!) { folderID in
            if let folderID = folderID {
                print("作成されたフォルダのID: \(folderID)")
                
                //ユーザー情報を Core Data に保存
                saveUserInfo(name: driveManager.userName, email: userEmail, folderID: folderID)
                //テキストフィールドの文字を消す
                driveManager.userName = ""
                userEmail = ""
                // フォルダ作成後にリストを更新
//                driveManager.getList(folderID: driveManager.rootFolderID) {
//                    // getList の処理が完了した後の追加処理があればここに書けます
//                    print("リスト更新完了")
//                }
            }
        }
    }

    //画面の表示
    var body: some View {
        ZStack{
            // 画面全体をタップ可能にするための透明な背景
            Color.clear
                .contentShape(Rectangle()) // タップ範囲を拡大
                .onTapGesture {
                    hideKeyboard()
                }
            VStack {
                HStack {
                    Text(GIDSignIn.sharedInstance.currentUser?.profile?.name ?? "非表示")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        GIDSignIn.sharedInstance.signOut()
                        driveManager.update += 1
                        if GIDSignIn.sharedInstance.currentUser == nil {
                            driveManager.isSignedIn = false
                            print("ログアウト成功: 現在ログインしているユーザーは存在しません。")
                        } else {
                            print("ログアウト失敗: ユーザーがまだログインしています。")
                        }
                    }) {
                        Image(systemName: "escape")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.gray)
                            .padding(10)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .padding(.trailing)
                }
                .padding()
                .background(Color(.systemGray6)) // バーの背景色
                .shadow(color: .gray.opacity(0.4), radius: 4, y: 2) // 下部に影をつける
                // 共有相手の名前を入力するテキストフィールド
                Text("共有相手の名前とメールアドレスを入力")
                    .font(.subheadline)
                    .padding(.top)
                TextField("名前を入力", text: $driveManager.userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isFocused)
                    .onTapGesture {
                        // テキストフィールドがタップされたときにフォーカスを当てる
                        isFocused = true
                    }
                TextField("メールアドレスを入力", text: $userEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isFocused)
                    .onTapGesture {
                        // テキストフィールドがタップされたときにフォーカスを当てる
                        isFocused = true
                    }

                // 名前が空でない場合のみボタンが有効
                Button(action: {
                    createUserFolder()
                }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                            .padding(.leading, 10)
                            .padding(.trailing, 3)
                        Text("作成")
                    }
                    .bold()
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 40)
                    .foregroundColor(.gray)
                    .background(Color.white)
                    .cornerRadius(3)
                    .shadow(color: .gray, radius: 2, y: 2)
                }
                .disabled(driveManager.userName.isEmpty) // 名前が空の場合はボタンが無効
                
                if (UITraitCollection.current.userInterfaceStyle == .dark) {
                    Text("\(driveManager.update)")
                        .foregroundColor(.black)
                }   else {
                    Text("\(driveManager.update)")
                        .foregroundColor(.white)
                }
                List {
//                    ForEach(driveManager.FileList) { item in
//                        VStack {
//                            Text(item.filename)
//                            HStack {
//                                Text(item.id)
//                            }
//                        }
//                        .padding()
//                        .onTapGesture {
//                            Task {
//                                await driveManager.updateFolderIDAsync(item.id)
//                                print(item.id)
//                                print("selectFileFromFileAppを実行")
//                                selectFileFromFileApp()
//                                let folderLink = "https://drive.google.com/drive/folders/\(item.id)?usp=sharing"
//                                selectedFolderLink = folderLink
//                                print("生成したフォルダリンク: \(folderLink)")
//                            }
//                        }
//                        .contentShape(Rectangle()) // タップ領域を指定
//                    }
//                    ForEach(users) { user in
//                        HStack {
//                            VStack(alignment: .leading) {
//                                Text(user.name!)
//                                    .font(.headline)
//                                Text(user.email!)
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                            }
//                            Spacer()  // ← 追加（ボタンのタップ領域確保）
//                            Button(action: {
//                                print("ボタンが押された")  // ← デバッグ用
//                                Task {
//                                    await driveManager.updateFolderIDAsync(user.folderID!)
//                                    let folderLink = "sharefilebcapp://folder?folderID=\(user.folderID!)"
//
//                                    mailerManager.email = user.email!
//                                    mailerManager.subject = "\(user.name!)さんへのファイル共有"
//                                    mailerManager.body = "ファイル共有リンク\n\n\(folderLink)\n\n※このメールはiOSの標準メールアプリで開くことを推奨します。"
//
//                                    print("selectFileFromFileAppを実行")
//                                    selectFileFromFileApp()
//                                }
//                            }) {
//                                Text("共有")
//                                    .font(.body)
//                                    .padding(10)
//                                    .frame(minWidth: 60, maxWidth: 80)
//                                    .background(Color.blue)
//                                    .foregroundColor(.white)
//                                    .cornerRadius(6)
//                            }
//                            .contentShape(Rectangle()) // ← タップ領域を明示的に指定
//                        }
//                        .padding()
//                    }
                    ForEach(users) { user in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(user.name!)
                                    .font(.headline)
                                Text(user.email!)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer() // 余白を入れる
                        }
                        .swipeActions {
                            Button(action: {
                                Task {
                                    await driveManager.updateFolderIDAsync(user.folderID!)
                                    let folderLink = "sharefilebcapp://folder?folderID=\(user.folderID!)"

                                    mailerManager.email = user.email!
                                    mailerManager.subject = "\(user.name!)さんへのファイル共有"
                                    mailerManager.body = "ファイル共有リンク\n\n\(folderLink)\n\n※このメールはiOSの標準メールアプリで開くことを推奨します。"

                                    print("selectFileFromFileAppを実行")
                                    selectFileFromFileApp()
                                }
                            }) {
                                Label("共有", systemImage: "square.and.arrow.up")
                            }
                            .tint(.blue) // ボタンの色を設定
                        }
                    }

                }
                
            }
            .padding()
            .onTapGesture {
                // テキストフィールド以外をタップしたときにキーボードを閉じる
                hideKeyboard()
            }
        }
        .navigationBarBackButtonHidden(true) // 戻るボタンを非表示にする
        .navigationBarHidden(true) // ナビゲーションバーを非表示にする
    }
}

#Preview {
    HomeView()
}

