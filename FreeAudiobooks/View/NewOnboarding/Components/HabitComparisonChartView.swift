import UIKit
import SwiftUI
import Charts

// MARK: - Data Model

struct ReadingDataPoint: Identifiable {
    let id = UUID()
    let day: Int
    let value: Double
    let series: String
}

private struct SolidRevealMask: View {
    let progress: CGFloat // 0...1

    var body: some View {
        Rectangle()
            .scaleEffect(x: max(0.0001, min(1, progress)), y: 1, anchor: .leading)
    }
}

// MARK: - Feathered reveal mask

private struct FeatheredRevealMask: View {
    let progress: CGFloat          // 0...1
    let feather: CGFloat           // points

    var body: some View {
        // When fully revealed, remove feather entirely (no right-edge fade).
        if progress >= 0.999 {
            Rectangle()
        } else {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                let p = max(0, min(1, progress))
                let revealW = w * p

                ZStack(alignment: .leading) {
                    // For very small reveal widths, don't use a gradient at all (prevents "fade-in").
                    if revealW <= feather {
                        Rectangle()
                            .frame(width: revealW, height: h)
                            .foregroundStyle(.white)
                    } else {
                        // Solid revealed region
                        Rectangle()
                            .frame(width: revealW - feather, height: h)
                            .foregroundStyle(.white)

                        // Feather only at the moving edge
                        LinearGradient(
                            colors: [.white, .white.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: feather, height: h)
                        .offset(x: revealW - feather)
                    }
                }
            }
        }
    }
}

// MARK: - SwiftUI Chart View

struct HabitComparisonChartContent: View {

    // MARK: - Configuration
    let chartTitle: String
    let freebooksLabel: String
    let tryingAloneLabel: String
    let startAxisLabel: String
    let endAxisLabel: String

    // MARK: - Layout
    private let sideInset: CGFloat = 16
    private let chartHeight: CGFloat = 140

    // MARK: - Animation State (staggered)
    @State private var tryingReveal: CGFloat = 0.0
    @State private var freebooksReveal: CGFloat = 0.0

    @State private var showTryingEndLabel = false
    @State private var showFreebooksEndLabel = false

    // MARK: - Colors
    private let freebooksColor = Color(Colours.orangePrimary)
    private let tryingAloneColor = Color(Colours.textPrimary).opacity(0.45)
    private let containerBackgroundColor = Color(Colours.surfaceSecondary)
    private let guideLineColor = Color(Colours.separator)

    // MARK: - X/Y scales
    private let xDomain: ClosedRange<Double> = 1...30
    private let yDomain: ClosedRange<Double> = 0...1.1

    // MARK: - Guide lines (middle start)
    private let middleGuideY: Double = 0.55
    private let guideStep: Double = 0.20
    private var lowerGuideY: Double { middleGuideY - guideStep }
    private var upperGuideY: Double { middleGuideY + guideStep }
    private var topGuideY: Double   { middleGuideY + 2 * guideStep }

    // MARK: - Data (more control points => smoother arc)
    private let sampleDays = [1, 4, 7, 10, 14, 18, 22, 26, 30]

    private var freebooks: [ReadingDataPoint] {
        // Starts at middle guide and climbs to top guide
        let values: [Double] = [middleGuideY, 0.58, 0.63, 0.70, 0.79, 0.87, 0.92, 0.95, 0.96]
        return zip(sampleDays, values).map { day, value in
            .init(day: day, value: value, series: "FreeAudiobooks")
        }
    }

    private var tryingAlone: [ReadingDataPoint] {
        // Starts at middle, early momentum, then smooth swoop to one line below
        let values: [Double] = [middleGuideY, 0.72, 0.68, 0.60, 0.52, 0.45, 0.40, 0.37, lowerGuideY]
        return zip(sampleDays, values).map { day, value in
            .init(day: day, value: value, series: "TryingAlone")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text(chartTitle)
                .font(Font(Fonts.medium16))
                .foregroundColor(Color(Colours.textPrimary))
                .padding(.horizontal, sideInset)
                .padding(.top, 16)

            ZStack {
                guidesAndShadingChart

                tryingAloneChart
                    .mask { SolidRevealMask(progress: tryingReveal) }

                freebooksChart
                    .mask { SolidRevealMask(progress: freebooksReveal) }

                // End labels (right-aligned at Day 30), fade in after each line finishes
                endLabelsOverlayPositioner

                // Endpoint circles (drawn via overlay so they don't clip at edges)
                freebooksEndpointsOverlay
            }
            .frame(height: chartHeight)
            .padding(.horizontal, sideInset)

            HStack {
                Text(startAxisLabel)
                    .font(Font(Fonts.medium14))
                    .foregroundColor(Color(Colours.textSecondary))

                Spacer()

                Text(endAxisLabel)
                    .font(Font(Fonts.medium14))
                    .foregroundColor(Color(Colours.textSecondary))
            }
            .padding(.horizontal, sideInset)
            .padding(.bottom, 16)
        }
        .background(containerBackgroundColor)
        .cornerRadius(16)
        .onAppear {
            tryingReveal = 0
            freebooksReveal = 0
            showTryingEndLabel = false
            showFreebooksEndLabel = false

            let tryingDuration: Double = 0.9
            let freebooksDelay: Double = 0.35
            let freebooksDuration: Double = 0.9

            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: tryingDuration)) {
                    tryingReveal = 1
                }

