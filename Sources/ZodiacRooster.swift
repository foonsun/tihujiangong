import SwiftUI
import Foundation

extension PelicanArt {
    static func drawRoosterBody(_ c: inout GraphicsContext, t: Double, d: PelicanDraw,
                                p: Pose, walkPhase: Double) -> HeadInfo {
        let bed = d.hpState == .bedridden
        let outline = Color(red: 0.85, green: 0.80, blue: 0.70)
        let bodyC = Color(red: 0.97, green: 0.94, blue: 0.88)

        // 彩色尾羽（4 根扇形）
        let tailCols: [Color] = [Color(red: 0.45, green: 0.62, blue: 0.85),
                                 Color(red: 0.50, green: 0.75, blue: 0.45),
                                 red, footOrange]
        let tailAngs: [Double] = [-55, -35, -15, 5]
        for (i, ang) in tailAngs.enumerated() {
            var tf = c
            tf.translateBy(x: -24, y: -4)
            tf.rotate(by: .degrees(ang + p.swing2 * 0.1))
            var fp = Path()
            fp.move(to: .zero)
            fp.addQuadCurve(to: CGPoint(x: -30, y: -20), control: CGPoint(x: -30, y: -6))
            tf.stroke(fp, with: .color(tailCols[i]), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
        }
        // 身体
        let bb = c
        let bodyR = CGRect(x: -32, y: -22, width: 58, height: 52)
        bb.fill(Path(ellipseIn: bodyR), with: .color(bodyC))
        bb.stroke(Path(ellipseIn: bodyR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = bodyTint(d) { bb.fill(Path(ellipseIn: bodyR), with: .color(col.opacity(a))) }
        // 翅膀
        var wg = c
        wg.translateBy(x: -10, y: -2)
        wg.rotate(by: .degrees(p.swing2 * 0.6))
        wg.fill(Path(ellipseIn: CGRect(x: -16, y: -8, width: 30, height: 20)),
                with: .color(Color(red: 0.90, green: 0.87, blue: 0.80)))
        wg.stroke(Path(ellipseIn: CGRect(x: -16, y: -8, width: 30, height: 20)), with: .color(outline), lineWidth: 1.2)
        // 橙腿
        if !bed {
            drawLeg(c, hip: CGPoint(x: -6, y: 22), angle: -sin(walkPhase) * p.swing, color: footOrange, length: 13, width: 3)
            drawLeg(c, hip: CGPoint(x: 8, y: 22), angle: sin(walkPhase) * p.swing, color: footOrange, length: 13, width: 3)
        }
        // 脖子
        var neck = Path()
        neck.move(to: CGPoint(x: 14, y: -10))
        neck.addLine(to: CGPoint(x: 26, y: -22))
        c.stroke(neck, with: .color(bodyC), style: StrokeStyle(lineWidth: 11, lineCap: .round))
        // 头
        var hg = c
        hg.translateBy(x: 30, y: -27)
        hg.rotate(by: Angle(radians: p.headTilt))
        // 红鸡冠
        hg.fill(Path(ellipseIn: CGRect(x: -9, y: -19, width: 7, height: 8)), with: .color(red))
        hg.fill(Path(ellipseIn: CGRect(x: -2, y: -21, width: 8, height: 10)), with: .color(red))
        hg.fill(Path(ellipseIn: CGRect(x: 6, y: -19, width: 7, height: 8)), with: .color(red))
        let headR = CGRect(x: -14, y: -14, width: 28, height: 28)
        hg.fill(Path(ellipseIn: headR), with: .color(bodyC))
        hg.stroke(Path(ellipseIn: headR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = headTint(d) { hg.fill(Path(ellipseIn: headR), with: .color(col.opacity(a))) }
        // 橙喙
        var beakP = Path()
        beakP.move(to: CGPoint(x: 11, y: -5))
        beakP.addLine(to: CGPoint(x: 25, y: -1))
        beakP.addLine(to: CGPoint(x: 11, y: 2))
        beakP.closeSubpath()
        hg.fill(beakP, with: .color(footOrange))
        if p.mouthOpen {
            hg.fill(Path(CGRect(x: 12, y: -0.5, width: 8, height: 3.5)), with: .color(.black.opacity(0.35)))
        }
        // 红肉垂
        hg.fill(Path(ellipseIn: CGRect(x: 8, y: 3, width: 6, height: 8)), with: .color(red))
        drawEye(hg, CGPoint(x: 2, y: -6), p.eyes)
        if d.mood == .angry {
            var brow = Path()
            brow.move(to: CGPoint(x: -3, y: -13))
            brow.addLine(to: CGPoint(x: 6, y: -10))
            hg.stroke(brow, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        drawHeadSymptoms(&hg, t: t, d: d, mouthLocal: CGPoint(x: 25, y: -1))
        return HeadInfo(center: CGPoint(x: 30, y: -27), radius: 14, mouthTip: CGPoint(x: 55, y: -28))
    }
}
