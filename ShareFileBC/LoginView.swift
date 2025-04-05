//
//  LoginView.swift
//  ShareFileBCtest
//
//  Created by 古賀創臣 on 2025/03/17.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import GoogleAPIClientForREST_Drive
import UniformTypeIdentifiers

struct LoginView: View {
    @StateObject var driveManager = DriveManager.shared
    
    var body: some View {
        VStack {
            Text("ShareFileBC")
                .font(.largeTitle)
            GoogleSignInButton(action: driveManager.handleSignInButton)
        }
    }
}

#Preview {
    LoginView()
}
