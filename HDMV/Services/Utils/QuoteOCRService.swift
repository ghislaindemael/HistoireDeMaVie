//
//  QuoteOCRService.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.10.2026.
//

import UIKit
import Vision
import NaturalLanguage

struct OCRTextElement: Identifiable, Equatable {
    let id: UUID
    let text: String
    let boundingBox: CGRect // Normalized UIKit coordinates (0,0 is top-left, 1,1 is bottom-right)
    let paragraphIndex: Int
    let sentenceIndex: Int
}

struct OCRParagraph: Identifiable, Equatable {
    let id: UUID
    let text: String
    let sentences: [OCRTextElement]
    let paragraphIndex: Int
}

struct OCRResult: Equatable {
    let fullText: String
    let paragraphs: [OCRParagraph]
    let allSentences: [OCRTextElement]
    let image: UIImage
}

enum OCRError: LocalizedError {
    case invalidImage
    case recognitionFailed(String)
    case noTextFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to process the selected image."
        case .recognitionFailed(let message):
            return "Text recognition failed: \(message)"
        case .noTextFound:
            return "No readable text was detected on the page. Please ensure good lighting and clear text."
        }
    }
}

final class QuoteOCRService {
    static let shared = QuoteOCRService()
    
    private init() {}
    
    /// Processes a UIImage and returns recognized text structured into paragraphs and sentences.
    func processImage(_ image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        let orientation = cgOrientation(from: image.imageOrientation)
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { [weak self] request, error in
                guard let self = self else { return }
                
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let result = self.parseObservations(observations, originalImage: image)
                continuation.resume(returning: result)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            if #available(iOS 16.0, *) {
                request.automaticallyDetectsLanguage = true
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
            }
        }
    }
    
    // MARK: - Parsing
    
    private struct RawLine {
        let text: String
        let normalizedRect: CGRect // UIKit normalized
        let confidence: Float
    }
    
    private func parseObservations(_ observations: [VNRecognizedTextObservation], originalImage: UIImage) -> OCRResult {
        // Convert Vision coordinates (bottom-left origin) to UIKit coordinates (top-left origin)
        var rawLines: [RawLine] = []
        for obs in observations {
            guard let candidate = obs.topCandidates(1).first else { continue }
            let candidateText = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !candidateText.isEmpty else { continue }
            
            let box = obs.boundingBox
            let uiKitRect = CGRect(
                x: box.origin.x,
                y: 1.0 - box.origin.y - box.size.height,
                width: box.size.width,
                height: box.size.height
            )
            rawLines.append(RawLine(text: candidateText, normalizedRect: uiKitRect, confidence: candidate.confidence))
        }
        
        // Sort lines primarily by top (Y) position, secondarily by left (X)
        rawLines.sort { lineA, lineB in
            if abs(lineA.normalizedRect.midY - lineB.normalizedRect.midY) < (lineA.normalizedRect.height * 0.5) {
                return lineA.normalizedRect.minX < lineB.normalizedRect.minX
            }
            return lineA.normalizedRect.minY < lineB.normalizedRect.minY
        }
        
        // Group raw lines into paragraphs based on vertical spacing
        var paragraphLineGroups: [[RawLine]] = []
        var currentGroup: [RawLine] = []
        var lastLine: RawLine? = nil
        
        for line in rawLines {
            guard let previous = lastLine else {
                currentGroup.append(line)
                lastLine = line
                continue
            }
            
            let verticalGap = line.normalizedRect.minY - previous.normalizedRect.maxY
            let avgHeight = (line.normalizedRect.height + previous.normalizedRect.height) / 2.0
            
            // A gap greater than ~0.7x line height or an indented next line indicates a paragraph break
            let isSignificantGap = verticalGap > (avgHeight * 0.75)
            let isIndented = (line.normalizedRect.minX - previous.normalizedRect.minX) > (avgHeight * 0.8)
            let previousEndsWithPeriod = previous.text.hasSuffix(".") || previous.text.hasSuffix("!") || previous.text.hasSuffix("?")
            
            if isSignificantGap || (previousEndsWithPeriod && isIndented) {
                if !currentGroup.isEmpty {
                    paragraphLineGroups.append(currentGroup)
                    currentGroup = []
                }
            }
            
            currentGroup.append(line)
            lastLine = line
        }
        if !currentGroup.isEmpty {
            paragraphLineGroups.append(currentGroup)
        }
        
        // Build OCRParagraphs and split into clean sentences
        var parsedParagraphs: [OCRParagraph] = []
        var allSentences: [OCRTextElement] = []
        var fullTextParts: [String] = []
        
        for (pIndex, lineGroup) in paragraphLineGroups.enumerated() {
            // Join lines in paragraph cleanly handling hyphenation
            let joinedParagraphText = joinLinesHandlingHyphens(lineGroup.map { $0.text })
            guard !joinedParagraphText.isEmpty else { continue }
            
            fullTextParts.append(joinedParagraphText)
            
            // Sentence splitting using NLTokenizer
            let sentencesText = splitIntoSentences(joinedParagraphText)
            
            // Calculate an encompassing bounding box for the paragraph lines
            var minX: CGFloat = 1.0, minY: CGFloat = 1.0, maxX: CGFloat = 0.0, maxY: CGFloat = 0.0
            for line in lineGroup {
                minX = min(minX, line.normalizedRect.minX)
                minY = min(minY, line.normalizedRect.minY)
                maxX = max(maxX, line.normalizedRect.maxX)
                maxY = max(maxY, line.normalizedRect.maxY)
            }
            let paragraphRect = CGRect(x: minX, y: minY, width: max(0.01, maxX - minX), height: max(0.01, maxY - minY))
            
            var paragraphSentences: [OCRTextElement] = []
            let totalSentences = max(1, sentencesText.count)
            let sentenceSliceHeight = paragraphRect.height / CGFloat(totalSentences)
            
            for (sIndex, sentenceString) in sentencesText.enumerated() {
                // Approximate sentence vertical location within paragraph
                let sentenceRect = CGRect(
                    x: paragraphRect.minX,
                    y: paragraphRect.minY + (CGFloat(sIndex) * sentenceSliceHeight),
                    width: paragraphRect.width,
                    height: sentenceSliceHeight
                )
                
                let element = OCRTextElement(
                    id: UUID(),
                    text: sentenceString,
                    boundingBox: sentenceRect,
                    paragraphIndex: pIndex,
                    sentenceIndex: sIndex
                )
                paragraphSentences.append(element)
                allSentences.append(element)
            }
            
            let paragraph = OCRParagraph(
                id: UUID(),
                text: joinedParagraphText,
                sentences: paragraphSentences,
                paragraphIndex: pIndex
            )
            parsedParagraphs.append(paragraph)
        }
        
        let fullText = fullTextParts.joined(separator: "\n\n")
        return OCRResult(
            fullText: fullText,
            paragraphs: parsedParagraphs,
            allSentences: allSentences,
            image: originalImage
        )
    }
    
    /// Joins lines of a paragraph, reconnecting words broken across lines by a hyphen (e.g. "con- \n clusion" -> "conclusion").
    private func joinLinesHandlingHyphens(_ lines: [String]) -> String {
        var result = ""
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            if index == 0 {
                result = trimmed
                continue
            }
            
            if result.hasSuffix("-") {
                // Check if last word before hyphen continues as a word
                result.removeLast() // remove hyphen
                result.append(trimmed)
            } else if result.hasSuffix("—") || result.hasSuffix("–") {
                // Em dash / en dash usually don't need spaces or keep line break
                result.append(" " + trimmed)
            } else {
                result.append(" " + trimmed)
            }
        }
        return result
    }
    
    /// Splits paragraph text into clean sentences using NaturalLanguage tokenizer.
    private func splitIntoSentences(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let rawSentence = String(text[tokenRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !rawSentence.isEmpty {
                sentences.append(rawSentence)
            }
            return true
        }
        
        // Fallback if tokenizer returns empty
        if sentences.isEmpty && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sentences = [text.trimmingCharacters(in: .whitespacesAndNewlines)]
        }
        return sentences
    }
    
    private func cgOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
