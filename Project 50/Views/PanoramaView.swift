import SwiftUI

struct PanoramaView: View {
    @ObservedObject var viewModel: ChallengeViewModel
    @State private var showingJournalTip = false
    @AppStorage("hasShownJournalTip") private var hasShownJournalTip = false
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...50, id: \.self) { day in
                    DayCell(day: day, status: viewModel.getDayStatus(day: day))
                        .onTapGesture {
                            viewModel.selectedDay = SelectedDay(day)
                        }
                }
            }
            .padding()
        }
        .navigationTitle("50天全景")
        .overlay {
            if showingJournalTip {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("点击卡片记录今天的感想")
                            .font(.subheadline)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 3)
                        Spacer()
                    }
                    .padding()
                    .transition(.move(edge: .bottom))
                }
                .animation(.easeInOut, value: showingJournalTip)
            }
        }
        .onAppear {
            viewModel.checkChallengeStatus()
            if !hasShownJournalTip {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showingJournalTip = true
                    }
                    // 3秒后自动隐藏提示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showingJournalTip = false
                            hasShownJournalTip = true
                        }
                    }
                }
            }
        }
    }
}

struct DayCell: View {
    let day: Int
    let status: DayStatus
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(status.color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(status.borderColor, lineWidth: status.borderWidth)
                )
            
            VStack(spacing: 4) {
                Text("\(day)")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                
                if status.showCheckmark {
                    Image(systemName: "checkmark")
                        .foregroundColor(status.color)
                }
            }
            .foregroundColor(status.color)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    NavigationView {
        PanoramaView(viewModel: ChallengeViewModel())
    }
} 