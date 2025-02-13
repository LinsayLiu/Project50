import SwiftUI

struct JournalView: View {
    @ObservedObject var viewModel: ChallengeViewModel
    @State private var journalContent: String = ""
    @Environment(\.dismiss) var dismiss
    @State private var showingSaveAlert = false
    let existingJournal: Journal?
    
    init(viewModel: ChallengeViewModel, existingJournal: Journal? = nil) {
        self.viewModel = viewModel
        self.existingJournal = existingJournal
        _journalContent = State(initialValue: existingJournal?.content ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
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
                    .listRowBackground(Color.yellow)
                    .foregroundColor(.white)
                }
            }
            .navigationTitle(existingJournal != nil ? "编辑日记" : "今日日记")
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
        guard !journalContent.isEmpty else { return }
        
        if let existing = existingJournal {
            viewModel.updateJournalEntry(existing, newContent: journalContent)
        } else {
            viewModel.addJournalEntry(content: journalContent)
        }
        showingSaveAlert = true
    }
}

struct JournalDetailView: View {
    let journal: Journal
    @ObservedObject var viewModel: ChallengeViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingEditSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("第\(journal.dayNumber)天", systemImage: "calendar")
                    Spacer()
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
                Button(action: {
                    showingEditSheet = true
                }) {
                    Text("编辑")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            JournalView(viewModel: viewModel, existingJournal: journal)
        }
    }
}

#Preview {
    JournalView(viewModel: ChallengeViewModel())
} 