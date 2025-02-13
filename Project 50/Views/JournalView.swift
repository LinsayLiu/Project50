import SwiftUI

struct JournalView: View {
    @ObservedObject var viewModel: ChallengeViewModel
    @State private var journalContent: String = ""
    @State private var selectedMood: Journal.Mood = .normal
    @Environment(\.dismiss) var dismiss
    @State private var showingSaveAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("今天的心情")) {
                    HStack {
                        ForEach(Journal.Mood.allCases, id: \.self) { mood in
                            Button(action: {
                                selectedMood = mood
                            }) {
                                VStack {
                                    Image(systemName: mood.icon)
                                        .font(.title2)
                                    Text(mood.rawValue)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedMood == mood ? Color.accentColor.opacity(0.2) : Color.clear)
                                .foregroundColor(selectedMood == mood ? .accentColor : .primary)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Section(header: Text("今天的感想")) {
                    TextEditor(text: $journalContent)
                        .frame(minHeight: 200)
                        .overlay(
                            Group {
                                if journalContent.isEmpty {
                                    Text("记录一下今天的心得体会...")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                }
                            },
                            alignment: .topLeading
                        )
                }
                
                Section {
                    Button(action: submitJournal) {
                        HStack {
                            Spacer()
                            Text("保存")
                                .bold()
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .listRowBackground(Color.accentColor)
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("今日日记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("保存成功", isPresented: $showingSaveAlert) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("日记已保存")
            }
        }
    }
    
    private func submitJournal() {
        guard !journalContent.isEmpty else {
            // 如果内容为空，至少需要选择一个心情
            viewModel.addJournalEntry(content: "今天的心情：\(selectedMood.rawValue)", mood: selectedMood)
            showingSaveAlert = true
            return
        }
        
        viewModel.addJournalEntry(content: journalContent, mood: selectedMood)
        showingSaveAlert = true
    }
}

struct JournalDetailView: View {
    let journal: Journal
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("第\(journal.dayNumber)天", systemImage: "calendar")
                        Spacer()
                        Label(journal.mood.rawValue, systemImage: journal.mood.icon)
                    }
                    .font(.headline)
                    
                    Divider()
                    
                    Text(journal.content)
                        .font(.body)
                    
                    Text(journal.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("日记详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    JournalView(viewModel: ChallengeViewModel())
} 