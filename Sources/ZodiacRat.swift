import SwiftUI
import Foundation

extension PelicanArt {
    static func drawRatBody(_ c: inout GraphicsContext, t: Double, d: PelicanDraw,
                            p: Pose, walkPhase: Double) -> HeadInfo {
        let bed = d.hpState == .bedridden
        let outline = Color(red: 0.60, green: 0.60, blue: 0.66)
        let bodyC = Color(red: 0.78, green: 0.78, blue: 0.82)
        let footC = Color(red: 0.85, green: 0.76, blue: 0.78)

        // 细长波浪卷尾（老鼠标志）
        var tg = c
        tg.translateBy(x: -32, y: 8)
        tg.rotate(by: .degrees(p.swing2 * 0.3))
        var tail = Path()
        tail.move(to: .zero)
        tail.addQuadCurve(to: CGPoint(x: -16, y: 12), control: CGPoint(x: -18, y: -6))
        tail.addQuadCurve(to: CGPoint(x: -26, y: 2), control: CGPoint(x: -14, y: 18))
        tail.addQuadCurve(to: CGPoint(x: -31, y: -8), control: CGPoint(x: -34, y: -4))
        tg.stroke(tail, with: .color(Color(red: 0.70, green: 0.70, blue: 0.75)),
                  style: StrokeStyle(lineWidth: 2, lineCap: .round))
        // 身体（拉长，更像鼠）
        var bb = c
        bb.rotate(by: .degrees(-8))
        let bodyR = CGRect(x: -38, y: -18, width: 68, height: 46)
        bb.fill(Path(ellipseIn: bodyR), with: .color(bodyC))
        bb.stroke(Path(ellipseIn: bodyR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = bodyTint(d) { bb.fill(Path(ellipseIn: bodyR), with: .color(col.opacity(a))) }
        c.fill(Path(ellipseIn: CGRect(x: -20, y: -4, width: 30, height: 26)),
               with: .color(Color(red: 0.93, green: 0.93, blue: 0.95)))
        // 短腿
        if !bed {
            drawLeg(c, hip: CGPoint(x: -20, y: 15), angle: -sin(walkPhase) * p.swing, color: footC, length: 11, width: 4.5)
            drawLeg(c, hip: CGPoint(x: -12, y: 17), angle: sin(walkPhase) * p.swing, color: footC, length: 11, width: 4.5)
            drawLeg(c, hip: CGPoint(x: 6, y: 17), angle: -sin(walkPhase) * p.swing, color: footC, length: 11, width: 4.5)
            drawLeg(c, hip: CGPoint(x: 14, y: 15), angle: sin(walkPhase) * p.swing, color: footC, length: 11, width: 4.5)
        }
        // 大圆耳朵
        var earL = c
        earL.translateBy(x: 18, y: -38)
        earL.rotate(by: .degrees(-14 + p.swing2 * 0.15))
        earL.fill(Path(ellipseIn: CGRect(x: -8, y: -4, width: 16, height: 16)), with: .color(bodyC))
        earL.stroke(Path(ellipseIn: CGRect(x: -8, y: -4, width: 16, height: 16)), with: .color(outline), lineWidth: 1.3)
        earL.fill(Path(ellipseIn: CGRect(x: -4, y: 0, width: 8, height: 8)), with: .color(earInner))
        var earR = c
        earR.translateBy(x: 38, y: -36)
        earR.rotate(by: .degrees(10 + p.swing2 * 0.15))
        earR.fill(Path(ellipseIn: CGRect(x: -8, y: -4, width: 16, height: 16)), with: .color(bodyC))
        earR.stroke(Path(ellipseIn: CGRect(x: -8, y: -4, width: 16, height: 16)), with: .color(outline), lineWidth: 1.3)
        earR.fill(Path(ellipseIn: CGRect(x: -4, y: 0, width: 8, height: 8)), with: .color(earInner))
        // 尖吻楔形（头后叠加在头上，形成尖嘴）
        var snout = Path()
        snout.move(to: CGPoint(x: 8, y: -8))
        snout.addQuadCurve(to: CGPoint(x: 21, y: -1), control: CGPoint(x: 17, y: -9))
        snout.addQuadCurve(to: CGPoint(x: 8, y: 6), control: CGPoint(x: 17, y: 3))
        snout.closeSubpath()
        var hg = c
        hg.translateBy(x: 30, y: -27)
        hg.rotate(by: Angle(radians: p.headTilt))
        let headR = CGRect(x: -18, y: -13, width: 34, height: 27)
        hg.fill(Path(ellipseIn: headR), with: .color(bodyC))
        hg.stroke(Path(ellipseIn: headR), with: .color(outline), lineWidth: 1.5)
        hg.fill(snout, with: .color(bodyC))
        if let (col, a) = headTint(d) {
            hg.fill(Path(ellipseIn: headR), with: .color(col.opacity(a)))
            hg.fill(snout, with: .color(col.opacity(a)))
        }
        var snoutEdge = Path()
        snoutEdge.move(to: CGPoint(x: 8, y: -8))
        snoutEdge.addQuadCurve(to: CGPoint(x: 21, y: -1), control: CGPoint(x: 17, y: -9))
        snoutEdge.addQuadCurve(to: CGPoint(x: 8, y: 6), control: CGPoint(x: 17, y: 3))
        hg.stroke(snoutEdge, with: .color(outline), lineWidth: 1.2)
        drawEye(hg, CGPoint(x: 2, y: -5), p.eyes, eyelid: bodyC)
        if d.mood == .angry {
            var brow = Path()
            brow.move(to: CGPoint(x: -3, y: -12))
            brow.addLine(to: CGPoint(x: 6, y: -9))
            hg.stroke(brow, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        // 粉鼻（吻尖）+ 小嘴 + 门牙
        hg.fill(Path(ellipseIn: CGRect(x: 17, y: -4, width: 6, height: 5)), with: .color(nosePink))
        var mouth = Path()
        mouth.move(to: CGPoint(x: 19.5, y: 1.5))
        mouth.addQuadCurve(to: CGPoint(x: 15, y: 5), control: CGPoint(x: 19.5, y: 3.8))
        mouth.addQuadCurve(to: CGPoint(x: 23, y: 5), control: CGPoint(x: 19.5, y: 3.8))
        hg.stroke(mouth, with: .color(.black.opacity(0.35)), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
        if p.mouthOpen {
            hg.fill(Path(ellipseIn: CGRect(x: 17, y: 2.5, width: 5, height: 4)), with: .color(.black.opacity(0.3)))
        }
        hg.fill(Path(roundedRect: CGRect(x: 17, y: 5, width: 2.4, height: 3.4), cornerRadius: 1), with: .color(.white))
        hg.fill(Path(roundedRect: CGRect(x: 19.8, y: 5, width: 2.4, height: 3.4), cornerRadius: 1), with: .color(.white))
        // 胡须
        for dy in [-2.0, 1.5] {
            var w = Path()
            w.move(to: CGPoint(x: 17, y: dy))
            w.addLine(to: CGPoint(x: 27, y: dy - 2))
            hg.stroke(w, with: .color(.black.opacity(0.2)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        }
        drawHeadSymptoms(&hg, t: t, d: d, mouthLocal: CGPoint(x: 20, y: 1))
        return HeadInfo(center: CGPoint(x: 30, y: -27), radius: 16, mouthTip: CGPoint(x: 51, y: -26))
    }
}
