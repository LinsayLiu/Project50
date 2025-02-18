import SwiftUI 

struct MemoView: View {
    @ObservedObject var viewModel: ChallengeViewModel
    @State private var memoContent: String = ""
    @Environment(\.dismiss) var dismiss
    @State private var showingSaveAlert = false
    let cardNumber: Int
    
    init(viewModel: ChallengeViewModel, cardNumber: Int) {
        self.viewModel = viewModel
        self.cardNumber = cardNumber
        _memoContent = State(initialValue: viewModel.getMemo(for: cardNumber)?.content ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("备注内容")) {
                    TextEditor(text: $memoContent)
                        .frame(minHeight: 200)
                        .overlay(
                            Group {
                                if memoContent.isEmpty {
                                    Text("记录一下想法...")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                }
                            },
                            alignment: .topLeading
                        )
                }
                
                Section {
                    Button(action: saveMemo) {
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
            .navigationTitle("第\(cardNumber)天")
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
                Text("备注已保存")
            }
        }
    }
    
    private func saveMemo() {
        guard !memoContent.isEmpty else { return }
        viewModel.addOrUpdateMemo(content: memoContent, forCard: cardNumber)
        showingSaveAlert = true
    }
}

struct MemoDetailView: View {
    let memo: Memo
    let cardNumber: Int
    @ObservedObject var viewModel: ChallengeViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingEditSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("第\(cardNumber)天", systemImage: "note.text")
                    Spacer()
                }
                .font(.headline)
                
                Divider()
                
                Text(memo.content)
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("备注详情")
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
            MemoView(viewModel: viewModel, cardNumber: cardNumber)
        }
    }
}

#Preview {
    MemoView(viewModel: ChallengeViewModel(), cardNumber: 1)
}