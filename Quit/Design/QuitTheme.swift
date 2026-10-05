import SwiftUI

enum QuitTheme {
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let accent = Color("AccentColor")
    static let accentSoft = Color("AccentSoft")
    static let text = Color("TextPrimary")
    static let secondary = Color("TextSecondary")
    static let amber = Color("Amber")
    static let border = Color("Border")
    static let onAccent = Color("OnAccent")
}

struct QuitCard<Content: View>: View {
    var tinted = false
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 16) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .background(tinted ? QuitTheme.accentSoft : QuitTheme.surface, in: RoundedRectangle(cornerRadius: 24))
    }
}

struct QuitPrimaryButton: View {
    let title: String
    var symbol: String? = nil
    var action: () -> Void
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if #available(iOS 26, *), !reduceTransparency {
            button.buttonStyle(.glassProminent).tint(QuitTheme.accent)
        } else {
            button.buttonStyle(.borderedProminent).tint(QuitTheme.accent)
        }
    }

    private var button: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let symbol { Image(systemName: symbol) }
                Text(title).font(.headline)
            }
            .foregroundStyle(QuitTheme.onAccent)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonBorderShape(.capsule)
    }
}

struct QuietRow: View {
    let title: String
    var detail: String? = nil
    let symbol: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.title3).foregroundStyle(QuitTheme.accent)
                .frame(width: 38, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(QuitTheme.text)
                if let detail { Text(detail).font(.subheadline).foregroundStyle(QuitTheme.secondary) }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(QuitTheme.secondary)
        }
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}

struct ScreenContent<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) { content }
                .frame(maxWidth: 620)
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)
        }
        .background(QuitTheme.background)
        .foregroundStyle(QuitTheme.text)
    }
}

struct EmotionPicker: View {
    @Binding var selection: Emotion
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
            ForEach(Emotion.allCases) { emotion in
                Button {
                    selection = emotion
                } label: {
                    Label(emotion.title, systemImage: emotion.symbol)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(selection == emotion ? QuitTheme.onAccent : QuitTheme.text)
                        .background(selection == emotion ? QuitTheme.accent : QuitTheme.surface, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == emotion ? [.isSelected] : [])
            }
        }
    }
}

struct IntensitySlider: View {
    let title: String
    @Binding var value: Double
    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.headline)
                Spacer()
                Text("\(Int(value))").font(.system(.largeTitle, design: .rounded, weight: .medium)).monospacedDigit()
                Text("/ 10").foregroundStyle(QuitTheme.secondary)
            }
            Slider(value: $value, in: 0...10, step: 1) { Text(title) }
                .tint(QuitTheme.accent)
                .accessibilityValue("\(Int(value)) sur 10")
            HStack {
                Text("Faible")
                Spacer()
                Text("Intense")
            }.font(.caption).foregroundStyle(QuitTheme.secondary)
        }
    }
}

struct ContourArtwork: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var animated = false
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !animated || reduceMotion)) { context in
            let phase = animated && !reduceMotion ? context.date.timeIntervalSinceReferenceDate / 8 : 0
            Canvas { canvas, size in
                for line in 0..<9 {
                    var path = Path()
                    for point in 0...80 {
                        let x = size.width * Double(point) / 80
                        let fraction = x / size.width
                        let y = size.height * 0.52 + sin(fraction * .pi * 2 + phase + Double(line) * 0.12) * size.height * 0.16 + Double(line - 4) * 9
                        if point == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    canvas.stroke(path, with: .color(QuitTheme.accent.opacity(0.12 + Double(line) * 0.035)), lineWidth: 1.2)
                }
            }
        }
        .accessibilityHidden(true)
    }
}
