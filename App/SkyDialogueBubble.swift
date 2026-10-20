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
            } else { introduction }
            actions.fixedSize(horizontal: false, vertical: true)
        }
    }

    private var introduction: some View {
            HStack(alignment: .top, spacing: StarfallTheme.Spacing.small) {
                if !textSize.isAccessibilitySize && !compact {
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
                if !embedded { Circle().fill(StarfallTheme.Dialogue.surface)
                    .overlay(Circle().stroke(StarfallTheme.Dialogue.brass.opacity(0.45), lineWidth: 1)) }
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
    private var scriptPresented: Bool { session.visible && session.scriptID != nil }
    private var line: SkyDialogueLine? { scriptPresented ? session.line : pausedLine ?? session.line }
    private var expanded: Bool { pausedLine != nil || session.visible }
    private var timerKey: String { "\(session.revision)-\(active)-\(pausedLine != nil)-\(voiceOver)" }

    var body: some View {
        Group {
            if let line {
                if expanded {
                    SkyDialogueBubble(line: line, maximumHeight: maximumHeight, compact: compact, embedded: embedded, embeddedInk: embeddedInk) {
                        if pausedLine != nil && !scriptPresented {
                            if !externalControls { actions }
                            if session.scriptID != nil, let retained = session.line {
                                Button(SkyCopy.text(.actionReadMessage, values: ["speaker": retained.speaker.name])) { session.reopen() }
                                    .buttonStyle(StarfallButtonStyle(role: .quiet))
                                    .accessibilityIdentifier("sky.dialogue.reopen")
                            }
                        }
                        else if !externalControls && (session.hasNext || line.seconds == nil || voiceOver) {
                            HStack {
                                if session.hasNext {
                                    Button(SkyCopy.text(.actionNextLine), action: next)
                                        .accessibilityIdentifier("sky.dialogue.next")
                                }
                                Spacer(minLength: 0)
                                Button(SkyCopy.text(.actionClose)) { session.dismiss() }
                                    .accessibilityIdentifier("sky.dialogue.close")
                            }
                            .buttonStyle(StarfallButtonStyle(role: .quiet))
                        }
                    }
                } else {
                    Button { session.reopen() } label: {
                        SkyDialoguePortrait(speaker: line.speaker, side: StarfallTheme.Layout.minimumTarget, embedded: true)
                    }
                        .buttonStyle(StarfallGameButtonStyle())
                        .accessibilityLabel(SkyCopy.text(.actionReadMessage, values: ["speaker": line.speaker.name]))
                        .accessibilityIdentifier("sky.dialogue.reopen")
                }
            }
        }
        .task(id: timerKey) {
            guard active, pausedLine == nil, !voiceOver, session.visible, !session.hasNext,
                  let seconds = session.line?.seconds else { return }
            let ticket = session.revision
            do { try await Task.sleep(for: .seconds(seconds)) } catch { return }
            guard !Task.isCancelled else { return }
            session.expire(revision: ticket)
        }
    }
}
