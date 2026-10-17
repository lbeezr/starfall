import SwiftUI

/// Environmental presentation receives lifecycle values, never a game store.
@MainActor struct ObservatoryEnvironment: View {
    let active: Bool
    let reducedMotion: Bool
    @State private var clock = ObservatoryAmbientClock()
    @State private var response: ObservatoryProp?
    @State private var responseTask: Task<Void, Never>?
    @State private var generation = 0
    private var running: Bool { active && !reducedMotion }

    var body: some View {
        GeometryReader { geometry in
            let mapping = ObservatoryGeometry(size: geometry.size)
            let imageRect = mapping.imageRect
            TimelineView(.animation(minimumInterval: 1.0/24, paused: !running)) { _ in
                let time = clock.phase(at: ProcessInfo.processInfo.systemUptime)
                ZStack {
                    Image("ObservatoryBackground").resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                        .blur(radius: 24).overlay(StarfallTheme.Colors.skyTop.opacity(0.3))
                        .allowsHitTesting(false).accessibilityHidden(true)
                    layer("ObservatoryBackground", in: imageRect)
                        .mask {
                            LinearGradient(stops: [.init(color: .clear, location: 0),
                                                   .init(color: .black, location: 0.035),
                                                   .init(color: .black, location: 0.965),
                                                   .init(color: .clear, location: 1)],
                                           startPoint: .leading, endPoint: .trailing)
                                .frame(width: imageRect.width, height: geometry.size.height)
                                .position(x: imageRect.midX, y: geometry.size.height/2)
                        }
                        .mask {
                            LinearGradient(stops: [.init(color: .clear, location: 0),
                                                   .init(color: .black, location: 0.025),
                                                   .init(color: .black, location: 0.975),
                                                   .init(color: .clear, location: 1)],
                                           startPoint: .top, endPoint: .bottom)
                                .frame(width: imageRect.width, height: imageRect.height)
                                .position(x: imageRect.midX, y: imageRect.midY)
                        }
                    let glow = mapping.artworkPoint(x: 0.925, y: 0.79)
                    RadialGradient(colors: [StarfallTheme.Observatory.lanternGlow.opacity(response == .lantern ? 0.43 : 0.10 + (reducedMotion ? 0 : sin(time/4)*0.015)), .clear],
                                   center: .center, startRadius: 0, endRadius: 90)
                        .frame(width: 180, height: 180).position(glow)
                        .allowsHitTesting(false).accessibilityHidden(true)
                    registeredProp(.telescope, mapping: mapping)
                    registeredProp(.lantern, mapping: mapping)
                    layer("ObservatoryFog", in: imageRect)
                        .offset(x: reducedMotion ? 0 : sin(time/12)*22, y: reducedMotion ? 0 : cos(time/18)*5)
                        .opacity(StarfallTheme.Observatory.fogOpacity)
                    layer("ObservatoryFog", in: imageRect)
                        .offset(x: reducedMotion ? 0 : -sin(time/19)*14, y: 12)
                        .opacity(StarfallTheme.Observatory.fogOpacity*0.5)
                    if response == .telescope {
                        let lens = mapping.artworkPoint(x: 0.25, y: 0.10)
                        Circle().fill(StarfallTheme.Colors.actionPrimary.opacity(0.8))
                            .frame(width: 5, height: 5)
                            .shadow(color: StarfallTheme.Colors.actionPrimary, radius: 8)
                            .position(lens).allowsHitTesting(false).accessibilityHidden(true)
                    }
                    if active {
                        propButton(.telescope, mapping: mapping)
                        propButton(.lantern, mapping: mapping)
                    }
                }
            }
            .clipped()
        }
        .animation(reducedMotion ? nil : .easeInOut(duration: 0.35), value: response)
        .onAppear { clock.setRunning(running, at: ProcessInfo.processInfo.systemUptime) }
        .onChange(of: running) { _, value in clock.setRunning(value, at: ProcessInfo.processInfo.systemUptime) }
        .onChange(of: active) { _, value in if !value { cancelResponse() } }
        .onDisappear {
            clock.setRunning(false, at: ProcessInfo.processInfo.systemUptime)
            cancelResponse()
        }
    }
    private func layer(_ name: String, in rect: CGRect) -> some View {
        Image(name).resizable().frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
    private func registeredProp(_ prop: ObservatoryProp, mapping: ObservatoryGeometry) -> some View {
        let source = mapping.propSourceFrame(prop)
        let target = mapping.propArtworkFrame(prop)
        let image = mapping.imageRect
        let scale = target.width/source.width
        let width = image.width*scale, height = image.height*scale
        let targetPoint = mapping.artworkPoint(x: target.minX, y: target.minY)
        return Image(prop == .telescope ? "ObservatoryTelescope" : "ObservatoryLantern")
            .resizable().frame(width: width, height: height)
            .rotationEffect(.degrees(response == prop && !reducedMotion ? (prop == .telescope ? -3 : 3) : 0),
                            anchor: UnitPoint(x: source.midX, y: source.maxY))
            .brightness(response == .lantern && prop == .lantern ? 0.12 : 0)
            .position(x: targetPoint.x+(0.5-source.minX)*width,
                      y: targetPoint.y+(0.5-source.minY)*height)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
    private func propButton(_ prop: ObservatoryProp, mapping: ObservatoryGeometry) -> some View {
        let rect = mapping.propFrame(prop)
        return Button { react(to: prop) } label: {
            Color.clear.contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: rect.width, height: rect.height).position(x: rect.midX, y: rect.midY)
        .disabled(!active)
        .accessibilityHidden(!active)
        .accessibilityLabel(prop == .telescope ? "Observatory telescope" : "Observatory lantern")
        .accessibilityHint(prop == .telescope ? "Tilt the telescope and catch a glint of starlight" : "Make the lantern glow warmly")
        .accessibilityValue(response == prop ? "Responding" : "At rest")
        .accessibilityIdentifier(prop == .telescope ? "landing.telescope" : "landing.lantern")
    }
    private func react(to prop: ObservatoryProp) {
        responseTask?.cancel()
        generation += 1
        let ticket = generation
        response = prop
        responseTask = Task { @MainActor in
            do { try await Task.sleep(for: .seconds(1.8)) } catch { return }
            guard !Task.isCancelled, ticket == generation, active else { return }
            response = nil
            responseTask = nil
        }
    }
    private func cancelResponse() {
        generation += 1
        responseTask?.cancel(); responseTask = nil; response = nil
    }
}
