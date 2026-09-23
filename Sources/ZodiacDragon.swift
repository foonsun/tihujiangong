import SwiftUI
import Foundation

extension PelicanArt {
    static func drawDragonBody(_ c: inout GraphicsContext, t: Double, d: PelicanDraw,
                               p: Pose, walkPhase: Double) -> HeadInfo {
        let bed = d.hpState == .bedridden
        let outline = Color(red: 0.40, green: 0.62, blue: 0.45)
        let bodyC = Color(red: 0.55, green: 0.80, blue: 0.60)
        let goldC = Color(red: 0.98, green: 0.83, blue: 0.40)

        // 细长尾 + 金色铲尖
        var tg = c
        tg.translateBy(x: -30, y: 6)
        tg.rotate(by: .degrees(p.swing2 * 0.8))
        var tail = Path()
        tail.move(to: .zero)
        tail.addQuadCurve(to: CGPoint(x: -14, y: -16), control: CGPoint(x: -20, y: 4))
        tg.stroke(tail, with: .color(bodyC), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        tg.fill(Path(ellipseIn: CGRect(x: -19, y: -22, width: 9, height: 8)), with: .color(goldC))
        // 身体
        let bb = c
        let bodyR = CGRect(x: -34, y: -22, width: 64, height: 50)
        bb.fill(Path(ellipseIn: bodyR), with: .color(bodyC))
        bb.stroke(Path(ellipseIn: bodyR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = bodyTint(d) { bb.fill(Path(ellipseIn: bodyR), with: .color(col.opacity(a))) }
        // 奶油肚皮
        c.fill(Path(ellipseIn: CGRect(x: -18, y: -8, width: 34, height: 30)),
               with: .color(Color(red: 0.93, green: 0.95, blue: 0.82)))
        // 背部小软刺
        for sx in [-20.0, -8.0, 4.0] {
            var s = Path()
            s.move(to: CGPoint(x: sx, y: -20))
            s.addLine(to: CGPoint(x: sx + 5, y: -31))
            s.addLine(to: CGPoint(x: sx + 10, y: -19))
            s.closeSubpath()
            c.fill(s, with: .color(goldC))
        }
        // 小圆翅膀
        var wg = c
        wg.translateBy(x: -14, y: -10)
        wg.rotate(by: .degrees(p.swing2 * 0.5))
        wg.fill(Path(ellipseIn: CGRect(x: -12, y: -8, width: 20, height: 16)), with: .color(goldC.opacity(0.85)))
        // 腿（带金色爪尖）
        if !bed {
            drawLeg(c, hip: CGPoint(x: -12, y: 18), angle: -sin(walkPhase) * p.swing, color: bodyC, length: 11, width: 5)
            drawLeg(c, hip: CGPoint(x: 10, y: 19), angle: sin(walkPhase) * p.swing, color: bodyC, length: 11, width: 5)
        }
        // 头
        var hg = c
        hg.translateBy(x: 30, y: -27)
        hg.rotate(by: Angle(radians: p.headTilt))
        // 金色分叉龙角（鹿角状，画在头前）
        var hornL = Path()
        hornL.move(to: CGPoint(x: -10, y: -12))
        hornL.addQuadCurve(to: CGPoint(x: -17, y: -26), control: CGPoint(x: -15, y: -18))
        hg.stroke(hornL, with: .color(goldC), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        var tineL = Path()
        tineL.move(to: CGPoint(x: -13, y: -19))
        tineL.addQuadCurve(to: CGPoint(x: -19, y: -23), control: CGPoint(x: -14, y: -23))
        hg.stroke(tineL, with: .color(goldC), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        var hornR = Path()
        hornR.move(to: CGPoint(x: 4, y: -14))
        hornR.addQuadCurve(to: CGPoint(x: 3, y: -28), control: CGPoint(x: 9, y: -24))
        hg.stroke(hornR, with: .color(goldC), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        var tineR = Path()
        tineR.move(to: CGPoint(x: 4, y: -22))
        tineR.addQuadCurve(to: CGPoint(x: -2, y: -26), control: CGPoint(x: 3, y: -27))
        hg.stroke(tineR, with: .color(goldC), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        // 吻部楔形
        var snout = Path()
        snout.move(to: CGPoint(x: 8, y: -6))
        snout.addQuadCurve(to: CGPoint(x: 22, y: -1), control: CGPoint(x: 18, y: -7))
        snout.addQuadCurve(to: CGPoint(x: 8, y: 5), control: CGPoint(x: 18, y: 3))
        snout.closeSubpath()
        let headR = CGRect(x: -16, y: -14, width: 33, height: 29)
        hg.fill(Path(ellipseIn: headR), with: .color(bodyC))
        hg.stroke(Path(ellipseIn: headR), with: .color(outline), lineWidth: 1.5)
        hg.fill(snout, with: .color(bodyC))
        if let (col, a) = headTint(d) {
            hg.fill(Path(ellipseIn: headR), with: .color(col.opacity(a)))
            hg.fill(snout, with: .color(col.opacity(a)))
        }
        var snoutEdge = Path()
        snoutEdge.move(to: CGPoint(x: 8, y: -6))
        snoutEdge.addQuadCurve(to: CGPoint(x: 22, y: -1), control: CGPoint(x: 18, y: -7))
        snoutEdge.addQuadCurve(to: CGPoint(x: 8, y: 5), control: CGPoint(x: 18, y: 3))
        hg.stroke(snoutEdge, with: .color(outline), lineWidth: 1.2)
        // 金色长龙须（下垂外卷）
        var barbelL = Path()
        barbelL.move(to: CGPoint(x: 11, y: 1))
        barbelL.addQuadCurve(to: CGPoint(x: 7, y: 17), control: CGPoint(x: 19, y: 7))
        hg.stroke(barbelL, with: .color(goldC), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        var barbelR = Path()
        barbelR.move(to: CGPoint(x: 18, y: 3))
        barbelR.addQuadCurve(to: CGPoint(x: 25, y: 16), control: CGPoint(x: 29, y: 8))
        hg.stroke(barbelR, with: .color(goldC), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        // 鼻 + 嘴
        hg.fill(Path(ellipseIn: CGRect(x: 18, y: -4, width: 6, height: 5)), with: .color(nosePink))
        var mouth = Path()
        mouth.move(to: CGPoint(x: 21, y: 1))
        mouth.addQuadCurve(to: CGPoint(x: 15, y: 5), control: CGPoint(x: 20, y: 4))
        hg.stroke(mouth, with: .color(.black.opacity(0.4)), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
        if p.mouthOpen {
            hg.fill(Path(ellipseIn: CGRect(x: 15, y: 1.5, width: 7, height: 5)), with: .color(.black.opacity(0.3)))
        }
        drawEye(hg, CGPoint(x: 0, y: -5), p.eyes, eyelid: bodyC)
        if d.mood == .angry {
            var brow = Path()
            brow.move(to: CGPoint(x: -5, y: -12))
            brow.addLine(to: CGPoint(x: 4, y: -9))
            hg.stroke(brow, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        drawHeadSymptoms(&hg, t: t, d: d, mouthLocal: CGPoint(x: 22, y: 1))
        return HeadInfo(center: CGPoint(x: 30, y: -27), radius: 16, mouthTip: CGPoint(x: 52, y: -26))
    }
}
