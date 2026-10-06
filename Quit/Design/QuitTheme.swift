import SwiftUI

enum QuitTheme {
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let text = Color("TextPrimary")
    static let secondary = Color("TextSecondary")
    static let amber = Color("Amber")
    static let border = Color("Border")
}

extension AccentTheme {
    var color: Color {
        switch self { case .sage: Color("AccentColor"); case .slate: Color("SlateAccent"); case .sand: Color("SandAccent") }
    }
    var soft: Color {
        switch self { case .sage: Color("AccentSoft"); case .slate: Color("SlateSoft"); case .sand: Color("SandSoft") }
    }
    var foreground: Color { Color("OnAccent") }
}

extension AppAppearance {
    var colorScheme: ColorScheme? {
        switch self { case .system: nil; case .light: .light; case .dark: .dark }
    }
}

extension EnvironmentValues {
    @Entry var quitAccent: AccentTheme = .sage
    @Entry var quitHaptics = true
    @Entry var quitReduceMotion = false
}

struct QuitCard<Content: View>: View {
    @Environment(\.quitAccent) private var accent
    @Environment(\.colorSchemeContrast) private var contrast
    var tinted = false
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 16) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .background(tinted ? accent.soft : QuitTheme.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(QuitTheme.border.opacity(contrast == .increased ? 1 : 0.45), lineWidth: contrast == .increased ? 1.5 : 0.5)
            }
    }
}

struct QuitPrimaryButton: View {
    @Environment(\.quitAccent) private var accent
    let title: String
    var symbol: String? = nil
    var action: () -> Void
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.quitHaptics) private var haptics
    @State private var feedback = 0

    var body: some View {
        if #available(iOS 26, *), !reduceTransparency {
            button.buttonStyle(.glassProminent).tint(accent.color)
        } else {
            button.buttonStyle(.borderedProminent).tint(accent.color)
        }
    }

    private var button: some View {
        Button { feedback += 1; action() } label: {
            HStack(spacing: 10) {
                if let symbol { Image(systemName: symbol) }
                Text(title).font(.headline)
            }
            .foregroundStyle(accent.foreground)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonBorderShape(.capsule)
        .sensoryFeedback(.selection, trigger: feedback) { _, _ in haptics }
    }
}

struct QuietRow: View {
    @Environment(\.quitAccent) private var accent
    let title: String
    var detail: String? = nil
    let symbol: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.title3).foregroundStyle(accent.color)
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
        .scrollDismissesKeyboard(.interactively)
    }
}

struct QuitBottomBar<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 10) { content }
            .frame(maxWidth: 620)
            .padding(.horizontal, 22).padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(QuitTheme.background)
            .overlay(alignment: .top) { Rectangle().fill(QuitTheme.border.opacity(0.5)).frame(height: 0.5) }
    }
}

struct EmotionPicker: View {
    @Environment(\.quitAccent) private var accent
    @Environment(\.quitReduceMotion) private var reduceMotion
    @Environment(\.quitHaptics) private var haptics
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
                        .foregroundStyle(selection == emotion ? accent.foreground : QuitTheme.text)
                        .background(selection == emotion ? accent.color : QuitTheme.surface, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == emotion ? [.isSelected] : [])
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: selection)
        .sensoryFeedback(.selection, trigger: selection) { _, _ in haptics }
    }
}

struct IntensitySlider: View {
    @Environment(\.quitAccent) private var accent
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
                .tint(accent.color)
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
    @Environment(\.quitAccent) private var accent
    @Environment(\.quitReduceMotion) private var reduceMotion
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
                    canvas.stroke(path, with: .color(accent.color.opacity(0.12 + Double(line) * 0.035)), lineWidth: 1.2)
                }
            }
        }
        .accessibilityHidden(true)
    }
}
