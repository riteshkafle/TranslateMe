import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TranslationViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                translationPanel

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("History")
                                .font(.title3.bold())
                            Text("Your recent translations")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if !viewModel.history.isEmpty {
                            Button("Clear", role: .destructive) {
                                Task {
                                    await viewModel.clearHistory()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if viewModel.history.isEmpty {
                                ContentUnavailableView(
                                    "No translations yet",
                                    systemImage: "text.bubble",
                                    description: Text("Translate something to see history here.")
                                )
                                .padding(.top, 24)
                            } else {
                                ForEach(viewModel.history) { item in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(item.inputText)
                                            .font(.headline)
                                        Text(item.outputText)
                                            .foregroundStyle(.secondary)
                                        Text("\(item.sourceLanguage.uppercased()) -> \(item.targetLanguage.uppercased())")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if let error = viewModel.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .navigationTitle("TranslateMe")
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture {
                isInputFocused = false
            }
            .task {
                await viewModel.loadHistory()
            }
        }
    }

    private var translationPanel: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Quick Translation")
                    .font(.title3.bold())
                Spacer()
            }

            HStack {
                Picker("From", selection: $viewModel.sourceLanguage) {
                    ForEach(viewModel.languageOptions, id: \.code) { language in
                        Text(language.name).tag(language.code)
                    }
                }
                .pickerStyle(.menu)

                Image(systemName: "arrow.right")

                Picker("To", selection: $viewModel.targetLanguage) {
                    ForEach(viewModel.languageOptions, id: \.code) { language in
                        Text(language.name).tag(language.code)
                    }
                }
                .pickerStyle(.menu)
            }

            TextField("Type text to translate...", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .lineLimit(2...5)

            Button {
                isInputFocused = false
                Task {
                    await viewModel.translate()
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                    Text(viewModel.isLoading ? "Translating..." : "Translate")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            VStack(alignment: .leading, spacing: 8) {
                Text("Translation")
                    .font(.headline)
                Text(viewModel.translatedText.isEmpty ? "Your result appears here..." : viewModel.translatedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.12), .purple.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ContentView()
}
