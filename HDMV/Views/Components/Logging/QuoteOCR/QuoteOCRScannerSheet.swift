//
//  QuoteOCRScannerSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.10.2026.
//

import SwiftUI
import PhotosUI

enum OCRCaptureSource: Identifiable {
    case documentCamera
    case standardCamera
    case photoLibrary
    
    var id: String {
        switch self {
        case .documentCamera: return "documentCamera"
        case .standardCamera: return "standardCamera"
        case .photoLibrary: return "photoLibrary"
        }
    }
}

struct QuoteOCRScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var existingQuoteText: String = ""
    var onQuoteExtracted: (String) -> Void
    
    @State private var activeSource: OCRCaptureSource? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    @State private var capturedImage: UIImage? = nil
    @State private var ocrResult: OCRResult? = nil
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String? = nil
    
    // Automatically launch document camera on appear if supported
    @State private var hasAutoLaunched: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if isProcessing {
                    processingView
                } else if let result = ocrResult {
                    QuoteOCRHighlightView(
                        result: result,
                        existingQuoteText: existingQuoteText,
                        onQuoteSelected: { selectedQuote in
                            onQuoteExtracted(selectedQuote)
                            dismiss()
                        },
                        onRetake: {
                            resetState()
                            promptCaptureSource()
                        }
                    )
                } else if let error = errorMessage {
                    errorStateView(error: error)
                } else {
                    sourceSelectionView
                }
            }
            .navigationTitle(ocrResult == nil ? "Scan Quote Page" : "Select Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if ocrResult != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                resetState()
                                startCapture(source: .standardCamera)
                            } label: {
                                Label("Take Photo", systemImage: "camera")
                            }
                            
                            Button {
                                resetState()
                                startCapture(source: .photoLibrary)
                            } label: {
                                Label("Choose from Photos", systemImage: "photo.on.rectangle")
                            }
                            
                            if DocumentScannerView.isSupported {
                                Button {
                                    resetState()
                                    startCapture(source: .documentCamera)
                                } label: {
                                    Label("Scan Document Page", systemImage: "doc.viewfinder")
                                }
                            }
                        } label: {
                            Image(systemName: "camera.badge.ellipsis")
                        }
                    }
                }
            }
            .fullScreenCover(item: $activeSource) { source in
                switch source {
                case .documentCamera:
                    if DocumentScannerView.isSupported {
                        DocumentScannerView(
                            onScanCompleted: { image in
                                activeSource = nil
                                processImage(image)
                            },
                            onCancel: {
                                activeSource = nil
                            },
                            onError: { error in
                                activeSource = nil
                                self.errorMessage = error.localizedDescription
                            }
                        )
                        .ignoresSafeArea()
                    } else {
                        ImagePickerView(
                            sourceType: .camera,
                            onImagePicked: { image in
                                activeSource = nil
                                processImage(image)
                            },
                            onCancel: {
                                activeSource = nil
                            }
                        )
                        .ignoresSafeArea()
                    }
                case .standardCamera:
                    ImagePickerView(
                        sourceType: .camera,
                        onImagePicked: { image in
                            activeSource = nil
                            processImage(image)
                        },
                        onCancel: {
                            activeSource = nil
                        }
                    )
                    .ignoresSafeArea()
                case .photoLibrary:
                    ImagePickerView(
                        sourceType: .photoLibrary,
                        onImagePicked: { image in
                            activeSource = nil
                            processImage(image)
                        },
                        onCancel: {
                            activeSource = nil
                        }
                    )
                    .ignoresSafeArea()
                }
            }
            .onAppear {
                if !hasAutoLaunched {
                    hasAutoLaunched = true
                    // Default to camera photo for snapping 1-2 sentences quickly
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        activeSource = .standardCamera
                    } else if DocumentScannerView.isSupported {
                        activeSource = .documentCamera
                    } else {
                        activeSource = .photoLibrary
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var sourceSelectionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
                .padding()
                .background(Circle().fill(Color.accentColor.opacity(0.12)))
            
            VStack(spacing: 8) {
                Text("Snap Quote from Book")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Take a quick photo of the page to recognize text and highlight sentences for your quote.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                Button {
                    startCapture(source: .standardCamera)
                } label: {
                    Label("Take Photo with Camera", systemImage: "camera.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button {
                    startCapture(source: .photoLibrary)
                } label: {
                    Label("Choose from Photos", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
                
                if DocumentScannerView.isSupported {
                    Button {
                        startCapture(source: .documentCamera)
                    } label: {
                        Label("Scan Document Page", systemImage: "doc.viewfinder")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 6)
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 20) {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor.opacity(0.5), lineWidth: 2)
                    )
                    .shadow(radius: 6)
            }
            
            ProgressView()
                .scaleEffect(1.3)
                .padding(.top, 8)
            
            Text("Recognizing Text...")
                .font(.headline)
            
            Text("Decoding words and sentences from the page image using on-device OCR.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }
    
    private func errorStateView(error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 54))
                .foregroundColor(.orange)
            
            Text("Could Not Read Page")
                .font(.title3)
                .fontWeight(.bold)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            VStack(spacing: 12) {
                Button {
                    resetState()
                    promptCaptureSource()
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button("Choose Another Photo") {
                    resetState()
                    startCapture(source: .photoLibrary)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func promptCaptureSource() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            startCapture(source: .standardCamera)
        } else if DocumentScannerView.isSupported {
            startCapture(source: .documentCamera)
        } else {
            startCapture(source: .photoLibrary)
        }
    }
    
    private func startCapture(source: OCRCaptureSource) {
        activeSource = source
    }
    
    private func processImage(_ image: UIImage) {
        self.capturedImage = image
        self.isProcessing = true
        self.errorMessage = nil
        
        Task {
            do {
                let result = try await QuoteOCRService.shared.processImage(image)
                await MainActor.run {
                    self.ocrResult = result
                    self.isProcessing = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isProcessing = false
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
    
    private func resetState() {
        self.ocrResult = nil
        self.capturedImage = nil
        self.errorMessage = nil
        self.isProcessing = false
    }
}
