import SwiftUI

/// A native, resizable speech surface. Portrait art contains neither frame nor text.
struct SkyDialogueBubble<Actions: View>: View {
    let line: SkyDialogueLine
    var messageIdentifier = "experiment.message"
    var maximumHeight: CGFloat? = nil
    @ViewBuilder let actions: Actions
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
            if maximumHeight != nil {
                ViewThatFits(in: .vertical) {
                    introduction.fixedSize(horizontal: false, vertical: true)
                    ScrollView { introduction }
                }
            } else { introduction }
            actions
        }
        .padding(StarfallTheme.Spacing.medium)
        .background {
            SkySpeechShape(tail: !textSize.isAccessibilitySize)
                .fill(StarfallTheme.Dialogue.surface)
                .overlay {
                    SkySpeechShape(tail: !textSize.isAccessibilitySize)
                        .stroke(StarfallTheme.Dialogue.brass.opacity(0.8), lineWidth: 1)
                }
                .shadow(color: StarfallTheme.Colors.skyTop.opacity(0.55), radius: 5, y: 3)
        }
        .frame(maxHeight: maximumHeight, alignment: .bottom)
        .padding(.leading, textSize.isAccessibilitySize ? 0 : StarfallTheme.Dialogue.portraitOverlap)
        .frame(maxWidth: StarfallTheme.Layout.menuWidth)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sky.dialogue")
    }
    private var introduction: some View {
            HStack(alignment: .top, spacing: StarfallTheme.Spacing.small) {
                if !textSize.isAccessibilitySize {
                    SkyDialoguePortrait(speaker: line.speaker)
                        .padding(.leading, -StarfallTheme.Dialogue.portraitOverlap)
                        .padding(.top, -StarfallTheme.Spacing.small)
                }
                VStack(alignment: .leading, spacing: StarfallTheme.Spacing.compact) {
                    Text(line.speaker.name)
                        .font(StarfallTheme.Typography.skyHeading)
                        .dynamicTypeSize(...StarfallTheme.Typography.GuideTitleRole.character.maximumTextSize)
                        .foregroundStyle(StarfallTheme.Dialogue.brass)
                        .accessibilityIdentifier("sky.guide.title")
                        .accessibilityHidden(true)
                    Text(line.text)
                        .font(StarfallTheme.Typography.supporting)
                        .foregroundStyle(StarfallTheme.Dialogue.ink)
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
    var body: some View {
        Image(speaker.portraitAsset)
            .resizable().scaledToFit()
            .padding(StarfallTheme.Spacing.compact)
            .frame(width: side, height: side)
            .background {
                Circle().fill(StarfallTheme.Dialogue.surface)
                    .overlay(Circle().stroke(StarfallTheme.Dialogue.brass.opacity(0.8), lineWidth: 1))
            }
            .accessibilityHidden(true)
    }
}

/// The small leading tail joins the portrait; text remains inside the rounded body.
private struct SkySpeechShape: Shape {
    let tail: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: StarfallTheme.Dialogue.corner)
        if tail {
            path.move(to: CGPoint(x: 1, y: 26))
            path.addQuadCurve(to: CGPoint(x: -9, y: 38), control: CGPoint(x: -2, y: 34))
            path.addQuadCurve(to: CGPoint(x: 1, y: 46), control: CGPoint(x: -2, y: 42))
            path.closeSubpath()
        }
        return path
    }
}

/// Dismissal is tied to message identity and lifecycle; expiry never commits a game event.
@MainActor struct SkyDialogueOverlay<Actions: View>: View {
    let session: SkyDialogueSession
    let pausedLine: SkyDialogueLine?
    let active: Bool
    let next: () -> Void
    var maximumHeight: CGFloat? = nil
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
                    SkyDialogueBubble(line: line, maximumHeight: maximumHeight) {
                        if pausedLine != nil && !scriptPresented {
                            actions
                            if session.scriptID != nil, let retained = session.line {
                                Button(SkyCopy.text(.actionReadMessage, values: ["speaker": retained.speaker.name])) { session.reopen() }
                                    .buttonStyle(StarfallButtonStyle(role: .quiet))
                                    .accessibilityIdentifier("sky.dialogue.reopen")
                            }
                        }
                        else if session.hasNext || line.seconds == nil || voiceOver {
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
                    Button { session.reopen() } label: { SkyDialoguePortrait(speaker: line.speaker, side: 48) }
                        .buttonStyle(.plain)
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
