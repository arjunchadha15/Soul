import SwiftUI
import Foundation

// MARK: - Visual States

enum BranchState {
    case seedling   // just started (< 14 days old)
    case growing    // active and being updated
    case dormant    // paused
    case completed  // finished

    var opacity: Double {
        switch self {
        case .seedling:  return 0.65
        case .growing:   return 1.0
        case .dormant:   return 0.38
        case .completed: return 0.72
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .seedling:  return 1.5
        case .growing:   return 2.5
        case .dormant:   return 1.5
        case .completed: return 2.0
        }
    }

    var color: Color {
        switch self {
        case .seedling:  return Color(red: 0.6, green: 0.9, blue: 0.6)
        case .growing:   return Color(red: 0.961, green: 0.902, blue: 0.784) // soulAccent
        case .dormant:   return Color(white: 0.5)
        case .completed: return Color(red: 0.85, green: 0.78, blue: 0.65)
        }
    }
}

// MARK: - Layout Models

struct NodeLayout: Identifiable {
    let id: UUID
    let update: ProjectUpdate
    let position: CGPoint
    let isRecent: Bool
}

enum BranchSide { case left, right }

struct BranchLayout: Identifiable {
    let id: UUID            // = project.id
    let project: Project
    let side: BranchSide
    let trunkAttach: CGPoint
    let controlPoint1: CGPoint
    let controlPoint2: CGPoint
    let endPoint: CGPoint
    let labelPoint: CGPoint
    let nodes: [NodeLayout]
    let state: BranchState
    let thickness: CGFloat
}

struct TreeLayout {
    let canvasSize: CGSize
    let trunkX: CGFloat
    let trunkTop: CGPoint       // present (low Y)
    let trunkBottom: CGPoint    // root (high Y)
    let branches: [BranchLayout]
}

// MARK: - Engine

final class TreeLayoutEngine {
    // Layout constants
    private let pixelsPerDay: CGFloat = 2.8
    private let minCanvasHeight: CGFloat = 520
    private let trunkTopPad: CGFloat = 80
    private let trunkBottomPad: CGFloat = 100
    private let branchLength: CGFloat = 128
    private let branchRise: CGFloat = 36
    private let recentThreshold: TimeInterval = 60 * 60 * 24 * 7 // 7 days

    func compute(
        user: AppUser,
        projects: [Project],
        updatesByProject: [UUID: [ProjectUpdate]],
        canvasWidth: CGFloat
    ) -> TreeLayout {
        let rootDate = user.createdAt
        let now = Date()

        let totalDays = max(
            CGFloat(Calendar.current.dateComponents([.day], from: rootDate, to: now).day ?? 1),
            180
        )
        let contentH = totalDays * pixelsPerDay
        let canvasH = max(contentH + trunkTopPad + trunkBottomPad, minCanvasHeight)

        let trunkX = canvasWidth / 2
        let trunkBottom = CGPoint(x: trunkX, y: canvasH - trunkBottomPad)  // root
        let trunkTop    = CGPoint(x: trunkX, y: trunkTopPad)                // now

        func yFor(_ date: Date) -> CGFloat {
            let days = CGFloat(Calendar.current.dateComponents([.day], from: rootDate, to: date).day ?? 0)
            return trunkBottom.y - days * pixelsPerDay
        }

        let sorted = projects.sorted { $0.startDate < $1.startDate }
        var branches: [BranchLayout] = []

        for (i, project) in sorted.enumerated() {
            let side: BranchSide = i % 2 == 0 ? .right : .left
            let sign: CGFloat = side == .right ? 1 : -1

            let attachY = max(yFor(project.startDate), trunkTop.y + 20)
            let attach = CGPoint(x: trunkX, y: attachY)
            let end = CGPoint(x: trunkX + sign * branchLength, y: attachY - branchRise)

            // Organic cubic bezier control points
            let cp1 = CGPoint(x: trunkX + sign * branchLength * 0.25, y: attachY + 4)
            let cp2 = CGPoint(x: end.x - sign * 18, y: end.y + 12)

            // Label sits just past the branch tip
            let labelPad: CGFloat = 8
            let labelX = side == .right ? end.x + labelPad : end.x - labelPad
            let labelPoint = CGPoint(x: labelX, y: end.y - 6)

            let updates = updatesByProject[project.id] ?? []
            let state = branchState(project: project)
            let thickness = min(4.0, max(1.5, CGFloat(updates.count) * 0.35 + 1.5))

            let nodes = computeNodes(
                updates: updates,
                attach: attach, cp1: cp1, cp2: cp2, end: end
            )

            branches.append(BranchLayout(
                id: project.id,
                project: project,
                side: side,
                trunkAttach: attach,
                controlPoint1: cp1,
                controlPoint2: cp2,
                endPoint: end,
                labelPoint: labelPoint,
                nodes: nodes,
                state: state,
                thickness: thickness
            ))
        }

        return TreeLayout(
            canvasSize: CGSize(width: canvasWidth, height: canvasH),
            trunkX: trunkX,
            trunkTop: trunkTop,
            trunkBottom: trunkBottom,
            branches: branches
        )
    }

    // MARK: - Helpers

    private func branchState(project: Project) -> BranchState {
        switch project.status {
        case .active:
            let age = Calendar.current.dateComponents([.day], from: project.startDate, to: Date()).day ?? 0
            return age < 14 ? .seedling : .growing
        case .paused:
            return .dormant
        case .completed:
            return .completed
        }
    }

    private func computeNodes(
        updates: [ProjectUpdate],
        attach: CGPoint, cp1: CGPoint, cp2: CGPoint, end: CGPoint
    ) -> [NodeLayout] {
        guard !updates.isEmpty else { return [] }
        let sorted = updates.sorted { $0.createdAt < $1.createdAt }
        let now = Date()
        return sorted.enumerated().map { index, update in
            let t = CGFloat(index + 1) / CGFloat(sorted.count + 1) * 0.82 + 0.1
            let pt = bezier(t: t, p0: attach, p1: cp1, p2: cp2, p3: end)
            let isRecent = now.timeIntervalSince(update.createdAt) < 7 * 24 * 3600
            return NodeLayout(id: update.id, update: update, position: pt, isRecent: isRecent)
        }
    }

    private func bezier(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let u = 1 - t
        return CGPoint(
            x: u*u*u*p0.x + 3*u*u*t*p1.x + 3*u*t*t*p2.x + t*t*t*p3.x,
            y: u*u*u*p0.y + 3*u*u*t*p1.y + 3*u*t*t*p2.y + t*t*t*p3.y
        )
    }
}