                // No withAnimation here: avoid whole chart re-render "flash".
                DispatchQueue.main.asyncAfter(deadline: .now() + tryingDuration) {
                    showTryingEndLabel = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + freebooksDelay) {
                    withAnimation(.easeInOut(duration: freebooksDuration)) {
                        freebooksReveal = 1
                    }
                }

                // No withAnimation here: labels animate themselves only.
                DispatchQueue.main.asyncAfter(deadline: .now() + freebooksDelay + freebooksDuration) {
                    showFreebooksEndLabel = true
                }
            }
        }
    }

    // MARK: - End label view (matches the line style, not a hyphen)

    private func endLabel(color: Color, lineWidth: CGFloat, text: String) -> some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(color)
                .frame(width: 24, height: lineWidth)

            Text(text)
                .font(Font(Fonts.medium14))
                .foregroundColor(color)
        }
    }

    // MARK: - End labels overlay (positions using plot coordinates)

    private var endLabelsOverlayPositioner: some View {
        Chart { }
            .applyChartStyling(xDomain: xDomain, yDomain: yDomain)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    let plotRect = geo[proxy.plotAreaFrame]

                    // Endpoint x at Day 30
                    let xEnd = proxy.position(forX: 30.0) ?? plotRect.maxX

                    // Endpoint y values
                    let freeYVal = freebooks.last?.value ?? middleGuideY
                    let tryYVal  = tryingAlone.last?.value ?? middleGuideY

                    let yFree = proxy.position(forY: freeYVal) ?? plotRect.midY
                    let yTry  = proxy.position(forY: tryYVal) ?? plotRect.midY

                    // Layout tuning
                    let gapFree: CGFloat = 26          // FreeAudiobooks: always above
                    let gapTry: CGFloat = 22           // Trying alone: always below
                    let labelHeight: CGFloat = 18      // approx single-line label height
                    let halfH = labelHeight / 2
                    let topPadding: CGFloat = -10
                    let bottomPadding: CGFloat = 6

                    // Label placed to the LEFT of the endpoint dot, but still right-aligned
                    let rightInsetFromDot: CGFloat = 8   // keep as you requested
                    let maxLabelWidth: CGFloat = 190
                    let availableToLeft = max(0, (xEnd - rightInsetFromDot) - plotRect.minX)
                    let labelW = min(maxLabelWidth, availableToLeft)

                    // Horizontal position: right edge sits at xEnd - rightInsetFromDot
                    let xRightEdge = xEnd - rightInsetFromDot
                    let xCenter = max(plotRect.minX + labelW / 2, xRightEdge - labelW / 2)

                    // Clamp only (no flipping):
                    // - FreeAudiobooks stays ABOVE (clamps to top if needed)
                    // - Trying alone stays BELOW (clamps to bottom if needed)
                    let clampToPlot: (CGFloat) -> CGFloat = { y in
                        min(
                            max(y, plotRect.minY + topPadding + halfH),
                            plotRect.maxY - bottomPadding - halfH
                        )
                    }

                    let freeY = clampToPlot(yFree - gapFree)
                    let tryY  = clampToPlot(yTry + gapTry)

                    ZStack {
                        endLabel(color: freebooksColor, lineWidth: 3, text: freebooksLabel)
                            .frame(width: labelW, alignment: .trailing)
                            .position(x: xCenter, y: freeY)
                            .opacity(showFreebooksEndLabel ? 1 : 0)
                            .animation(.easeOut(duration: 0.25), value: showFreebooksEndLabel)

                        endLabel(color: tryingAloneColor, lineWidth: 2.5, text: tryingAloneLabel)
                            .frame(width: labelW, alignment: .trailing)
                            .position(x: xCenter, y: tryY)
                            .opacity(showTryingEndLabel ? 1 : 0)
                            .animation(.easeOut(duration: 0.25), value: showTryingEndLabel)
                    }
                }
            }
            .allowsHitTesting(false)
    }

    // MARK: - Endpoint circles overlay (prevents clipping)

    private var freebooksEndpointsOverlay: some View {
        Chart { }
            .applyChartStyling(xDomain: xDomain, yDomain: yDomain)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    let plotRect = geo[proxy.plotAreaFrame]

                    Group {
                        if
                            let start = freebooks.first,
                            let end = freebooks.last,
                            let x1 = proxy.position(forX: Double(start.day)),
                            let y1 = proxy.position(forY: start.value),
                            let x2 = proxy.position(forX: Double(end.day)),
                            let y2 = proxy.position(forY: end.value)
                        {
                            let outerD: CGFloat = 14
                            let innerD: CGFloat = 8

                            ZStack {
                                // Start (always visible)
                                ZStack {
                                    Circle().fill(Color(Colours.surfacePrimary)).frame(width: outerD, height: outerD)
                                    Circle().fill(freebooksColor).frame(width: innerD, height: innerD)
                                }
                                .position(x: x1, y: y1)

                                // End (show when FreeAudiobooks line completes)
                                ZStack {
                                    Circle().fill(Color(Colours.surfacePrimary)).frame(width: outerD, height: outerD)
                                    Circle().fill(freebooksColor).frame(width: innerD, height: innerD)
                                }
                                .position(x: x2, y: y2)
                                .opacity(showFreebooksEndLabel ? 1 : 0)
                            }
                            .frame(width: plotRect.width, height: plotRect.height)
                            .offset(x: plotRect.minX, y: plotRect.minY)
                        } else {
                            EmptyView()
                        }
                    }
                }
            }
            .allowsHitTesting(false)
    }

    // MARK: - Static guides + subtle banding (not animated)

    private var guidesAndShadingChart: some View {
        Chart {
            RectangleMark(
                xStart: .value("Day Start", 1),
                xEnd: .value("Day End", 30),
                yStart: .value("Band Low", yDomain.lowerBound),
                yEnd: .value("Band Mid", middleGuideY)
            )
            .foregroundStyle(Color(Colours.textPrimary).opacity(0.03))

            ForEach([lowerGuideY, middleGuideY, upperGuideY, topGuideY], id: \.self) { y in
                RuleMark(y: .value("Guide", y))
                    .foregroundStyle(guideLineColor)
                    .lineStyle(StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3, 4]))
            }
        }
        .applyChartStyling(xDomain: xDomain, yDomain: yDomain)
        .allowsHitTesting(false)
    }

    // MARK: - Series charts

    private var tryingAloneChart: some View {
        Chart {
            ForEach(tryingAlone) { point in
                AreaMark(
                    x: .value("Day", point.day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            tryingAloneColor.opacity(0.22),
                            tryingAloneColor.opacity(0.06),
                            tryingAloneColor.opacity(0.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Day", point.day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(tryingAloneColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
            }
        }
        .applyChartStyling(xDomain: xDomain, yDomain: yDomain)
    }

    private var freebooksChart: some View {
        Chart {
            ForEach(freebooks) { point in
                AreaMark(
                    x: .value("Day", point.day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            freebooksColor.opacity(0.10),
                            freebooksColor.opacity(0.03),
                            freebooksColor.opacity(0.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Day", point.day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(freebooksColor)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
            }
        }
        .applyChartStyling(xDomain: xDomain, yDomain: yDomain)
    }
}

// MARK: - Shared chart styling

private extension View {
    @ViewBuilder
    func applyChartStyling(xDomain: ClosedRange<Double>, yDomain: ClosedRange<Double>) -> some View {
        if #available(iOS 17.0, *) {
            self
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: yDomain)
                .chartXScale(domain: xDomain, range: .plotDimension(padding: 0)) // flush ends
                .chartPlotStyle { plotArea in plotArea.padding(.zero) }
                .chartLegend(.hidden)
        } else {
            self
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: yDomain)
                .chartXScale(domain: xDomain) // iOS 16 keeps some internal padding (framework limitation)
                .chartPlotStyle { plotArea in plotArea.padding(.zero) }
                .chartLegend(.hidden)
        }
    }
}

// MARK: - UIKit Wrapper

final class HabitComparisonChartView: UIView {

    var chartTitle: String = "Your listening" { didSet { updateHostingController() } }
    var freebooksLabel: String = "FreeAudiobooks" { didSet { updateHostingController() } }
    var tryingAloneLabel: String = "Trying alone" { didSet { updateHostingController() } }

    var startAxisLabel: String = "Day 1" { didSet { updateHostingController() } }
    var endAxisLabel: String = "Day 30" { didSet { updateHostingController() } }

    private var hostingController: UIHostingController<HabitComparisonChartContent>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHostingController()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHostingController()
    }

    private func setupHostingController() {
        let hosting = UIHostingController(rootView: makeRootView())
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false

        addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        hostingController = hosting
    }

    private func updateHostingController() {
        hostingController?.rootView = makeRootView()
    }

    private func makeRootView() -> HabitComparisonChartContent {
        HabitComparisonChartContent(
            chartTitle: chartTitle,
            freebooksLabel: freebooksLabel,
            tryingAloneLabel: tryingAloneLabel,
            startAxisLabel: startAxisLabel,
            endAxisLabel: endAxisLabel
        )
    }
}
