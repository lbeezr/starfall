import SwiftUI

/// Five bounded depth planes. Decorative views have no store capability or touch targets.
@MainActor struct LandingEnvironment: View {
    let place: LandingPlace
    let active: Bool
    let reducedMotion: Bool
    var largeHeader = false
    @State private var clock = LandingAmbientClock()
    private var running: Bool { active && !reducedMotion }

    var body: some View {
        GeometryReader { geometry in
            let layout = NightSceneLayout(size: geometry.size, largeHeader: largeHeader)
            ZStack {
                // Plane 0: still space, shared by the traveling cast.
                LandingBackdrop(place: place)
                NightDistantStars()
                TimelineView(.animation(minimumInterval: 1.0/24, paused: !running)) { _ in
                    let phase = reducedMotion ? 0 : clock.phase(at: ProcessInfo.processInfo.systemUptime)
                    ZStack {
                        // Plane 1: faint atmosphere. Its movement never shifts the board.
                        art("NightVeil", in: layout.veilLeft, opacity: 0.32)
                            .offset(y: sin(phase/13)*1.5)
                        art("NightVeil", in: layout.veilRight, opacity: 0.25, rotation: 180).offset(y: -sin(phase/17)*1.5)
                        // Plane 2: the world's identifying distant silhouette.
                        landmark(in: layout, phase: phase).offset(y: sin(phase/19)*1.2)
                        // Plane 3: one small local story detail, independently controlled.
                        detail(in: layout, phase: phase)
                        // Plane 4: near silhouettes; modest movement, no screen shake.
                        foreground(in: layout).offset(y: sin(phase/11)*2)
                    }
                }
            }.clipped().allowsHitTesting(false).accessibilityHidden(true)
        }
        .onAppear { clock.setRunning(running, at: ProcessInfo.processInfo.systemUptime) }
        .onChange(of: running) { _, value in clock.setRunning(value, at: ProcessInfo.processInfo.systemUptime) }
        .onDisappear { clock.setRunning(false, at: ProcessInfo.processInfo.systemUptime) }
    }

    @ViewBuilder private func landmark(in layout: NightSceneLayout, phase: TimeInterval) -> some View {
        if place == .ringdrift {
            let rect = layout.landmark
            ZStack {
                Image("RingdriftRings").resizable().scaledToFit()
                    .mask(alignment: .top) { Rectangle().frame(height: rect.height/2) }
                Image("RingdriftPlanet").resizable().scaledToFit()
                    .frame(width: rect.width*0.52, height: rect.height*0.70)
                Image("RingdriftRings").resizable().scaledToFit()
                    .mask(alignment: .bottom) { Rectangle().frame(height: rect.height/2) }
            }.frame(width: rect.width, height: rect.height).position(x: rect.midX,y: rect.midY)
        } else if place == .shatterlight {
            let rect = layout.landmark
            art("ShatterlightCrown", in: CGRect(x:rect.minX,y:rect.minY,width:rect.width,height:rect.height*0.46))
                .offset(x:sin(phase/16)*1.2)
            art("ShatterlightCrescent", in: CGRect(x:rect.minX,y:rect.minY+rect.height*0.40,width:rect.width*0.72,height:rect.height*0.34))
                .offset(y:-sin(phase/20)*1.5)
            art("ShatterlightShard", in: CGRect(x:rect.minX+rect.width*0.08,y:rect.minY+rect.height*0.75,width:rect.width*0.63,height:rect.height*0.24))
                .offset(x:-sin(phase/18)*1.2)
        } else {
            art(place.landmarkAsset, in: layout.landmark)
        }
    }

    @ViewBuilder private func detail(in layout: NightSceneLayout, phase: TimeInterval) -> some View {
        switch place {
        case .moonwake, .ringdrift:
            NightSail(phase: phase)
                .frame(width: layout.detail.width, height: layout.detail.height)
                .position(x: layout.detail.midX,y: layout.detail.midY)
                .offset(y: sin(phase/8)*1.5)
        case .nebula:
            art("NebulaBankRight", in: layout.secondary, opacity: 0.84)
            light(in: layout.secondary, x: 0.66, y: 0.60, phase: phase/5)
        case .shatterlight:
            art("ShatterlightShelter", in: layout.detail)
                .offset(y: sin(phase/12)*1.2)
            light(in: layout.detail, x: 0.62, y: 0.36, phase: phase/4)
        case .garden:
            art("GardenPod", in: layout.secondary, opacity: 0.92)
            light(in: layout.secondary, x: 0.51, y: 0.53, phase: phase/6)
            let moth = CGRect(x: layout.detail.minX-40,y: layout.detail.minY+12,width: 36,height: 36)
            art("GardenMoth", in: moth, opacity: 0.65, rotation: sin(phase/4)*2)
                .offset(y: sin(phase/7)*1.5)
        }
    }

    @ViewBuilder private func foreground(in layout: NightSceneLayout) -> some View {
        switch place {
        case .moonwake: art("NightIce", in: layout.nearLeft, opacity: 0.7)
        case .nebula: art("NightVeil", in: layout.nearLeft, opacity: 0.24)
        case .shatterlight: art("ShatterlightShard", in: layout.nearRight, opacity: 0.35)
        case .garden: art("GardenCanopy", in: layout.nearLeft, opacity: 0.42)
        case .ringdrift:
            art("NightIce", in: layout.nearLeft, opacity: 0.68)
            art("RingdriftPlanet", in: layout.nearMoon, opacity: 0.68)
        }
    }

