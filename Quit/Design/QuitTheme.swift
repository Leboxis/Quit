import SwiftUI

enum QuitTheme {
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let text = Color("TextPrimary")
    static let secondary = Color("TextSecondary")
    static let amber = Color("Amber")
    static let border = Color("Border")
}

// Content colors complement the user's accent; primary actions keep that accent.
enum QuitTone {
    case reflection, support, preparation

    var color: Color {
        switch self {
        case .reflection: Color("SlateAccent")
        case .support: Color("PlumAccent")
        case .preparation: QuitTheme.amber
        }
    }
    var soft: Color {
        switch self {
        case .reflection: Color("SlateSoft")
        case .support: Color("PlumSoft")
        case .preparation: Color("AmberSoft")
        }
    }
}

struct QuitSectionTitle: View {
    let title: String
    let symbol: String
    var tone: QuitTone? = nil
    @Environment(\.quitAccent) private var accent

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.headline)
            .foregroundStyle(tone?.color ?? accent.color)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
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
    var tone: QuitTone? = nil
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(tinted ? (tone?.soft ?? accent.soft) : QuitTheme.surface,
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
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
                    .fixedSize(horizontal: false, vertical: true)
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
    @ScaledMetric(relativeTo: .body) private var symbolSize = 36.0
    let title: String
    var detail: String? = nil
    let symbol: String
    var tone: QuitTone? = nil
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.body.weight(.medium))
                .foregroundStyle(tone?.color ?? accent.color)
                .frame(width: symbolSize, height: symbolSize)
                .background(tone?.soft ?? accent.soft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(QuitTheme.text)
                if let detail { Text(detail).font(.subheadline).foregroundStyle(QuitTheme.secondary) }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(QuitTheme.secondary)
                .accessibilityHidden(true)
        }
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}

struct ScreenContent<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) { content }
                .frame(maxWidth: 620)
                .padding(.horizontal, 18)
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var choiceWidth = 100.0
    @Binding var selection: Emotion
    var body: some View {
        LazyVGrid(columns: dynamicTypeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: choiceWidth))], spacing: 10) {
            ForEach(Emotion.allCases) { emotion in
                Button {
                    selection = emotion
                } label: {
                    Label(emotion.title, systemImage: emotion.symbol)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(selection == emotion ? accent.foreground : QuitTheme.text)
                        .background(selection == emotion ? accent.color : QuitTheme.surface, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("emotion.\(emotion.rawValue)")
                .accessibilityAddTraits(selection == emotion ? [.isSelected] : [])
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: selection)
        .sensoryFeedback(.selection, trigger: selection) { _, _ in haptics }
    }
}

struct IntensitySlider: View {
    @Environment(\.quitAccent) private var accent
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    @Binding var value: Double
    var body: some View {
        VStack(spacing: 14) {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
            layout {
                Text(title).font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(value))").font(.system(.largeTitle, design: .rounded, weight: .medium)).monospacedDigit()
                    Text("/ 10").foregroundStyle(QuitTheme.secondary)
                }
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

// Native menu choices can grow vertically where segmented labels cannot fit.
struct QuitAdaptivePickerStyle: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ViewBuilder func body(content: Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            content.pickerStyle(.menu).frame(minHeight: 44)
        } else {
            content.pickerStyle(.segmented)
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
