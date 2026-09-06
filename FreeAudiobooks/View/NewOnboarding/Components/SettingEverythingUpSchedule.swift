//
//  SettingEverythingUpSchedule.swift
//  FreeAudiobooks
//

import Foundation

/// The clock behind the plan-building screen: nine seconds from 0 to 100 that move
/// the way real work does rather than the way a linear animation does.
///
/// Four phases, each with a time budget and a cadence. A jittery warm-up to 20, a
/// steady build to 91 with a few short stalls, a crawl to 95, and a zip to 100.
/// The gaps inside a phase are random, then scaled so the phase lands on its budget
/// exactly, so every run feels alive and every run hits the same boundaries.
struct SettingEverythingUpSchedule {

    /// One change of the number on screen.
    struct Step: Equatable {
        /// Seconds after the previous step, or after the start for the first.
        let delay: TimeInterval
        let percent: Int
    }

    struct Phase {
        let endPercent: Int
        let budget: TimeInterval
        let gap: ClosedRange<TimeInterval>
        let increment: ClosedRange<Int>
        /// Percents that, when crossed, cost an extra `stallDuration` before scaling.
        let stalls: [Int]
    }

    static let phases: [Phase] = [
        Phase(endPercent: 20, budget: 1.5, gap: 0.08...0.14, increment: 1...2, stalls: []),
        Phase(endPercent: 91, budget: 5.1, gap: 0.10...0.20, increment: 1...4, stalls: [35, 55, 75]),
        Phase(endPercent: 95, budget: 1.6, gap: 0.40...0.40, increment: 1...1, stalls: []),
        Phase(endPercent: 100, budget: 0.3, gap: 0.06...0.06, increment: 1...1, stalls: [])
    ]

    static let stallDuration: TimeInterval = 0.28

    /// How long 100% stays on screen before the crossfade.
    static let finalHold: TimeInterval = 0.5

    /// Start to crossfade.
    static var totalDuration: TimeInterval {
        phases.reduce(finalHold) { $0 + $1.budget }
    }

    static let checklist = [
        "Finding audiobooks you’ll love",
        "Choosing your first listens",
        "Building your listening routine",
        "Saving your listening preferences"
    ]
    static let tickPercents = [20, 50, 80, 100]

    let steps: [Step]

    init(seed: UInt64 = UInt64.random(in: 0...UInt64.max)) {
        var generator = SeededGenerator(seed: seed)
        var steps: [Step] = []
        var percent = 0

        for phase in Self.phases {
            var local: [(gap: TimeInterval, percent: Int)] = []
            while percent < phase.endPercent {
                let before = percent
                percent = min(phase.endPercent, percent + Int.random(in: phase.increment, using: &generator))
                var gap = Double.random(in: phase.gap, using: &generator)
                for stall in phase.stalls where before < stall && percent >= stall {
                    gap += Self.stallDuration
                }
                local.append((gap, percent))
            }
            let raw = local.reduce(0) { $0 + $1.gap }
            let scale = raw > 0 ? phase.budget / raw : 1
            steps.append(contentsOf: local.map { Step(delay: $0.gap * scale, percent: $0.percent) })
        }
        self.steps = steps
    }

    /// Seconds from the start until the number first shows `percent` or more.
    func time(toReach percent: Int) -> TimeInterval? {
        var elapsed: TimeInterval = 0
        for step in steps {
            elapsed += step.delay
            if step.percent >= percent { return elapsed }
        }
        return nil
    }

    /// Start to crossfade, as this instance will actually play it.
    var duration: TimeInterval {
        steps.reduce(Self.finalHold) { $0 + $1.delay }
    }

    func percent(at elapsed: TimeInterval) -> Int {
        var deadline: TimeInterval = 0
        var percent = 0
        for step in steps {
            deadline += step.delay
            guard elapsed + 0.000001 >= deadline else { break }
            percent = step.percent
        }
        return percent
    }

    static func completedRowCount(at percent: Int) -> Int {
        tickPercents.filter { percent >= $0 }.count
    }

    static func statusLine(at percent: Int) -> String {
        switch percent {
        case 100...: return "Ready!"
        case 80...: return "Almost ready…"
        case 50...: return "Building your listening routine…"
        case 20...: return "Finding your next listens…"
        default: return "Reading your answers…"
        }
    }

    /// A small deterministic generator so a seeded schedule is the same on every
    /// platform and in every test run.
    private struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed &+ 0x9E37_79B9_7F4A_7C15
        }

        mutating func next() -> UInt64 {
            // SplitMix64.
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }
}

/// Tracks active viewing time only. The clock is supplied by the caller so lifecycle
/// behaviour can be verified without real-time waits or an attached view controller.
struct SettingEverythingUpPlayback {
    let schedule: SettingEverythingUpSchedule
    private var accumulatedTime: TimeInterval = 0
    private var resumedAt: TimeInterval?
    private(set) var elapsed: TimeInterval = 0
    private(set) var isCancelled = false
    private(set) var didComplete = false

    init(schedule: SettingEverythingUpSchedule) {
        self.schedule = schedule
    }

    var percent: Int { schedule.percent(at: elapsed) }

    mutating func resume(at now: TimeInterval) {
        guard !isCancelled, !didComplete, resumedAt == nil else { return }
        resumedAt = now
    }

    mutating func pause(at now: TimeInterval) {
        updateElapsed(at: now)
        accumulatedTime = elapsed
        resumedAt = nil
    }

    /// Returns true exactly once, after the final hold finishes while running.
    mutating func tick(at now: TimeInterval) -> Bool {
        guard !isCancelled, !didComplete, resumedAt != nil else { return false }
        updateElapsed(at: now)
        guard elapsed >= schedule.duration else { return false }
        didComplete = true
        resumedAt = nil
        return true
    }

    mutating func cancel() {
        isCancelled = true
        resumedAt = nil
    }

    private mutating func updateElapsed(at now: TimeInterval) {
        guard !isCancelled, let resumedAt else { return }
        elapsed = min(schedule.duration, accumulatedTime + max(0, now - resumedAt))
    }
}
