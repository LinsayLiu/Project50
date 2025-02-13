import SwiftUI

struct PanoramaView: View {
    @ObservedObject var viewModel: ChallengeViewModel
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
                        .stroke(status.color, lineWidth: 1)
                )
            
            VStack(spacing: 4) {
                Text("\(day)")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                
                if case .completed(let mood) = status {
                    Image(systemName: mood.icon)
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