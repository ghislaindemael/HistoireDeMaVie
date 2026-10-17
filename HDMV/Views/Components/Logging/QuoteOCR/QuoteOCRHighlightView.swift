//
//  QuoteOCRHighlightView.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.10.2026.
//

import SwiftUI

enum OCRViewMode: String, CaseIterable, Identifiable {
    case highlighter = "Highlight"
    case pageImage = "Page View"
    case manualEdit = "Edit / Refine"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .highlighter: return "highlighter"
        case .pageImage: return "doc.text.image"
        case .manualEdit: return "pencil.line"
        }
    }
}

struct QuoteOCRHighlightView: View {
    let result: OCRResult
    var existingQuoteText: String
    var onQuoteSelected: (String) -> Void
    var onRetake: () -> Void
    
    @State private var viewMode: OCRViewMode = .highlighter
    @State private var selectedSentenceIds: Set<UUID> = []
    @State private var manualText: String = ""
    @State private var showReplaceConfirmation: Bool = false
    @State private var isZoomedImage: Bool = false
    
    // Computed compiled quote text from selected sentences in reading order
    private var compiledSelectedText: String {
        let selectedSentences = result.allSentences.filter { selectedSentenceIds.contains($0.id) }
        return selectedSentences.map { $0.text }.joined(separator: " ")
    }
    
