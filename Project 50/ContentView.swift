//
//  ContentView.swift
//  Project 50
//
//  Created by Linyi Liu on 2025/2/13.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChallengeViewModel()
    
    var body: some View {
        TabView {
            NavigationView {
                TaskListView(viewModel: viewModel)
            }
            .tabItem {
                Label("今日任务", systemImage: "list.bullet")
            }
            
            NavigationView {
                PanoramaView(viewModel: viewModel)
            }
            .tabItem {
                Label("全景视图", systemImage: "calendar")
            }
        }
        .sheet(item: $viewModel.selectedDay) { selectedDay in
            if let journal = viewModel.getJournal(for: selectedDay.id) {
                JournalDetailView(journal: journal)
            } else {
                JournalView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.checkChallengeStatus()
        }
    }
}

#Preview {
    ContentView()
}
