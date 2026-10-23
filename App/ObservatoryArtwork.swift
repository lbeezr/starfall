import SwiftUI

/// Rendered utility artwork. Controls own their names, values and hit regions;
/// these images never become an extra accessibility element.
enum ObservatoryGlyph: String, CaseIterable {
    case story, freePlay = "freeplay", tutorial, settings, back, next, play, pause
    case sound, haptic, calm, home, replay, help, close, list, check, lock, direction, trace

    var assetName: String { "ObservatoryGlyph" + rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

    init?(systemName: String) {
        switch systemName {
        case "map", "map.fill", "book.closed", "book.closed.fill": self = .story
        case "sparkles", "sparkle", "star", "star.fill": self = .freePlay
        case "graduationcap", "graduationcap.fill", "point.3.connected.trianglepath.dotted": self = .tutorial
        case "gearshape", "gearshape.fill", "slider.horizontal.3": self = .settings
        case "chevron.left", "arrow.left": self = .back
        case "chevron.right", "arrow.right": self = .next
        case "play", "play.fill": self = .play
        case "pause", "pause.fill": self = .pause
        case "speaker.wave.2", "speaker.wave.2.fill": self = .sound
        case "waveform", "iphone.radiowaves.left.and.right": self = .haptic
        case "moon", "moon.fill", "moon.stars", "moon.stars.fill": self = .calm
        case "house", "house.fill": self = .home
        case "arrow.counterclockwise", "arrow.clockwise": self = .replay
        case "questionmark.circle", "questionmark.circle.fill", "lightbulb": self = .help
        case "xmark", "xmark.circle": self = .close
        case "list.bullet", "line.3.horizontal": self = .list
        case "checkmark", "checkmark.circle", "checkmark.circle.fill": self = .check
        case "lock", "lock.fill": self = .lock
        case "arrow.up.and.down.and.arrow.left.and.right": self = .direction
        case "hand.draw", "hand.draw.fill": self = .trace
        default: return nil
        }
    }
}

struct ObservatoryIcon: View {
    @Environment(\.isEnabled) private var enabled
    private let glyph: ObservatoryGlyph?
    private let systemName: String?
    let size: CGFloat

    init(_ glyph: ObservatoryGlyph, size: CGFloat = 24) {
        self.glyph = glyph
        systemName = nil
        self.size = size
    }

    /// Retained only for existing symbol-based call sites, including Debug tools.
    /// Unknown symbols keep their original meaning instead of becoming a wrong glyph.
    init(systemName: String, size: CGFloat = 24) {
        glyph = ObservatoryGlyph(systemName: systemName)
        self.systemName = systemName
        self.size = size
    }

