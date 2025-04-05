//
//  DriveManager.swift
//  ShareFileBCtest
//
//  Created by 古賀創臣 on 2025/03/16.
//

import GoogleSignIn
import GoogleAPIClientForREST_Drive

class DriveManager : ObservableObject {
    static let shared = DriveManager() // シングルトン
    private var service: GTLRDriveService?
    @Published var rootFolderID: String? = nil // ルートフォルダの ID
    @Published var currentFolderID: String? = nil //現在選択しているフォルダのID
    @Published var folderIDForDownload: String? = nil //ダウンロードするフォルダのID
    @Published var userName: String = ""
    var FileList = [File_List]()
    //@Published var downloadFileList = [File_List]()
    @Published var update = 0
    @Published var isSignedIn: Bool = false // ログイン状態を管理
    
    private init() {
        self.service = getDriveService()
    }
    
    //Google認証とGoogleDriveへのアクセス許可の認証を行う関数
    func handleSignInButton() {
        //UIApplication.shared.connectedScenes.first as? UIWindowSceneでは複数ウィンドウが扱える場合Scene配列の最初の値を取るため、意図しないSceneを取る可能性もあるため、複数ウィンドウに対応させる場合は条件を入れるべき
        //ここでは現在開いているウィンドウの中で一番上に表示されている画面を取得
        guard let presentingviewcontroller = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return }
        //１行目Googleログインの画面を開く
        //２行目ログイン後signInResultにログイン情報が入る
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingviewcontroller) {
            signInResult, error in
            self.update += 1
            guard signInResult != nil, let currentuser = GIDSignIn.sharedInstance.currentUser else { return }
            
            let scopes = ["https://www.googleapis.com/auth/drive.file"]
            //presenting: presentingviewcontrollerはアプリの画面の上に認証画面を表示するという意味
            
            // 現在のスコープを確認
            if let currentScopes = currentuser.grantedScopes, currentScopes.contains(scopes[0]) {
                print("スコープ \(scopes[0]) はすでに追加されています")
            } else {
                // スコープが追加されていない場合、追加処理を実行
                currentuser.addScopes(scopes, presenting: presentingviewcontroller) { signInResult, error in
                    guard error == nil, signInResult != nil else {
                        print("スコープ追加失敗: \(error?.localizedDescription ?? "不明なエラー")")
                        return
                    }
                    print("スコープ追加成功: \(scopes[0])")
                }
            }
            
            self.getOrCreateFolder(named: "ShareFileBCApp", parentID: nil) { folderID in
                guard let folderID = folderID else {
                    print("ルートフォルダの作成に失敗しました")
                    return
                }
                self.rootFolderID = folderID
                print("rootFolderIDの確認：\(self.rootFolderID!)")
                self.isSignedIn = true
                
                //                self.getList(folderID: self.rootFolderID) {
                //                    DispatchQueue.main.async {
                //                        print("共有相手リスト取得完了")
                //                        //ホーム画面へ遷移
                //                        self.isSignedIn = true
                //                    }
                //                }
            }
        }
    }
    
    //GoogleDriveAPIを操作するためのクラスのインスタンスを返す関数
    func getDriveService() -> GTLRDriveService? {
        //GTLRDriveServiceはGoogleDriveAPIを操作するためのクラス
        let service = GTLRDriveService()
        guard let currentuser = GIDSignIn.sharedInstance.currentUser else { return nil }
        service.authorizer = currentuser.fetcherAuthorizer
        return service
    }
    
    // フォルダを作成または取得する汎用関数
    func getOrCreateFolder(named folderName: String, parentID: String?, completion: @escaping (String?) -> Void) {
        guard let service = getDriveService() else { return }
        
        // フォルダ名で検索
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "name = '\(folderName)' and mimeType = 'application/vnd.google-apps.folder' and trashed = false" +
        (parentID != nil ? " and '\(parentID!)' in parents" : "")
        query.spaces = "drive"
        
        service.executeQuery(query) { _, result, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let result = result as? GTLRDrive_FileList, let folder = result.files?.first {
                // フォルダが見つかった場合
                print("\(folderName) フォルダID: \(folder.identifier ?? "IDなし")")
                completion(folder.identifier)
            } else {
                // フォルダが見つからない場合、新規作成
                let newFolder = GTLRDrive_File()
                newFolder.name = folderName
                newFolder.mimeType = "application/vnd.google-apps.folder"
                if let parentID = parentID {
                    newFolder.parents = [parentID]
                }
                
                let createQuery = GTLRDriveQuery_FilesCreate.query(withObject: newFolder, uploadParameters: nil)
                service.executeQuery(createQuery) { _, createdFolder, error in
                    if let error = error {
                        print("フォルダ作成エラー: \(error.localizedDescription)")
                        completion(nil)
                        return
                    }
                    
                    if let createdFolder = createdFolder as? GTLRDrive_File {
                        print("\(folderName) フォルダ作成成功: \(createdFolder.identifier ?? "IDなし")")
                        
                        // 「Share FileBCApp」の場合、制限付きで作成
                        if folderName == "Share FileBCApp" {
                            // 制限付きフォルダにするための設定は不要
                            print("「Share FileBCApp」は制限付きフォルダ")
                        } else {
                            // それ以外はリンクを知っている人全員にアクセスできる設定
                            self.setPublicAccess(forFolder: createdFolder.identifier)
                        }
                        
                        completion(createdFolder.identifier)
                    } else {
                        print("フォルダ作成失敗")
                        completion(nil)
                    }
                }
            }
        }
    }
    
    // フォルダにリンクを知っている人全員にアクセスできる権限を追加
    func setPublicAccess(forFolder folderID: String?) {
        guard let service = getDriveService(), let folderID = folderID else { return }
        
        let permission = GTLRDrive_Permission()
        permission.type = "anyone" // リンクを知っている人全員
        permission.role = "reader" // 読み取り専用アクセス権限
        
        let query = GTLRDriveQuery_PermissionsCreate.query(withObject: permission, fileId: folderID)
        service.executeQuery(query) { _, _, error in
            if let error = error {
                print("フォルダのアクセス設定エラー: \(error.localizedDescription)")
            } else {
                print("フォルダがリンクを知っている人全員にアクセス可能になりました: \(folderID)")
            }
        }
    }
    
    //指定したfolderIDの中にあるフォルダやファイルを取得
    //    func getList(folderID: String?) {
    //        guard let service = getDriveService() else { return }
    //        guard let folderID = folderID else { return }
    //
    //        let query = GTLRDriveQuery_FilesList.query()
    //        query.q = "'\(folderID)' in parents and trashed = false"
    //        query.fields = "files(id, name, kind, mimeType)"
    //
    //        service.executeQuery(query) { _, result, error in
    //            guard error == nil, let result = result as? GTLRDrive_FileList, let files = result.files else { return }
    //
    //            DispatchQueue.main.async {
    //                self.FileList = files.map { file in
    //                    File_List(id: file.identifier ?? "", filename: file.name ?? "", kind: file.kind ?? "", mimeType: file.mimeType ?? "")
    //                }
    //                self.currentFolderID = folderID  // 選択したフォルダIDを更新
    //            }
    //        }
    //    }
    
    func getList(folderID: String?, completion: @escaping () -> Void) {
        guard let service = getDriveService() else { return }
        guard let folderID = folderID else { return }
        
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "'\(folderID)' in parents and trashed = false"
        query.fields = "files(id, name, kind, mimeType)"
        
        service.executeQuery(query) { _, result, error in
            guard error == nil, let result = result as? GTLRDrive_FileList, let files = result.files else {
                DispatchQueue.main.async {
                    completion()  // エラーでも completion を呼ぶ
                }
                return
            }
            
            DispatchQueue.main.async {
                self.FileList = files.map { file in
                    File_List(id: file.identifier ?? "", filename: file.name ?? "", kind: file.kind ?? "", mimeType: file.mimeType ?? "")
                }
                completion()  //データ更新後に completion を呼ぶ
            }
        }
    }
    
    
    func uploadFile(fileName: String, fileData: Data, mimeType: String, shareDate: String, userFolderID: String) {
        guard let service = getDriveService() else { return }
        
        // 次に、日付フォルダを作成または取得
        getOrCreateFolder(named: shareDate, parentID: userFolderID) { dateFolderID in
            guard let dateFolderID = dateFolderID else { return }
            
            // ファイルの情報を作成
            let file = GTLRDrive_File()
            file.name = fileName
            file.parents = [dateFolderID] // 日付フォルダ内に格納
            
            // アップロード用のパラメータ
            let uploadParams = GTLRUploadParameters(data: fileData, mimeType: mimeType)
            let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParams)
            
            service.executeQuery(query) { _, result, error in
                if let error = error {
                    print("アップロード失敗: \(error.localizedDescription)")
                } else {
                    print("アップロード成功: \(fileName)")
                    if let uploadedFile = result as? GTLRDrive_File {
                        print("アップロードされたファイルID: \(uploadedFile.identifier ?? "不明")")
                        print("アップロードされたファイルの名前: \(uploadedFile.name ?? "不明")")
                    }
                }
            }
        }
    }
    //変数更新を非同期処理で行う
    func updateFolderIDAsync(_ newID: String) async {
        // 非同期でIDを更新
        await MainActor.run {
            self.currentFolderID = newID
            print("currentFolderIDの更新完了")
        }
    }
    
    //ログインなしで公開ファイルをダウンロードする関数
    func downloadFile(fileID: String, completion: @escaping (Data?, Error?) -> Void) {
        // Google Driveサービスを設定
        let service = GTLRDriveService()
        
        // info.plistからAPIキーを読み取る
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleAPIKey") as? String {
            service.apiKey = apiKey
        } else {
            completion(nil, NSError(domain: "DriveServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey: "APIキーが設定されていません"]))
            return
        }
        
        // 公開ファイルにアクセスするための設定（認証なしでアクセス）
        service.authorizer = nil  // 認証なしでアクセス
        
        // ファイルをダウンロードするクエリ
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileID)
        
        // Google Drive APIクエリを実行
        service.executeQuery(query) { (ticket, file, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            // ダウンロードしたデータを返す
            if let fileData = file as? GTLRDataObject {
                completion(fileData.data, nil)
            } else {
                completion(nil, NSError(domain: "FileDownloadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "ファイルデータの取得に失敗しました"]))
            }
        }
    }
    
    //Googleログインなしで公開フォルダを取得
    func getPublicFilesList(folderID: String?, completion: @escaping () -> Void) {
        guard let folderID = folderID else {
            print("エラー: folderIDがnil")
            return
        }
        print("アクセス確認: \(folderID)")

        // APIキーをInfo.plistから取得
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleAPIKey") as? String, !apiKey.isEmpty else {
            print("エラー: APIキーが取得できません")
            return
        }
        print(apiKey)

        let service = GTLRDriveService()
        service.apiKey = apiKey  // API キーを設定

        let query = GTLRDriveQuery_FilesList.query()
        query.q = "'\(folderID.replacingOccurrences(of: "'", with: "\\'"))' in parents and trashed = false"
        query.fields = "files(id, name, kind, mimeType)"

        service.executeQuery(query) { [weak self] _, result, error in
            if let error = error {
                DispatchQueue.main.async {
                    print("アクセスエラー: \(error.localizedDescription)")
                    completion()
                }
                return
            }

            guard let result = result as? GTLRDrive_FileList, let files = result.files else {
                DispatchQueue.main.async {
                    print("データ取得エラー: 結果が nil またはファイルが存在しない")
                    completion()
                }
                return
            }

            DispatchQueue.main.async {
                self?.FileList = files.map { file in
                    File_List(id: file.identifier ?? "", filename: file.name ?? "", kind: file.kind ?? "", mimeType: file.mimeType ?? "")
                }
                print("アクセス成功: \(self?.FileList ?? [])")
                completion()
            }
        }
    }
}
