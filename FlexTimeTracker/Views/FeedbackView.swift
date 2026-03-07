import SwiftUI
import PhotosUI

/// Reusable feedback view. Drop into any app alongside FeedbackService.swift.
///
/// Usage:
/// ```swift
/// FeedbackView(repository: "KairosApp-Soulvy/KairosApp")
/// ```
struct FeedbackView: View {
    let repository: String
    
    @State private var category: FeedbackService.Category = .bug
    @State private var message = ""
    @State private var screenshotData: Data?
    @State private var screenshotImage: UIImage?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                // Category picker
                Section("Category") {
                    Picker("Type", selection: $category) {
                        ForEach(FeedbackService.Category.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
                
                // Message
                Section("Description") {
                    TextEditor(text: $message)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if message.isEmpty {
                                Text("Describe your feedback...")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                
                // Screenshot
                Section("Screenshot (Optional)") {
                    if let screenshotImage {
                        Image(uiImage: screenshotImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                        
                        Button("Remove Screenshot", role: .destructive) {
                            self.screenshotImage = nil
                            self.screenshotData = nil
                            self.selectedPhoto = nil
                        }
                    }
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .screenshots) {
                        Label(screenshotImage == nil ? "Attach Screenshot" : "Change Screenshot",
                              systemImage: "camera.viewfinder")
                    }
                }
                
                // Send
                Section {
                    Button {
                        Task { await sendFeedback() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSending {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Sending...")
                            } else {
                                Label("Send Feedback", systemImage: "paperplane.fill")
                            }
                            Spacer()
                        }
                        .font(.headline)
                    }
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedPhoto) {
                Task {
                    if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                        if let img = UIImage(data: data) {
                            // Compress to keep issue size reasonable
                            let compressed = img.jpegData(compressionQuality: 0.5)
                            screenshotData = compressed
                            screenshotImage = img
                        }
                    }
                }
            }
            .alert("Feedback Sent!", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Thank you! Your feedback has been submitted.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func sendFeedback() async {
        isSending = true
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        let service = FeedbackService(repository: repository)
        let result = await service.submit(
            category: category,
            message: message,
            screenshotData: screenshotData
        )
        isSending = false
        
        if result.success {
            generator.notificationOccurred(.success)
            showSuccess = true
        } else {
            generator.notificationOccurred(.error)
            errorMessage = result.error ?? "Unknown error"
            showError = true
        }
    }
}

#Preview {
    FeedbackView(repository: "KairosApp-Soulvy/KairosApp")
}
