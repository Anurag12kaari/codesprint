import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    // MARK: - Model for Code Snippet
    struct CodeSnippet: Identifiable, Codable {
        let id = UUID()
        let language: String
        let code: String
        let timestamp: Date
        
        var fileName: String {
            "python_\(Int(timestamp.timeIntervalSince1970)).py"
        }
    }
    
    // MARK: - Model for Test Case
    struct TestCase: Identifiable {
        let id = UUID()
        var input: String
        var expectedOutput: String
    }
    
    // MARK: - Storage Manager (Embedded)
    private func saveSnippet(_ snippet: CodeSnippet) {
        var snippets = loadSnippets()
        snippets.append(snippet)
        if let data = try? JSONEncoder().encode(snippets) {
            UserDefaults.standard.set(data, forKey: "codeSnippets")
        }
    }
    
    private func loadSnippets() -> [CodeSnippet] {
        if let data = UserDefaults.standard.data(forKey: "codeSnippets"),
           let snippets = try? JSONDecoder().decode([CodeSnippet].self, from: data) {
            return snippets
        }
        return []
    }
    
    // MARK: - State Variables for Code Editor
    @State private var codeInput = "print('Hello, World!')"
    @State private var output = "Output will appear here..."
    @State private var selectedSnippetToExport: CodeSnippet?
    @State private var showDocumentPicker = false
    @State private var isLoading = false
    @State private var exportMessage = ""
    
    // MARK: - State Variables for Custom Question Mode
    @State private var customQuestionDescription = ""
    @State private var customTestCases: [TestCase] = [TestCase(input: "", expectedOutput: "")]
    @State private var customCodeInput = "# Write your solution here\n"
    @State private var testCaseResults: [String] = []
    
    // MARK: - Theme Preference
    @AppStorage("themePreference") private var themePreference: String = "system"
    
    // MARK: - Environment for Color Scheme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        TabView {
            // Tab 1: Code Editor
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Python Compiler")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.top, 20)
                            .padding(.bottom, 10)

                        // Code Editor Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Editor")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)

                            TextEditor(text: $codeInput)
                                .font(.system(size: 15, design: .monospaced))
                                .frame(height: 200)
                                .padding(10)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                .autocapitalization(.none)
                        }

                        // Run Code Button
                        Button(action: {
                            compileCode()
                        }) {
                            Text(isLoading ? "Compiling..." : "Run Code")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isLoading ? Color(.systemGray) : Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(isLoading)
                        .shadow(color: colorScheme == .dark ? Color.white.opacity(isLoading ? 0 : 0.1) : Color.black.opacity(isLoading ? 0 : 0.1), radius: 5, x: 0, y: 2)

                        // Output Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Output")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)

                            TextEditor(text: $output)
                                .font(.system(size: 15, design: .monospaced))
                                .frame(height: 150)
                                .padding(10)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .disabled(true)
                                .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
                .background(Color(.systemGroupedBackground))
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Editor", systemImage: "square.and.pencil")
            }

            // Tab 2: Custom Question Mode
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Custom Question")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.top, 20)
                            .padding(.bottom, 10)

                        // Question Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Question Description")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)

                            TextEditor(text: $customQuestionDescription)
                                .font(.system(size: 15))
                                .frame(height: 120)
                                .padding(10)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                .overlay(
                                    Text("Enter your problem statement here...")
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(14)
                                        .allowsHitTesting(false)
                                        .opacity(customQuestionDescription.isEmpty ? 1 : 0),
                                    alignment: .topLeading
                                )
                        }

                        // Test Cases
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Test Cases")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button(action: {
                                    customTestCases.append(TestCase(input: "", expectedOutput: ""))
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.accentColor)
                                        Text("Add Test Case")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }

                            ForEach(customTestCases.indices, id: \.self) { index in
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Test Case \(index + 1)")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            customTestCases.remove(at: index)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .disabled(customTestCases.count == 1)
                                    }

                                    HStack(spacing: 10) {
                                        VStack(alignment: .leading) {
                                            Text("Input")
                                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                                .foregroundColor(.secondary)
                                            TextField("e.g., 5\\n3", text: $customTestCases[index].input)
                                                .font(.system(size: 15, design: .monospaced))
                                                .padding(8)
                                                .background(Color(.systemBackground))
                                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                                )
                                                .autocapitalization(.none)
                                        }

                                        VStack(alignment: .leading) {
                                            Text("Expected Output")
                                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                                .foregroundColor(.secondary)
                                            TextField("e.g., 8", text: $customTestCases[index].expectedOutput)
                                                .font(.system(size: 15, design: .monospaced))
                                                .padding(8)
                                                .background(Color(.systemBackground))
                                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                                )
                                                .autocapitalization(.none)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .shadow(color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                        }

                        // Code Editor for Custom Question
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Code Editor")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)

                            TextEditor(text: $customCodeInput)
                                .font(.system(size: 15, design: .monospaced))
                                .frame(height: 200)
                                .padding(10)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                .autocapitalization(.none)
                        }

                        // Run Test Cases Button
                        Button(action: {
                            runCustomTestCases()
                        }) {
                            Text(isLoading ? "Running..." : "Run Test Cases")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isLoading ? Color(.systemGray) : Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(isLoading)
                        .shadow(color: colorScheme == .dark ? Color.white.opacity(isLoading ? 0 : 0.1) : Color.black.opacity(isLoading ? 0 : 0.1), radius: 5, x: 0, y: 2)

                        // Test Case Results
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Test Case Results")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)

                            if testCaseResults.isEmpty {
                                Text("Run test cases to see results...")
                                    .font(.system(size: 15, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                                    .background(Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                    .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            } else {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(testCaseResults.indices, id: \.self) { index in
                                            Text(testCaseResults[index])
                                                .font(.system(size: 15, design: .monospaced))
                                                .foregroundColor(testCaseResults[index].contains("Passed") ? .green : .red)
                                                .padding(.vertical, 4)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                .frame(minHeight: 120)
                                .padding(.horizontal, 10)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
                .background(Color(.systemGroupedBackground))
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Custom Question", systemImage: "questionmark.circle")
            }

            // Tab 3: History
            NavigationView {
                VStack {
                    if loadSnippets().isEmpty {
                        Text("No Code Snippets Yet")
                            .font(.system(size: 22, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        List(loadSnippets()) { snippet in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(snippet.language)
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)

                                Text(snippet.code.prefix(50) + (snippet.code.count > 50 ? "..." : ""))
                                    .font(.system(size: 15, design: .monospaced))
                                    .foregroundColor(.secondary)

                                Text("Saved: \(snippet.timestamp, formatter: dateFormatter)")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(.secondary)

                                Button(action: {
                                    selectedSnippetToExport = snippet
                                    showDocumentPicker = true
                                }) {
                                    Text("Export")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(.accentColor)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(Color.accentColor.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .listStyle(.insetGrouped)
                    }

                    // Export feedback message
                    if !exportMessage.isEmpty {
                        Text(exportMessage)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.green)
                            .padding()
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    exportMessage = ""
                                }
                            }
                    }
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("History")
            }
            .tabItem {
                Label("History", systemImage: "clock")
            }

            // Tab 4: Settings
            NavigationView {
                Form {
                    Section(header: Text("Appearance")) {
                        Picker("Theme", selection: $themePreference) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .navigationTitle("Settings")
                .background(Color(.systemGroupedBackground))
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .accentColor(.blue)
        .sheet(isPresented: $showDocumentPicker) {
            if let snippet = selectedSnippetToExport {
                DocumentPicker(code: snippet.code, fileName: snippet.fileName) { message in
                    exportMessage = message
                }
            }
        }
        .preferredColorScheme(themePreference == "system" ? nil : (themePreference == "light" ? .light : .dark))
    }
    
    // MARK: - Helper Functions
    private func compileCode() {
        let snippet = CodeSnippet(language: "Python", code: codeInput, timestamp: Date())
        saveSnippet(snippet)
        
        isLoading = true
        output = "Compiling...\n"
        
        let url = URL(string: "https://judge0-ce.p.rapidapi.com/submissions?base64_encoded=false&wait=true")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("f8a7b3d2d5msh6c59bfa5ae153d2p15dae6jsnf5d3713f7040", forHTTPHeaderField: "x-rapidapi-key")
        request.addValue("judge0-ce.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        
        let body: [String: Any] = [
            "source_code": codeInput,
            "language_id": 71,
            "stdin": ""
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            DispatchQueue.main.async {
                isLoading = false
                output = "Error: Failed to serialize request - \(error.localizedDescription)"
            }
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    output = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    output = "Error: No valid HTTP response"
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    output = "Error: HTTP \(httpResponse.statusCode)"
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    output = "Error: Invalid response from server"
                    return
                }
                
                print("Judge0 Response: \(json)")
                
                if let stdout = json["stdout"] as? String, !stdout.isEmpty {
                    output = "Output:\n\(stdout)"
                } else if let stderr = json["stderr"] as? String, !stderr.isEmpty {
                    output = "Error:\n\(stderr)"
                } else if let compileOutput = json["compile_output"] as? String, !compileOutput.isEmpty {
                    output = "Compilation Error:\n\(compileOutput)"
                } else if let status = json["status"] as? [String: Any],
                          let statusDesc = status["description"] as? String {
                    output = "Status: \(statusDesc)"
                } else {
                    output = "No output or error received. Check console for full response."
                }
            }
        }.resume()
    }
    
    private func runCustomTestCases() {
        isLoading = true
        testCaseResults = []
        let validTestCases = customTestCases.filter { !$0.input.isEmpty && !$0.expectedOutput.isEmpty }
        if validTestCases.isEmpty {
            isLoading = false
            testCaseResults.append("Error: Please provide at least one valid test case.")
            return
        }
        var currentTestCaseIndex = 0
        func runNextTestCase() {
            if currentTestCaseIndex >= validTestCases.count {
                isLoading = false
                return
            }
            let testCase = validTestCases[currentTestCaseIndex]
            let url = URL(string: "https://judge0-ce.p.rapidapi.com/submissions?base64_encoded=false&wait=true")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("f8a7b3d2d5msh6c59bfa5ae153d2p15dae6jsnf5d3713f7040", forHTTPHeaderField: "x-rapidapi-key")
            request.addValue("judge0-ce.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
            let body: [String: Any] = [
                "source_code": customCodeInput,
                "language_id": 71,
                "stdin": testCase.input
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    testCaseResults.append("Test Case \(currentTestCaseIndex + 1): Failed (Serialization Error)")
                }
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        testCaseResults.append("Test Case \(currentTestCaseIndex + 1): Failed (\(error.localizedDescription))")
                        currentTestCaseIndex += 1
                        runNextTestCase()
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                          let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        testCaseResults.append("Test Case \(currentTestCaseIndex + 1): Failed (Invalid response)")
                        currentTestCaseIndex += 1
                        runNextTestCase()
                        return
                    }
                    
                    if let stderr = json["stderr"] as? String, !stderr.isEmpty {
                        let errorLines = stderr.split(separator: "\n")
                        if let lastLine = errorLines.last {
                            testCaseResults.append("Test Case \(currentTestCaseIndex + 1): Failed (Error: \(lastLine))")
                        } else {
                            testCaseResults.append("Test Case \(currentTestCaseIndex + 1): Failed (Error: \(stderr))")
                        }
                    } else if let stdout = json["stdout"] as? String {
                        let trimmedOutput = stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                        let expectedOutput = testCase.expectedOutput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmedOutput == expectedOutput {
                            testCaseResults.append("Test Case \(currentTestCaseIndex + 1): Passed")
                        } else {
                            testCaseResults.append("Test Case \(currentTestCaseIndex + 1): Failed (Expected: \(expectedOutput), Got: \(trimmedOutput))")
                        }
                    } else {
                        testCaseResults.append("Test Case \(currentTestCaseIndex + 1): Failed (No output)")
                    }
                    currentTestCaseIndex += 1
                    runNextTestCase()
                }
            }.resume()
        }
        runNextTestCase()
        let snippet = CodeSnippet(language: "Python", code: customCodeInput, timestamp: Date())
        saveSnippet(snippet)
    }
    
    // Date formatter for history
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Document Picker for Exporting Code
struct DocumentPicker: UIViewControllerRepresentable {
    let code: String
    let fileName: String
    let onCompletion: (String) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try code.write(to: tempURL, atomically: true, encoding: .utf8)
        } catch {
            onCompletion("Error: Failed to create file - \(error.localizedDescription)")
            return UIDocumentPickerViewController(forExporting: [])
        }
        
        let picker = UIDocumentPickerViewController(forExporting: [tempURL])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onCompletion: (String) -> Void
        
        init(onCompletion: @escaping (String) -> Void) {
            self.onCompletion = onCompletion
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onCompletion("File exported successfully!")
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCompletion("Export cancelled")
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)
        ContentView()
            .preferredColorScheme(.dark)
    }
}