    private func light(in rect: CGRect, x: CGFloat, y: CGFloat, phase: TimeInterval) -> some View {
        Circle().fill(StarfallTheme.Observatory.lanternGlow)
            .frame(width: min(10,rect.width*0.06),height: min(10,rect.width*0.06))
            .blur(radius: 3).opacity(0.08 + (sin(phase)+1)*0.05)
            .position(x:rect.minX+rect.width*x,y:rect.minY+rect.height*y)
    }

    private func art(_ asset: String, in rect: CGRect, opacity: Double = 1, rotation: Double = 0) -> some View {
        Image(asset).resizable().scaledToFit().opacity(opacity)
            .frame(width: rect.width, height: rect.height)
            .rotationEffect(.degrees(rotation))
            .position(x: rect.midX,y: rect.midY)
    }
}

/// Place components in the available margins, independently of their source canvas.
/// Portrait gets a deliberate top/bottom composition; wide windows get lateral depth.
struct NightSceneLayout {
    let size: CGSize
    var largeHeader = false
    private var mapping: LandingGeometry { LandingGeometry(size: size, largeHeader: largeHeader) }
    var usesWings: Bool { mapping.arenaFrame.minX >= 140 }
    private var gutter: CGFloat { mapping.arenaFrame.minX-12 }
    private var top: CGFloat { max(24,mapping.crownFrame.minY-12) }
    private var bottom: CGFloat { mapping.actionFrame(0).maxY+12 }
    var landmark: CGRect {
        if usesWings { return CGRect(x: -gutter*0.18,y: 0,width: gutter*1.08,height: size.height*0.58) }
        return CGRect(x: -top*0.28,y: -top*0.24,width: top*1.45,height: top*1.20)
    }
    var detail: CGRect {
        if usesWings { return CGRect(x: size.width-gutter*0.78,y: size.height*0.14,width: gutter*0.66,height: gutter*0.66) }
        let side = min(100,top*0.72)
        return CGRect(x: size.width-side-10,y: max(8,top-side-10),width: side,height: side)
    }
    var nearLeft: CGRect {
        if usesWings { return CGRect(x: -gutter*0.25,y: size.height*0.67,width: gutter,height: size.height*0.38) }
        return CGRect(x: -size.width*0.1,y: bottom,width: size.width*0.38,height: size.width*0.38)
    }
    var nearRight: CGRect {
        if usesWings { return CGRect(x: size.width-gutter*0.88,y: size.height*0.56,width: gutter*1.1,height: size.height*0.48) }
        return CGRect(x: size.width*0.63,y: bottom,width: size.width*0.43,height: size.width*0.43)
    }
    var secondary: CGRect { usesWings ? nearRight : detail }
    var nearMoon: CGRect {
        if !usesWings { return CGRect(x:detail.minX-42,y:detail.minY,width:36,height:36) }
        let rect = nearRight, side = min(100,rect.width*0.45)
        return CGRect(x: rect.midX-side/2,y: rect.minY,width: side,height: side)
    }
    var veilLeft: CGRect { CGRect(x: -size.width*0.28,y: -size.height*0.12,width: size.width*0.6,height: size.height*1.2) }
    var veilRight: CGRect { CGRect(x: size.width*0.7,y: 0,width: size.width*0.6,height: size.height*1.2) }
}

struct LandingBackdrop: View {
    let place: LandingPlace
    var body: some View {
        LinearGradient(colors: [StarfallTheme.Colors.skyTop, StarfallTheme.Landing.nightCenter, StarfallTheme.Colors.skyTop],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct NightDistantStars: View {
    var body: some View {
        Canvas { context, size in
            // A small static field, with no RNG, textures, particles or per-frame work.
            for index in 0..<48 {
                let x = CGFloat((index*137+29)%997)/997*size.width
                let y = CGFloat((index*281+71)%991)/991*size.height
                let radius: CGFloat = index%9 == 0 ? 0.9 : 0.5
                context.fill(Path(ellipseIn: CGRect(x:x,y:y,width:radius*2,height:radius*2)),
                             with: .color(StarfallTheme.Landing.distantStar.opacity(index%9 == 0 ? 0.32 : 0.16)))
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Both authored parts retain a common 3:2 canvas; the cloth pivots at the mast foot.
private struct NightSail: View {
    let phase: TimeInterval
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width, height = width/1.5
            ZStack {
                Image("MoonwakeHull").resizable().scaledToFit()
                Image("MoonwakeCloth").resizable().scaledToFit()
                    .scaleEffect(x:0.92,y:0.89,anchor:UnitPoint(x:0.423,y:0.129))
                    .offset(x:width*0.0065,y:height*0.0215)
                    .rotationEffect(.degrees(sin(phase/9)*1.2),anchor:UnitPoint(x:0.429,y:0.69))
                Circle().fill(StarfallTheme.Observatory.lanternGlow)
                    .frame(width:width*0.025,height:width*0.025).blur(radius:1)
                    .opacity(0.15+(sin(phase/4)+1)*0.08)
                    .position(x:width*0.401,y:height*0.664)
            }.frame(width:width,height:height)
                .position(x:proxy.size.width/2,y:proxy.size.height/2)
        }
    }
}
