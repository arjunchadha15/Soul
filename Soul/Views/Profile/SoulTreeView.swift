import SwiftUI

struct SoulTreeView: View {
    let layout: TreeLayout
    let user: AppUser
    var onBranchTap: (Project) -> Void
    var onNodeTap: (ProjectUpdate, Project) -> Void

    @State private var scale: CGFloat = 1.0
    @GestureState private var pinchScale: CGFloat = 1.0

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                // ── Drawing layer ──
                Canvas { ctx, _ in
                    drawTrunk(ctx: &ctx)
                    for branch in layout.branches {
                        drawBranch(ctx: &ctx, branch: branch)
                    }
                }
                .frame(
                    width: layout.canvasSize.width,
                    height: layout.canvasSize.height
                )

                // ── Overlay: branches ──
                ForEach(layout.branches) { branch in
                    // Invisible tap target over the whole branch endpoint area
                    Button { onBranchTap(branch.project) } label: {
                        Circle().fill(Color.clear).frame(width: 56, height: 56)
                    }
                    .position(branch.endPoint)

                    // Branch tip dot
                    Circle()
                        .fill(branch.state.color)
                        .frame(width: 6, height: 6)
                        .opacity(branch.state.opacity)
                        .position(branch.endPoint)

                    // Project label
                    Text(branch.project.title)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(branch.state.color.opacity(branch.state.opacity))
                        .lineLimit(2)
                        .multilineTextAlignment(branch.side == .right ? .leading : .trailing)
                        .frame(width: 90, alignment: branch.side == .right ? .leading : .trailing)
                        .position(branch.labelPoint)
                        .allowsHitTesting(false)

                    // Update nodes
                    ForEach(branch.nodes) { node in
                        Button { onNodeTap(node.update, branch.project) } label: {
                            ZStack {
                                if node.isRecent {
                                    Circle()
                                        .fill(Color.soulAccent.opacity(0.25))
                                        .frame(width: 18, height: 18)
                                }
                                Circle()
                                    .fill(Color.soulAccent)
                                    .frame(width: 7, height: 7)
                                    .shadow(color: Color.soulAccent.opacity(0.7), radius: node.isRecent ? 5 : 2)
                            }
                        }
                        .position(node.position)
                    }
                }

                // ── Root marker ──
                VStack(spacing: 5) {
                    Circle()
                        .fill(Color.soulAccent.opacity(0.5))
                        .frame(width: 12, height: 12)
                    Text("Your journey begins")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.soulTextSecondary)
                }
                .position(x: layout.trunkX, y: layout.trunkBottom.y + 28)

                // ── Present marker ──
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(Color.soulAccent.opacity(0.25))
                        .frame(height: 1)
                    Text("Now")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.soulAccent.opacity(0.5))
                    Rectangle()
                        .fill(Color.soulAccent.opacity(0.25))
                        .frame(height: 1)
                }
                .frame(width: layout.canvasSize.width * 0.5)
                .position(x: layout.trunkX, y: layout.trunkTop.y - 20)
            }
            .frame(
                width: layout.canvasSize.width,
                height: layout.canvasSize.height + 60  // extra room for root label
            )
            .scaleEffect(scale * pinchScale, anchor: .center)
            .gesture(
                MagnificationGesture()
                    .updating($pinchScale) { value, state, _ in state = value }
                    .onEnded { value in scale = min(max(scale * value, 0.5), 3.0) }
            )
        }
        .background(Color.soulBackground)
    }

    // MARK: - Drawing

    private func drawTrunk(ctx: inout GraphicsContext) {
        var path = Path()
        path.move(to: layout.trunkBottom)
        path.addLine(to: layout.trunkTop)

        ctx.stroke(
            path,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: Color.soulAccent.opacity(0.18), location: 0),
                    .init(color: Color.soulAccent.opacity(0.55), location: 0.5),
                    .init(color: Color.soulAccent.opacity(0.30), location: 1),
                ]),
                startPoint: layout.trunkBottom,
                endPoint: layout.trunkTop
            ),
            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
        )
    }

    private func drawBranch(ctx: inout GraphicsContext, branch: BranchLayout) {
        var path = Path()
        path.move(to: branch.trunkAttach)
        path.addCurve(
            to: branch.endPoint,
            control1: branch.controlPoint1,
            control2: branch.controlPoint2
        )

        ctx.stroke(
            path,
            with: .color(branch.state.color.opacity(branch.state.opacity)),
            style: StrokeStyle(
                lineWidth: branch.thickness,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }
}