    private var activeQuoteText: String {
        if viewMode == .manualEdit {
            return manualText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return compiledSelectedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Mode Selector Bar
            Picker("View Mode", selection: $viewMode) {
                ForEach(OCRViewMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.iconName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 6)
            
            Divider()
            
            // Content Area depending on mode
            ZStack {
                switch viewMode {
                case .highlighter:
                    highlighterModeView
                case .pageImage:
                    pageImageModeView
                case .manualEdit:
                    manualEditModeView
                }
            }
            
            Divider()
            
            // Pinned Bottom Quote Preview & Action Bar
            bottomActionBar
        }
        .onChange(of: viewMode) { _, newMode in
            if newMode == .manualEdit && manualText.isEmpty {
                // Initialize manual text with current selection or full text if empty
                manualText = compiledSelectedText.isEmpty ? result.fullText : compiledSelectedText
            }
        }
    }
    
    // MARK: - Highlighter Mode View
    
    private var highlighterModeView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Hint Banner
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(.yellow)
                    Text("Tap any sentence to highlight it as part of your quote.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    if !selectedSentenceIds.isEmpty {
                        Button("Clear") {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedSentenceIds.removeAll()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    
                    Button("Select All") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedSentenceIds = Set(result.allSentences.map { $0.id })
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                
                // Document / Book Page Content
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(result.paragraphs) { paragraph in
                        VStack(alignment: .leading, spacing: 8) {
                            // Paragraph Header / Quick Action
                            HStack {
                                Text("Paragraph \(paragraph.paragraphIndex + 1)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                Spacer()
                                
                                let allInParagraphSelected = paragraph.sentences.allSatisfy { selectedSentenceIds.contains($0.id) }
                                Button(allInParagraphSelected ? "Deselect" : "Select Paragraph") {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if allInParagraphSelected {
                                        for s in paragraph.sentences {
                                            selectedSentenceIds.remove(s.id)
                                        }
                                    } else {
                                        for s in paragraph.sentences {
                                            selectedSentenceIds.insert(s.id)
                                        }
                                    }
                                }
                                .font(.caption2)
                                .foregroundColor(.accentColor)
                            }
                            
                            // Flowing sentences in paragraph
                            FlowSentencesView(
                                sentences: paragraph.sentences,
                                selectedIds: $selectedSentenceIds
                            )
                        }
                        .padding(.vertical, 4)
                        
                        if paragraph.id != result.paragraphs.last?.id {
                            Divider()
                                .opacity(0.4)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                )
            }
            .padding()
        }
    }
    
    // MARK: - Page Image Mode View
    
    private var pageImageModeView: some View {
        GeometryReader { proxy in
            let viewSize = proxy.size
            let imageRatio = result.image.size.width / max(1, result.image.size.height)
            let viewRatio = viewSize.width / max(1, viewSize.height)
            
            // Calculate fitted image rect inside container
            let fittedWidth = viewRatio > imageRatio ? viewSize.height * imageRatio : viewSize.width
            let fittedHeight = viewRatio > imageRatio ? viewSize.height : viewSize.width / imageRatio
            let offsetX = (viewSize.width - fittedWidth) / 2
            let offsetY = (viewSize.height - fittedHeight) / 2
            
            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    Image(uiImage: result.image)
                        .resizable()
                        .frame(width: fittedWidth, height: fittedHeight)
                    
                    // Overlaid Bounding Box Highlights
                    ForEach(result.allSentences) { sentence in
                        let isSelected = selectedSentenceIds.contains(sentence.id)
                        let boxRect = CGRect(
                            x: sentence.boundingBox.minX * fittedWidth,
                            y: sentence.boundingBox.minY * fittedHeight,
                            width: sentence.boundingBox.width * fittedWidth,
                            height: sentence.boundingBox.height * fittedHeight
                        )
                        
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            if isSelected {
                                selectedSentenceIds.remove(sentence.id)
                            } else {
                                selectedSentenceIds.insert(sentence.id)
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isSelected ? Color.yellow.opacity(0.45) : Color.blue.opacity(0.08))
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(isSelected ? Color.yellow : Color.blue.opacity(0.25), lineWidth: isSelected ? 2 : 1)
                            }
                        }
                        .frame(width: max(20, boxRect.width), height: max(16, boxRect.height))
                        .position(x: boxRect.midX, y: boxRect.midY)
                    }
                }
                .frame(width: fittedWidth, height: fittedHeight)
                .padding(.horizontal, max(0, offsetX))
                .padding(.vertical, max(0, offsetY))
            }
        }
    }
    
    // MARK: - Manual Edit Mode View
    
    private var manualEditModeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Refine Quote Text")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Button("Reset from Highlights") {
                    manualText = compiledSelectedText.isEmpty ? result.fullText : compiledSelectedText
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            TextEditor(text: $manualText)
                .font(.body)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            
            Text("Tip: You can remove footnote numbers, fix OCR spelling, or customize phrasing here.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 6)
        }
    }
    
    // MARK: - Bottom Action Bar & Preview
    
    private var bottomActionBar: some View {
        VStack(spacing: 12) {
            let quoteText = activeQuoteText
            let isQuoteEmpty = quoteText.isEmpty
            
            // Preview Bubble
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "quote.opening")
                    .font(.title3)
                    .foregroundColor(isQuoteEmpty ? .secondary.opacity(0.4) : .yellow)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    if isQuoteEmpty {
                        Text("No text highlighted yet. Tap sentences on the page above to build your quote.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        Text("“\(quoteText)”")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                        
                        let words = quoteText.split { $0.isWhitespace }.count
                        HStack(spacing: 8) {
                            Text("\(words) word\(words == 1 ? "" : "s")")
                            Text("•")
                            Text("\(quoteText.count) characters")
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onRetake) {
                    Label("Retake", systemImage: "camera")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.tertiarySystemFill))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                
                Button {
                    commitSelectedQuote()
                } label: {
                    Label("Use This Quote", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isQuoteEmpty ? Color.gray.opacity(0.3) : Color.accentColor)
                        .foregroundColor(isQuoteEmpty ? .secondary : .white)
                        .cornerRadius(10)
                }
                .disabled(isQuoteEmpty)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .confirmationDialog(
            "Replace Existing Quote?",
            isPresented: $showReplaceConfirmation,
            titleVisibility: .visible
        ) {
            Button("Replace Quote Content", role: .destructive) {
                onQuoteSelected(activeQuoteText)
            }
            Button("Append to Existing Quote") {
                let merged = existingQuoteText + "\n\n" + activeQuoteText
                onQuoteSelected(merged)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You already have text in this quote. Do you want to replace it or append this new excerpt?")
        }
    }
    
    private func commitSelectedQuote() {
        let quote = activeQuoteText
        guard !quote.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        if !existingQuoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showReplaceConfirmation = true
        } else {
            onQuoteSelected(quote)
        }
    }
}

// MARK: - Flow Sentences View

/// Displays sentences flowing within a paragraph with interactive fluorescent highlighter styling
struct FlowSentencesView: View {
    let sentences: [OCRTextElement]
    @Binding var selectedIds: Set<UUID>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(sentences) { sentence in
                let isSelected = selectedIds.contains(sentence.id)
                
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if isSelected {
                        selectedIds.remove(sentence.id)
                    } else {
                        selectedIds.insert(sentence.id)
                    }
                } label: {
                    HStack(alignment: .center, spacing: 8) {
                        // Highlighter marker indicator
                        Capsule()
                            .fill(isSelected ? Color.yellow : Color.clear)
                            .frame(width: 4)
                            .padding(.vertical, 2)
                        
                        Text(sentence.text)
                            .font(.system(.body, design: .serif))
                            .lineSpacing(4)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isSelected ? Color.yellow.opacity(0.35) : Color.clear)
                            )
                        
                        Spacer(minLength: 0)
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.yellow.opacity(0.12) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
