import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ChallengeViewModel
    
    var body: some View {
        TabView {
            NavigationStack {
                TaskListView(viewModel: viewModel)
            }
            .tabItem {
                Label("今日任务", systemImage: "list.bullet")
            }
            
            NavigationStack {
                PanoramaView(viewModel: viewModel)
            }
            .tabItem {
                Label("全景视图", systemImage: "calendar")
            }
        }
        .sheet(item: $viewModel.selectedDay) { selectedDay in
            if let memo = viewModel.getMemo(for: selectedDay.id) {
                MemoDetailView(memo: memo, cardNumber: selectedDay.id, viewModel: viewModel)
            } else {
                MemoView(viewModel: viewModel, cardNumber: selectedDay.id)
            }
        }
        .onAppear {
            viewModel.checkChallengeStatus()
        }
        .tint(.yellow)
        .accentColor(.yellow)
    }
}