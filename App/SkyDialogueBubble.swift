import SwiftUI

/// A native, resizable speech surface. Portrait art contains neither frame nor text.
struct SkyDialogueBubble<Actions: View>: View {
    let line: SkyDialogueLine
    var messageIdentifier = "experiment.message"
    var maximumHeight: CGFloat? = nil
    var compact = false
    var embedded = false
    var embeddedInk = StarfallTheme.Colors.textPrimary
    @ViewBuilder let actions: Actions
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        fittedContent
        .frame(maxHeight: maximumHeight, alignment: .bottom)
        .frame(maxWidth: StarfallTheme.Layout.menuWidth)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sky.dialogue")
    }

    private var fittedContent: some View {
        Group {
            if let maximumHeight {
                // Fit the complete message and actions first. Only the introduction
                // scrolls when constrained, so native actions keep their full targets.
                ViewThatFits(in: .vertical) {
                    messageSurface(scrolling: false)
                        .fixedSize(horizontal: false, vertical: true)
                    messageSurface(scrolling: true)
                }
                .frame(maxHeight: maximumHeight, alignment: .bottom)
            } else {
                messageSurface(scrolling: false)
            }
        }
    }

    @ViewBuilder private func messageSurface(scrolling: Bool) -> some View {
        if embedded { messageContent(scrolling: scrolling) }
        else { messageContent(scrolling: scrolling).starfallPanel(inset: StarfallTheme.Spacing.medium) }
    }

    private func messageContent(scrolling: Bool) -> some View {
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
            if scrolling {
                ScrollView { introduction }
                    .scrollBounceBehavior(.basedOnSize)
                    .accessibilityIdentifier("sky.dialogue.reading")
            } else { introduction }
            actions.fixedSize(horizontal: false, vertical: true)
        }
    }

    private var introduction: some View {
            HStack(alignment: .top, spacing: StarfallTheme.Spacing.small) {
                if !textSize.isAccessibilitySize {
                    SkyDialoguePortrait(speaker: line.speaker, side: StarfallTheme.Landing.portraitSide, embedded: true)
                }
                VStack(alignment: .leading, spacing: StarfallTheme.Spacing.compact) {
                    Text(line.speaker.name)
                        .font(StarfallTheme.Typography.skyHeading)
                        .dynamicTypeSize(...StarfallTheme.Typography.GuideTitleRole.character.maximumTextSize)
                        .foregroundStyle(embedded ? embeddedInk : StarfallTheme.Dialogue.brass)
                        .accessibilityIdentifier("sky.guide.title")
                        .accessibilityHidden(true)
                    Text(line.text)
                        .font(StarfallTheme.Typography.supporting)
                        .foregroundStyle(embedded ? embeddedInk : StarfallTheme.Dialogue.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityRepresentation {
                Text(line.spokenText).accessibilityIdentifier(messageIdentifier)
            }
    }
}

struct SkyDialoguePortrait: View {
    let speaker: SkySpeaker
    var side = StarfallTheme.Dialogue.portraitSide
    var embedded = false
    var body: some View {
        Image(speaker.portraitAsset)
            .resizable().scaledToFit()
            .padding(StarfallTheme.Spacing.compact)
            .frame(width: side, height: side)
            .background {
                if !embedded { ObservatorySurface(skin: .utility) }
            }
            .accessibilityHidden(true)
    }
}

/// Dismissal is tied to message identity and lifecycle; expiry never commits a game event.
@MainActor struct SkyDialogueOverlay<Actions: View>: View {
    let session: SkyDialogueSession
    let pausedLine: SkyDialogueLine?
    let active: Bool
    let next: () -> Void
    var maximumHeight: CGFloat? = nil
    var compact = false
    var embedded = false
    var externalControls = false
    var embeddedInk = StarfallTheme.Colors.textPrimary
    @ViewBuilder let actions: Actions
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var pausedMessageVisible = false
    @State private var pausedMessageDismissed = false
    @State private var controlsHeight = StarfallTheme.Layout.preferenceTarget
    private var scriptPresented: Bool { session.visible && session.scriptID != nil }
    private var line: SkyDialogueLine? { scriptPresented ? session.line : pausedLine ?? session.line }
    private var expanded: Bool {
        session.visible || pausedMessageVisible || (voiceOver && pausedLine != nil && !pausedMessageDismissed)
    }
    private var timerKey: String { "\(session.revision)-\(active)-\(pausedLine != nil)-\(voiceOver)" }
    private var showsControls: Bool { pausedLine != nil && !externalControls }
    private var messageHeight: CGFloat? {
        maximumHeight.map { max(80, $0 - (showsControls ? controlsHeight + StarfallTheme.Spacing.small : 0)) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
            if let line {
                if expanded {
                    SkyDialogueBubble(line: line, maximumHeight: messageHeight, compact: compact, embedded: embedded, embeddedInk: embeddedInk) {
                        if pausedLine != nil && !scriptPresented {
                            if session.scriptID != nil, let retained = session.line {
                                Button(SkyCopy.text(.actionReadMessage, values: ["speaker": retained.speaker.name])) { session.reopen() }
                                    .buttonStyle(StarfallButtonStyle(role: .quiet))
                                    .accessibilityIdentifier("sky.dialogue.reopen")
                            }
                            Button(SkyCopy.text(.actionClose), action: close)
                                .buttonStyle(StarfallButtonStyle(role: .quiet))
                                .accessibilityIdentifier("sky.dialogue.close")
                        }
                        else if !externalControls && (session.hasNext || line.seconds == nil || voiceOver) {
                            scriptControls
                        }
                    }
                }
                if !expanded || showsControls {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: StarfallTheme.Spacing.small) {
                            if !expanded { portraitButton(line) }
                            if showsControls { actions }
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
                            if !expanded { portraitButton(line) }
                            if showsControls { actions }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: showsControls ? .center : .leading)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { controlsHeight = $0 }
                }
            }
        }
        .onChange(of: pausedLine?.id) {
            pausedMessageVisible = false
            pausedMessageDismissed = false
        }
        .task(id: timerKey) {
            guard active, !voiceOver, session.visible, !session.hasNext,
                  let seconds = session.line?.seconds else { return }
            let ticket = session.revision
            do { try await Task.sleep(for: .seconds(seconds)) } catch { return }
            guard !Task.isCancelled else { return }
            session.expire(revision: ticket)
        }
    }

    private var scriptControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: StarfallTheme.Spacing.small) { scriptButtons }
                .fixedSize(horizontal: true, vertical: false)
            VStack(alignment: .leading, spacing: StarfallTheme.Spacing.compact) { scriptButtons }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .buttonStyle(StarfallButtonStyle(role: .quiet, expands: true))
    }

    @ViewBuilder private var scriptButtons: some View {
        if session.hasNext {
            Button(SkyCopy.text(.actionNextLine), action: next)
                .accessibilityIdentifier("sky.dialogue.next")
        }
        Button(SkyCopy.text(.actionClose), action: close)
            .accessibilityIdentifier("sky.dialogue.close")
    }

    private func portraitButton(_ line: SkyDialogueLine) -> some View {
        Button(action: reopen) {
            SkyDialoguePortrait(speaker: line.speaker, side: StarfallTheme.Layout.minimumTarget)
        }
        .buttonStyle(StarfallGameButtonStyle())
        .accessibilityLabel(SkyCopy.text(.actionReadMessage, values: ["speaker": line.speaker.name]))
        .accessibilityIdentifier("sky.dialogue.reopen")
    }

    private func reopen() {
        pausedMessageDismissed = false
        if session.line != nil { session.reopen() }
        else { pausedMessageVisible = true }
    }

    private func close() {
        pausedMessageVisible = false
        pausedMessageDismissed = true
        session.dismiss()
    }
}
