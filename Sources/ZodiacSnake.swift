import SwiftUI
import Foundation

extension PelicanArt {
    static func drawSnakeBody(_ c: inout GraphicsContext, t: Double, d: PelicanDraw,
                              p: Pose, walkPhase: Double) -> HeadInfo {
        let outline = Color(red: 0.42, green: 0.62, blue: 0.36)
        let bodyC = Color(red: 0.55, green: 0.78, blue: 0.45)
        let bellyC = Color(red: 0.85, green: 0.93, blue: 0.70)
        let wobble = sin(t * 2) * 1.2

        // 盘绕身体：三层同心圈（真正的蛇盘姿态）
        let coils: [(rect: CGRect, w: CGFloat)] = [
            (CGRect(x: -25, y: -2, width: 46, height: 32), 13),
            (CGRect(x: -18, y: 3, width: 33, height: 24), 11),
            (CGRect(x: -12, y: 7, width: 21, height: 16), 9)
        ]
        var cg = c
        cg.translateBy(x: 0, y: wobble * 0.5)
        for co in coils {
            cg.stroke(Path(ellipseIn: co.rect), with: .color(bodyC),
                      style: StrokeStyle(lineWidth: co.w, lineJoin: .round))
            cg.stroke(Path(ellipseIn: co.rect), with: .color(bellyC),
                      style: StrokeStyle(lineWidth: co.w * 0.38, lineJoin: .round))
        }
        // 颈部：从内圈顶部伸到头
        var neck = Path()
        neck.move(to: CGPoint(x: 0, y: 6))
        neck.addQuadCurve(to: CGPoint(x: 21, y: -16), control: CGPoint(x: 16, y: 0))
        cg.stroke(neck, with: .color(bodyC), style: StrokeStyle(lineWidth: 11, lineCap: .round))
        cg.stroke(neck, with: .color(bellyC), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
        if let (col, a) = bodyTint(d) {
            for co in coils {
                cg.stroke(Path(ellipseIn: co.rect), with: .color(col.opacity(a * 0.7)),
                          style: StrokeStyle(lineWidth: co.w, lineJoin: .round))
            }
            cg.stroke(neck, with: .color(col.opacity(a * 0.7)),
                      style: StrokeStyle(lineWidth: 11, lineCap: .round))
        }
        // 头
        var hg = c
        hg.translateBy(x: 30, y: -27)
        hg.rotate(by: Angle(radians: p.headTilt))
        let headR = CGRect(x: -15, y: -14, width: 30, height: 28)
        hg.fill(Path(ellipseIn: headR), with: .color(bodyC))
        hg.stroke(Path(ellipseIn: headR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = headTint(d) { hg.fill(Path(ellipseIn: headR), with: .color(col.opacity(a))) }
        // 头顶浅斑
        hg.fill(Path(ellipseIn: CGRect(x: -10, y: -13, width: 14, height: 6)), with: .color(bellyC))
        drawEye(hg, CGPoint(x: 3, y: -5), p.eyes, eyelid: bodyC)
        if d.mood == .angry {
            var brow = Path()
            brow.move(to: CGPoint(x: -2, y: -12))
            brow.addLine(to: CGPoint(x: 7, y: -9))
            hg.stroke(brow, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        // 鼻孔 + 嘴
        hg.fill(Path(ellipseIn: CGRect(x: 15, y: -3, width: 2.5, height: 2)), with: .color(.black.opacity(0.4)))
        var mouth = Path()
        mouth.move(to: CGPoint(x: 17, y: 2))
        mouth.addQuadCurve(to: CGPoint(x: 10, y: 5), control: CGPoint(x: 15, y: 4.5))
        hg.stroke(mouth, with: .color(.black.opacity(0.4)), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
        // 分叉信子（伸缩动效）
        if fmod(t * 0.9, 1) < 0.30 {
            let ph = fmod(t * 0.9, 1) / 0.30
            let ext = 4 + 5 * ph
            var tongue = Path()
            tongue.move(to: CGPoint(x: 17, y: 3))
            tongue.addLine(to: CGPoint(x: 17 + ext, y: 4))
            tongue.move(to: CGPoint(x: 17 + ext, y: 4))
            tongue.addLine(to: CGPoint(x: 17 + ext + 3, y: 1))
            tongue.move(to: CGPoint(x: 17 + ext, y: 4))
            tongue.addLine(to: CGPoint(x: 17 + ext + 3, y: 7))
            hg.stroke(tongue, with: .color(red), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
        drawHeadSymptoms(&hg, t: t, d: d, mouthLocal: CGPoint(x: 18, y: 3))
        return HeadInfo(center: CGPoint(x: 30, y: -27), radius: 15, mouthTip: CGPoint(x: 48, y: -24))
    }
}
