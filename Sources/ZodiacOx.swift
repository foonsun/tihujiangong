import SwiftUI
import Foundation

extension PelicanArt {
    static func drawOxBody(_ c: inout GraphicsContext, t: Double, d: PelicanDraw,
                           p: Pose, walkPhase: Double) -> HeadInfo {
        let bed = d.hpState == .bedridden
        let outline = Color(red: 0.55, green: 0.42, blue: 0.30)
        let bodyC = Color(red: 0.72, green: 0.55, blue: 0.40)
        let hornC = Color(red: 0.90, green: 0.88, blue: 0.80)

        // 小尾 + 尾簇
        var tg = c
        tg.translateBy(x: -32, y: -12)
        tg.rotate(by: .degrees(p.swing2 * 0.4))
        var tail = Path()
        tail.move(to: .zero)
        tail.addQuadCurve(to: CGPoint(x: -6, y: 18), control: CGPoint(x: -10, y: 8))
        tg.stroke(tail, with: .color(outline), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        tg.fill(Path(ellipseIn: CGRect(x: -9, y: 15, width: 8, height: 9)),
                with: .color(Color(red: 0.45, green: 0.33, blue: 0.22)))
        // 身体
        let bb = c
        let bodyR = CGRect(x: -36, y: -22, width: 66, height: 50)
        bb.fill(Path(ellipseIn: bodyR), with: .color(bodyC))
        bb.stroke(Path(ellipseIn: bodyR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = bodyTint(d) { bb.fill(Path(ellipseIn: bodyR), with: .color(col.opacity(a))) }
        c.fill(Path(ellipseIn: CGRect(x: -16, y: -4, width: 30, height: 28)),
               with: .color(Color(red: 0.93, green: 0.87, blue: 0.75)))
        // 粗短腿
        if !bed {
            drawLeg(c, hip: CGPoint(x: -18, y: 16), angle: -sin(walkPhase) * p.swing, color: outline, length: 13, width: 6)
            drawLeg(c, hip: CGPoint(x: 18, y: 16), angle: sin(walkPhase) * p.swing, color: outline, length: 13, width: 6)
            drawLeg(c, hip: CGPoint(x: -10, y: 20), angle: sin(walkPhase) * p.swing, color: bodyC, length: 13, width: 6)
            drawLeg(c, hip: CGPoint(x: 10, y: 20), angle: -sin(walkPhase) * p.swing, color: bodyC, length: 13, width: 6)
        }
        // 头
        var hg = c
        hg.translateBy(x: 30, y: -27)
        hg.rotate(by: Angle(radians: p.headTilt))
        // 大弯角（向外上扬，画在头前，基部被头盖住）
        var hornL = Path()
        hornL.move(to: CGPoint(x: -11, y: -10))
        hornL.addQuadCurve(to: CGPoint(x: -23, y: -22), control: CGPoint(x: -21, y: -13))
        hg.stroke(hornL, with: .color(hornC), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        var hornR = Path()
        hornR.move(to: CGPoint(x: 7, y: -12))
        hornR.addQuadCurve(to: CGPoint(x: 17, y: -25), control: CGPoint(x: 13, y: -22))
        hg.stroke(hornR, with: .color(hornC), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        // 小耳朵
        hg.fill(Path(ellipseIn: CGRect(x: -20, y: -8, width: 8, height: 6)), with: .color(bodyC))
        hg.fill(Path(ellipseIn: CGRect(x: 12, y: -10, width: 8, height: 6)), with: .color(bodyC))
        let headR = CGRect(x: -18, y: -16, width: 36, height: 31)
        hg.fill(Path(ellipseIn: headR), with: .color(bodyC))
        hg.stroke(Path(ellipseIn: headR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = headTint(d) { hg.fill(Path(ellipseIn: headR), with: .color(col.opacity(a))) }
        // 下巴肉垂（牛的特征）
        hg.fill(Path(ellipseIn: CGRect(x: 7, y: 7, width: 11, height: 9)), with: .color(bodyC))
        hg.stroke(Path(ellipseIn: CGRect(x: 7, y: 7, width: 11, height: 9)), with: .color(outline), lineWidth: 1.1)
        // 浅色吻部 + 大鼻孔
        hg.fill(Path(ellipseIn: CGRect(x: 6, y: -7, width: 18, height: 14)),
                with: .color(Color(red: 0.90, green: 0.83, blue: 0.70)))
        hg.fill(Path(ellipseIn: CGRect(x: 10, y: -3, width: 3.5, height: 4.5)), with: .color(.black.opacity(0.35)))
        hg.fill(Path(ellipseIn: CGRect(x: 18, y: -3, width: 3.5, height: 4.5)), with: .color(.black.opacity(0.35)))
        if p.mouthOpen {
            hg.fill(Path(ellipseIn: CGRect(x: 12, y: 4, width: 8, height: 4)), with: .color(.black.opacity(0.3)))
        }
        drawEye(hg, CGPoint(x: -2, y: -6), p.eyes, eyelid: bodyC)
        if d.mood == .angry {
            var brow = Path()
            brow.move(to: CGPoint(x: -7, y: -13))
            brow.addLine(to: CGPoint(x: 2, y: -10))
            hg.stroke(brow, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        drawHeadSymptoms(&hg, t: t, d: d, mouthLocal: CGPoint(x: 21, y: 6))
        return HeadInfo(center: CGPoint(x: 30, y: -27), radius: 16, mouthTip: CGPoint(x: 51, y: -21))
    }
}
