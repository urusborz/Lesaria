import SwiftUI

// MARK: - Activity Rings (concentric, Apple-Fitness style)

struct ActivityRings: View {
    /// Rings from outer to inner: (progress 0...1, color).
    var rings: [(progress: Double, color: Color)]
    var size: CGFloat = 116
    var lineWidth: CGFloat = 11
    var spacing: CGFloat = 4
    var centerLabel: String? = nil
    var centerSub: String? = nil

    var body: some View {
        ZStack {
            ForEach(rings.indices, id: \.self) { i in
                let dim = size - CGFloat(i) * 2 * (lineWidth + spacing)
                ZStack {
                    Circle().stroke(AppTheme.ringTrack, lineWidth: lineWidth)
                    Circle()
                        .trim(from: 0, to: max(0.0001, min(1, rings[i].progress)))
                        .stroke(rings[i].color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.55, dampingFraction: 0.85), value: rings[i].progress)
                }
                .frame(width: dim, height: dim)
            }
            if let centerLabel {
                VStack(spacing: 0) {
                    Text(centerLabel)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    if let centerSub {
                        Text(centerSub).font(.system(size: 10)).foregroundColor(AppTheme.textTertiary)
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Liquid Fill Circle (a "glass" that fills, with an animated wave)

struct Wave: Shape {
    var progress: Double
    var phase: CGFloat
    var amplitude: CGFloat = 3.5

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let baseY = h * (1 - CGFloat(min(1, max(0, progress))))
        let steps = 38
        p.move(to: CGPoint(x: 0, y: baseY))
        for i in 0...steps {
            let x = w * CGFloat(i) / CGFloat(steps)
            let y = baseY + amplitude * sin(2 * .pi * CGFloat(i) / CGFloat(steps) + phase)
            p.addLine(to: CGPoint(x: x, y: y))
        }
        p.addLine(to: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: 0, y: h))
        p.closeSubpath()
        return p
    }
}

struct LiquidFillCircle: View {
    let progress: Double
    var size: CGFloat = 60
    var color: Color = AppTheme.accent
    var centerLabel: String? = nil

    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            Circle().fill(AppTheme.controlBackground)
            Wave(progress: progress, phase: phase + .pi, amplitude: 3)
                .fill(color.opacity(0.4))
            Wave(progress: progress, phase: phase)
                .fill(color.opacity(0.85))
            if let centerLabel {
                Text(centerLabel)
                    .font(.system(size: size * 0.26, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(AppTheme.glassBorder, lineWidth: 1))
        .onAppear {
            withAnimation(.linear(duration: 2.6).repeatForever(autoreverses: false)) {
                phase = 2 * .pi
            }
        }
    }
}

// MARK: - Prayer Sun Arc (the day as an arc, sun/moon at current position)

struct PrayerSunArc: View {
    let slots: [PrayerSlot]
    let now: Date

    private var trackable: [PrayerSlot] { slots.filter { $0.isTrackable } }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                if let fajr = trackable.first?.time,
                   let isha = trackable.last?.time,
                   isha > fajr {
                    let span = isha.timeIntervalSince(fajr)

                    arcPath(in: size)
                        .stroke(AppTheme.ringTrack, style: StrokeStyle(lineWidth: 2, lineCap: .round))

                    ForEach(trackable) { s in
                        let f = clamp(s.time.timeIntervalSince(fajr) / span)
                        let pt = point(f, size)
                        Group {
                            dot(for: s).position(pt)
                            Text(s.name)
                                .font(.system(size: 11, weight: s.isNext ? .semibold : .regular))
                                .foregroundColor(s.isNext ? AppTheme.accentAmber : AppTheme.textTertiary)
                                .position(x: pt.x, y: pt.y + 17)
                        }
                    }

                    let mf = clamp(now.timeIntervalSince(fajr) / span)
                    marker(isDay: now >= fajr && now <= isha).position(point(mf, size))
                }
            }
        }
        .frame(height: 118)
    }

    private func clamp(_ x: Double) -> Double { min(1, max(0, x)) }

    private func point(_ f: Double, _ size: CGSize) -> CGPoint {
        let cx = size.width / 2
        let rx = size.width / 2 - 22
        let baseY = size.height - 24
        let ry = size.height - 42
        let theta = Double.pi * (1 - clamp(f))
        let c: Double = cos(theta)
        let s: Double = sin(theta)
        return CGPoint(x: cx + rx * CGFloat(c), y: baseY - ry * CGFloat(s))
    }

    private func arcPath(in size: CGSize) -> Path {
        var p = Path()
        var f = 0.0
        var first = true
        while f <= 1.0001 {
            let pt = point(f, size)
            if first { p.move(to: pt); first = false } else { p.addLine(to: pt) }
            f += 0.04
        }
        return p
    }

    @ViewBuilder
    private func dot(for s: PrayerSlot) -> some View {
        if s.isDone {
            Circle().fill(AppTheme.accentAmber).frame(width: 11, height: 11)
        } else if s.isNext {
            Circle().stroke(AppTheme.accentAmber, lineWidth: 2.5).frame(width: 13, height: 13)
        } else {
            Circle().fill(AppTheme.ringTrack).frame(width: 10, height: 10)
        }
    }

    @ViewBuilder
    private func marker(isDay: Bool) -> some View {
        if isDay {
            ZStack {
                Circle().stroke(AppTheme.accentAmber.opacity(0.35), lineWidth: 3).frame(width: 22, height: 22)
                Circle().fill(AppTheme.accentAmber).frame(width: 15, height: 15)
            }
        } else {
            ZStack {
                Circle().fill(AppTheme.textSecondary).frame(width: 15, height: 15)
                Circle().fill(AppTheme.glassBackground).frame(width: 12, height: 12).offset(x: 3.5, y: -2)
            }
        }
    }
}

// MARK: - Today Timeline (vertical day strip with a "now" marker)

struct TimelineEntry: Identifiable {
    let id = UUID()
    let time: Date
    let title: String
    let kind: Kind
    var done: Bool = false

