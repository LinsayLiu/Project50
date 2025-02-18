//
//  Project_50App.swift
//  Project 50
//
//  Created by Linyi Liu on 2025/2/13.
//

import SwiftUI

@main
struct Project_50App: App {
    @StateObject private var viewModel = ChallengeViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                viewModel.sceneDidBecomeActive()
            }
        }
    }
}