    var body: some View {
        Group {
            if let glyph {
                Image(decorative: glyph.assetName)
                    .renderingMode(.original).resizable().scaledToFit()
            } else if let systemName {
                Image(systemName: systemName).resizable().scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .saturation(enabled ? 1 : 0.25)
        .opacity(enabled ? 1 : 0.5)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

enum ObservatoryMode: String, CaseIterable {
    case story, freePlay = "freeplay", tutorial
    var assetName: String { "ObservatoryEmblem" + rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
}

struct ObservatoryEmblem: View {
    let mode: ObservatoryMode
    let size: CGFloat

    init(_ mode: ObservatoryMode, size: CGFloat = 40) {
        self.mode = mode
        self.size = size
    }

    var body: some View {
        Image(decorative: mode.assetName)
            .resizable().scaledToFit().frame(width: size, height: size)
            .accessibilityHidden(true).allowsHitTesting(false)
    }
}

struct ObservatoryModeLabel: View {
    let mode: ObservatoryMode
    let title: String
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        Group {
            if textSize.isAccessibilitySize {
                VStack(spacing: StarfallTheme.Spacing.small) {
                    ObservatoryEmblem(mode)
                    Text(title).fixedSize(horizontal: false, vertical: true)
                }
            } else {
                HStack(spacing: StarfallTheme.Spacing.medium) {
                    ObservatoryEmblem(mode)
                    Text(title).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

/// Point registration comes from the retained production manifests, not pixels
/// inferred from whichever density the current device selects.
enum ObservatorySkin: CaseIterable {
    case action, reading, utility

    var assetName: String {
        switch self {
        case .action: "ObservatoryButtonAction"
        case .reading: "ObservatoryPanelReading"
        case .utility: "ObservatoryUtilityBezel"
        }
    }

    var pointSize: CGSize {
        switch self {
        case .action: CGSize(width: 320, height: 64)
        case .reading: CGSize(width: 160, height: 160)
        case .utility: CGSize(width: 32, height: 32)
        }
    }

    var capInsets: EdgeInsets {
        switch self {
        case .action: EdgeInsets(top: 0, leading: 48, bottom: 0, trailing: 48)
        case .reading: EdgeInsets(top: 32, leading: 32, bottom: 32, trailing: 32)
        case .utility: EdgeInsets()
        }
    }
}

/// A measured action grows before its text is laid out. The horizontal skin has
/// only two allowed heights; a wrapped/tall label receives the reading surface.
struct ObservatoryActionLayout: Layout {
    var expands: Bool

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        measurement(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let label = subviews.first else { return }
        let layout = measurement(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        label.place(at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center,
                    proposal: ProposedViewSize(width: max(0, bounds.width - layout.horizontalInset * 2), height: nil))
    }

    private func measurement(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, horizontalInset: CGFloat) {
        guard let label = subviews.first else { return (.zero, 0) }
        let available = proposal.width.flatMap { $0.isFinite ? $0 : nil }
        var horizontalInset: CGFloat = 52
        var labelSize = label.sizeThatFits(ProposedViewSize(width: available.map { max(0, $0 - horizontalInset * 2) }, height: nil))
        let contentHeight = ceil(labelSize.height + 24)
        let height: CGFloat
        let minimumWidth: CGFloat
        if contentHeight > 64 {
            horizontalInset = 32
            labelSize = label.sizeThatFits(ProposedViewSize(width: available.map { max(0, $0 - 64) }, height: nil))
            height = max(80, ceil(labelSize.height + 64))
            minimumWidth = 80
        } else {
            height = contentHeight <= 52 ? 52 : 64
            minimumWidth = height == 52 ? 98 : 120
        }
        let contentWidth = labelSize.width + horizontalInset * 2
        let width = expands ? (available ?? contentWidth) : contentWidth
        return (CGSize(width: max(minimumWidth, width), height: height), horizontalInset)
    }
}

/// Passive artwork only. Text, press/focus, accessibility and minimum touch
/// bounds are composed by the native control above it.
struct ObservatorySurface: View {
    var skin: ObservatorySkin = .reading
    var pressed = false
    var enabled = true
    var subdued = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if reduceTransparency || contrast == .increased {
                    RoundedRectangle(cornerRadius: StarfallTheme.Radius.control)
                        .fill(StarfallTheme.Colors.surface).padding(6)
                }
                artwork(size: geometry.size)
                    .saturation(enabled ? 1 : 0.15)
                    .brightness(enabled ? (pressed ? -0.12 : (subdued ? -0.04 : 0)) : -0.10)
                if contrast == .increased {
                    RoundedRectangle(cornerRadius: StarfallTheme.Radius.control)
                        .strokeBorder(StarfallTheme.Colors.outline, lineWidth: 1.5).padding(6)
                }
            }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }

    @ViewBuilder private func artwork(size: CGSize) -> some View {
        if skin == .action && size.height <= 64 {
            let scale = max(size.height / 64, 0.01)
            Image(decorative: skin.assetName)
                .resizable(capInsets: skin.capInsets, resizingMode: .stretch)
                .frame(width: size.width / scale, height: 64)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: size.width, height: size.height, alignment: .topLeading)
        } else if skin == .utility {
            Image(decorative: skin.assetName).resizable().scaledToFit()
        } else {
            Image(decorative: ObservatorySkin.reading.assetName)
                .resizable(capInsets: ObservatorySkin.reading.capInsets, resizingMode: .stretch)
        }
    }
}

private struct ObservatoryReadingPanel: ViewModifier {
    let inset: CGFloat
    func body(content: Content) -> some View {
        content.padding(max(32, inset))
            .frame(minWidth: 80, minHeight: 80)
            .background { ObservatorySurface() }
    }
}

/// A shallow enamel speech instrument. The caller owns content insets and size;
/// this passive background never clips the native reader or its actions.
struct ObservatoryDialogueSurface: View {
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: StarfallTheme.Dialogue.corner, style: .continuous)
        shape
            // Opaque enamel supplies the same backing with reduced transparency.
            .fill(LinearGradient(colors: [StarfallTheme.Dialogue.enamelHighlight,
                                         StarfallTheme.Dialogue.surface,
                                         StarfallTheme.Dialogue.enamelShade],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                shape.strokeBorder(LinearGradient(stops: [
                    .init(color: StarfallTheme.Dialogue.brass.opacity(contrast == .increased ? 1 : 0.8), location: 0),
                    .init(color: StarfallTheme.Dialogue.rimShade, location: 0.45),
                    .init(color: StarfallTheme.Dialogue.enamelShade, location: 1)
                ], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: contrast == .increased ? 1.5 : 1)
            }
            .overlay {
                shape.inset(by: 1.5).strokeBorder(LinearGradient(colors: [
                    StarfallTheme.Dialogue.ink.opacity(0.12), .clear, .clear
                ], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            }
            .shadow(color: StarfallTheme.Dialogue.contactShadow,
                    radius: StarfallTheme.Dialogue.shadowRadius, y: StarfallTheme.Dialogue.shadowDrop)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// The same authored enamel and fittings at half scale. Compact controls keep
/// shallow edges; their content padding and native hit region remain independent.
struct ObservatoryCompactSurface: View {
    var pressed = false
    var enabled = true
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                if reduceTransparency || contrast == .increased {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(StarfallTheme.Colors.surface).padding(3)
                }
                Image(decorative: ObservatorySkin.reading.assetName)
                    .resizable(capInsets: ObservatorySkin.reading.capInsets, resizingMode: .stretch)
                    .frame(width: geometry.size.width * 2, height: geometry.size.height * 2)
                    .scaleEffect(0.5, anchor: .topLeading)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                    .saturation(enabled ? 1 : 0.15)
                    .brightness(enabled ? (pressed ? -0.12 : 0) : -0.10)
                if contrast == .increased {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(StarfallTheme.Colors.outline, lineWidth: 1.5).padding(3)
                }
            }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

extension View {
    func observatoryReadingPanel(inset: CGFloat = 32) -> some View {
        modifier(ObservatoryReadingPanel(inset: inset))
    }
}

/// A native Toggle representation preserves switch labels, values and actions.
/// The visible thumb also carries a check, so hue is never its only state cue.
struct ObservatoryToggleStyle: ToggleStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.dynamicTypeSize) private var textSize

    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            Group {
                if textSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
                        configuration.label.fixedSize(horizontal: false, vertical: true)
                        indicator(isOn: configuration.isOn)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack(spacing: StarfallTheme.Spacing.large) {
                        configuration.label.fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: StarfallTheme.Spacing.small)
                        indicator(isOn: configuration.isOn)
                    }
                }
            }
            .font(StarfallTheme.Typography.body)
            .foregroundStyle(isEnabled ? StarfallTheme.Colors.textPrimary : StarfallTheme.Colors.textDisabled)
            .frame(minHeight: StarfallTheme.Layout.preferenceTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(ObservatoryTogglePressStyle())
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }.toggleStyle(.switch)
        }
    }

    private func indicator(isOn: Bool) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule().fill(StarfallTheme.Colors.surface)
            Capsule().strokeBorder(isOn ? StarfallTheme.Colors.actionPrimary : StarfallTheme.Colors.outline, lineWidth: 1)
            Circle().fill(isEnabled ? StarfallTheme.Colors.textPrimary : StarfallTheme.Colors.textDisabled)
                .overlay {
                    if isOn {
                        ObservatoryIcon(.check, size: 14).foregroundStyle(StarfallTheme.Colors.surface)
                    } else {
                        Circle().strokeBorder(StarfallTheme.Colors.surface, lineWidth: 1.5).frame(width: 6, height: 6)
                    }
                }
                .frame(width: 22, height: 22).padding(3)
        }
        .frame(width: 48, height: 28)
        .accessibilityHidden(true)
    }
}

private struct ObservatoryTogglePressStyle: ButtonStyle {
    @Environment(\.isFocused) private var focused
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? StarfallTheme.Colors.surfacePressed : .clear,
                        in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                if focused {
                    RoundedRectangle(cornerRadius: 8).strokeBorder(StarfallTheme.Colors.focus, lineWidth: 2)
                }
            }
            .transaction { $0.animation = nil }
    }
}