    enum Kind { case prayer, event, task, now }

    var icon: String {
        switch kind {
        case .prayer: return "moon.stars.fill"
        case .event:  return "calendar"
        case .task:   return "checkmark.circle"
        case .now:    return "circle.fill"
        }
    }
}

struct TodayTimeline: View {
    let entries: [TimelineEntry]
    let now: Date

    private var merged: [TimelineEntry] {
        var arr = entries
        arr.append(TimelineEntry(time: now, title: "Jetzt", kind: .now))
        return arr.sorted { $0.time < $1.time }
    }

    var body: some View {
        let items = merged
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { idx in
                row(items[idx], isFirst: idx == 0, isLast: idx == items.count - 1)
            }
        }
    }

    private func row(_ e: TimelineEntry, isFirst: Bool, isLast: Bool) -> some View {
        let isNow = e.kind == .now
        let isPast = e.time < now && !isNow
        return HStack(spacing: 10) {
            Text(isNow ? "Jetzt" : e.time.deTime)
                .font(.system(size: 12, weight: isNow ? .semibold : .medium, design: .monospaced))
                .foregroundColor(isNow ? AppTheme.accent : (isPast ? AppTheme.textTertiary : AppTheme.textSecondary))
                .frame(width: 44, alignment: .trailing)

            ZStack {
                Rectangle().fill(AppTheme.separator).frame(width: 2)
                    .padding(.top, isFirst ? 18 : 0)
                    .padding(.bottom, isLast ? 18 : 0)
                Circle()
                    .fill(isNow ? AppTheme.accent : (e.done ? AppTheme.accentGreen : dotColor(e)))
                    .frame(width: isNow ? 11 : 9, height: isNow ? 11 : 9)
                    .overlay(Circle().stroke(AppTheme.glassBackground, lineWidth: 2.5))
            }
            .frame(width: 18)

            HStack(spacing: 7) {
                if !isNow {
                    Image(systemName: e.icon).font(.system(size: 11)).foregroundColor(iconColor(e, isPast))
                }
                Text(e.title)
                    .font(.system(size: 14, weight: isNow ? .semibold : .medium))
                    .foregroundColor(isNow ? AppTheme.accent : (isPast ? AppTheme.textTertiary : AppTheme.textPrimary))
                    .strikethrough(e.done, color: AppTheme.textTertiary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.vertical, 9)
        }
        .frame(minHeight: 36)
    }

    private func dotColor(_ e: TimelineEntry) -> Color {
        switch e.kind {
        case .prayer: return AppTheme.accentAmber
        case .event:  return AppTheme.accent
        case .task:   return AppTheme.accentSecondary
        case .now:    return AppTheme.accent
        }
    }

    private func iconColor(_ e: TimelineEntry, _ isPast: Bool) -> Color {
        isPast ? AppTheme.textTertiary : dotColor(e)
    }
}

// MARK: - Confetti (one-shot micro-interaction)

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var rotation: Double
    var opacity: Double
}

struct ConfettiView: View {
    let trigger: Int
    @State private var pieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 0.6)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(x: piece.x, y: piece.y)
                        .opacity(piece.opacity)
                }
            }
            .onChange(of: trigger) { _, _ in fire(in: geo.size) }
        }
        .allowsHitTesting(false)
    }

    private func fire(in size: CGSize) {
        guard size.width > 0 else { return }
        let colors = [AppTheme.accent, AppTheme.accentSecondary, AppTheme.accentGreen, AppTheme.accentAmber]
        let originX = size.width / 2
        let originY = size.height * 0.32
        var new: [ConfettiPiece] = []
        for _ in 0..<28 {
            new.append(ConfettiPiece(
                x: originX,
                y: originY,
                size: CGFloat.random(in: 7...11),
                color: colors.randomElement() ?? AppTheme.accent,
                rotation: Double.random(in: 0...360),
                opacity: 1
            ))
        }
        pieces = new
        withAnimation(.easeOut(duration: 1.4)) {
            for i in pieces.indices {
                pieces[i].x += CGFloat.random(in: -size.width / 2 ... size.width / 2)
                pieces[i].y += CGFloat.random(in: 150...360)
                pieces[i].rotation += Double.random(in: -300...300)
                pieces[i].opacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            pieces = []
        }
    }
}
