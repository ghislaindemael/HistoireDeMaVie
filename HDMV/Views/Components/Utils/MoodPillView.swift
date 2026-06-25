//
//  MoodPillView.swift
//  HDMV
//
//  Created by Ghislain Demael on 24.06.2026.
//

import SwiftUI

struct MoodPillView: View {
    let mood: Int

    private var clampedMood: Int { min(max(mood, 0), 10) }

    private var label: String {
        switch clampedMood {
        case 0...1: return "Terrible"
        case 2...3: return "Bad"
        case 4: return "Low"
        case 5: return "Neutral"
        case 6: return "Okay"
        case 7...8: return "Good"
        default: return "Great"
        }
    }

    private var iconName: String {
        switch clampedMood {
        case 0...3: return "face.dashed"
        case 4...10: return "face.smiling"
        default: return "face.smiling.inverse"
        }
    }

    private var moodColor: Color {
        let stops: [Color] = [.red, .orange, .yellow, .green]
        let normalized = min(max(Double(clampedMood) / 10.0, 0), 1)

        let segmentCount = stops.count - 1
        let segment = min(Int(normalized * Double(segmentCount)), segmentCount - 1)
        let segmentStart = Double(segment) / Double(segmentCount)
        let segmentEnd = Double(segment + 1) / Double(segmentCount)
        let localProgress = (normalized - segmentStart) / (segmentEnd - segmentStart)

        let startColor = UIColor(stops[segment])
        let endColor = UIColor(stops[segment + 1])

        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)

        startColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        endColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let r = r1 + (r2 - r1) * CGFloat(localProgress)
        let g = g1 + (g2 - g1) * CGFloat(localProgress)
        let b = b1 + (b2 - b1) * CGFloat(localProgress)
        let a = a1 + (a2 - a1) * CGFloat(localProgress)

        return Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
            Text(label)
                .fontWeight(.semibold)
            Text("\(clampedMood)/10")
                .fontWeight(.medium)
                .opacity(0.75)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(moodColor.opacity(0.18))
        )
        .foregroundColor(moodColor)
        .animation(.easeInOut, value: clampedMood)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        ForEach(0...10, id: \.self) { i in
            MoodPillView(mood: i)
        }
    }
    .padding()
}
