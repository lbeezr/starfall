import SwiftUI

/// Allocate the short, wide proposal without compressing native cells or type.
enum SkyReadingLayout {
    static let returnBandHeight: CGFloat = 80

    static func sidebarWidth(viewport: CGSize) -> CGFloat? {
        let minimumCanvasWidth = 7 * StarfallTheme.Layout.minimumTarget + 12
        let available = viewport.width - minimumCanvasWidth - StarfallTheme.Spacing.small
        guard viewport.width > viewport.height, viewport.height < 700, available >= 180 else { return nil }
        return min(StarfallTheme.Layout.wideGameSidebarWidth, available, viewport.width * 0.42)
    }

    static func canvasWidth(availableWidth: CGFloat, viewportHeight: CGFloat, ceilingClearance: CGFloat) -> CGFloat {
        // The complete ceiling and two rows remain readable together. Fit the
        // actual shared canvas; never independently resize its sprites or hits.
        let readingHeight = viewportHeight - returnBandHeight - 2 * StarfallTheme.Spacing.small
        let cell = max(StarfallTheme.Layout.minimumTarget, (readingHeight - ceilingClearance) / 2)
        return min(availableWidth, 7 * cell + 12)
    }
}

/// Native reading composition over one continuous painting. The caller owns
/// game state, canvas mapping and source-bound actions; this view only places
/// the supplied official slots and preserves their explicit visibility.
@MainActor struct SkyReadingPlayfield<Scenery: View, Header: View, Board: View, Guide: View>: View {
    let canvasSize: CGSize
    let visibleHeight: CGFloat
    let crop: CGFloat
    let isCovered: Bool
    var sidebarWidth: CGFloat? = nil
    var pinsAward = false
    let scenery: Scenery
    let header: Header
    let board: Board
    let guide: (CGFloat) -> Guide

    var body: some View {
        ZStack {
            scenery.ignoresSafeArea()
            if let sidebarWidth {
                HStack(alignment: .top, spacing: StarfallTheme.Spacing.small) {
                    if !isCovered {
                        header.padding(.horizontal, StarfallTheme.Spacing.small)
                            .frame(width: sidebarWidth)
                            .padding(.top, StarfallTheme.Spacing.compact)
                    } else {
                        Color.clear.frame(width: sidebarWidth)
                    }
                    VStack(spacing: 0) {
                        if !isCovered { returnBand }
                        readingViewport
                    }
                }
            } else {
                VStack(spacing: 0) {
                    if !isCovered {
                        header
                            .padding(.horizontal, StarfallTheme.Spacing.medium)
                            .padding(.top, StarfallTheme.Spacing.compact)
                        returnBand
                    }
                    readingViewport
                }
            }
        }
    }

    private var returnBand: some View {
        // Exact figure returns need fixed sky while the cells scroll.
        Color.clear.frame(height: SkyReadingLayout.returnBandHeight)
            .transformAnchorPreference(key: StarlightAnchors.self, value: .bounds) { anchors, anchor in
                anchors[.constellationReturn] = anchor
                if pinsAward { anchors[.award] = anchor }
            }
            .padding(.vertical, StarfallTheme.Spacing.small)
            .allowsHitTesting(false).accessibilityHidden(true)
    }

    private var readingViewport: some View {
        GeometryReader { readingViewport in
            ScrollViewReader { reader in
                ScrollView {
                    VStack(spacing: StarfallTheme.Spacing.small) {
                        board
                            .frame(width: sidebarWidth == nil ? nil : canvasSize.width)
                            .frame(height: canvasSize.height)
                            .offset(y: -crop)
                            .frame(height: visibleHeight - crop, alignment: .top).clipped()
                            .allowsHitTesting(!isCovered)
                            .accessibilityHidden(isCovered)
                            .frame(maxWidth: .infinity)
                            .id("sky.readingBoard")
                        if !isCovered {
                            guide(max(240, readingViewport.size.height - 2 * StarfallTheme.Spacing.medium))
                                .padding(.horizontal, StarfallTheme.Spacing.medium)
                                .padding(.bottom, StarfallTheme.Spacing.medium)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .task {
                    // Start on the current stars, rather than empty rows
                    // above the survivor opening, as in the existing owner.
                    await Task.yield()
                    guard !Task.isCancelled else { return }
                    reader.scrollTo("sky.readingBoard", anchor: .bottom)
                }
            }
        }
    }
}
