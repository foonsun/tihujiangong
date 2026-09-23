import SwiftUI
import Foundation

extension PelicanArt {
    static func drawHorseBody(_ c: inout GraphicsContext, t: Double, d: PelicanDraw,
                              p: Pose, walkPhase: Double) -> HeadInfo {
        let bed = d.hpState == .bedridden
        let outline = Color(red: 0.60, green: 0.42, blue: 0.27)
        let bodyC = Color(red: 0.80, green: 0.58, blue: 0.38)
        let maneC = Color(red: 0.45, green: 0.30, blue: 0.20)

        // 大尾巴
        var tg = c
        tg.translateBy(x: -30, y: -12)
        tg.rotate(by: .degrees(p.swing2 * 0.8))
        var tail = Path()
        tail.move(to: .zero)
        tail.addQuadCurve(to: CGPoint(x: -10, y: 16), control: CGPoint(x: -16, y: 4))
        tail.addQuadCurve(to: CGPoint(x: -14, y: 30), control: CGPoint(x: -2, y: 22))
        tg.stroke(tail, with: .color(maneC), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        // 身体
        let bb = c
        let bodyR = CGRect(x: -34, y: -22, width: 66, height: 50)
        bb.fill(Path(ellipseIn: bodyR), with: .color(bodyC))
        bb.stroke(Path(ellipseIn: bodyR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = bodyTint(d) { bb.fill(Path(ellipseIn: bodyR), with: .color(col.opacity(a))) }
        // 胸口浅斑
        c.fill(Path(ellipseIn: CGRect(x: 0, y: -8, width: 26, height: 30)),
               with: .color(Color(red: 0.93, green: 0.85, blue: 0.72)))
        // 长腿
        if !bed {
            drawLeg(c, hip: CGPoint(x: -16, y: 16), angle: -sin(walkPhase) * p.swing, color: bodyC, length: 14, width: 5)
            drawLeg(c, hip: CGPoint(x: 16, y: 16), angle: sin(walkPhase) * p.swing, color: bodyC, length: 14, width: 5)
            drawLeg(c, hip: CGPoint(x: -8, y: 20), angle: sin(walkPhase) * p.swing, color: bodyC, length: 14, width: 5)
            drawLeg(c, hip: CGPoint(x: 8, y: 20), angle: -sin(walkPhase) * p.swing, color: bodyC, length: 14, width: 5)
        }
        // 鬃毛（一列深色椭圆）
        var mg = c
        mg.rotate(by: .degrees(p.swing2 * 0.4))
        for (i, mx) in [-16.0, -6.0, 4.0].enumerated() {
            mg.fill(Path(ellipseIn: CGRect(x: mx, y: -30 - Double(i) * 2, width: 12, height: 12)),
                    with: .color(maneC))
        }
        // 头
        var hg = c
        hg.translateBy(x: 30, y: -27)
        hg.rotate(by: Angle(radians: p.headTilt))
        // 立耳
        var earL = Path()
        earL.move(to: CGPoint(x: -10, y: -10))
        earL.addLine(to: CGPoint(x: -13, y: -24))
        earL.addLine(to: CGPoint(x: -3, y: -13))
        earL.closeSubpath()
        hg.fill(earL, with: .color(bodyC))
        hg.stroke(earL, with: .color(outline), lineWidth: 1.2)
        var earR = Path()
        earR.move(to: CGPoint(x: 2, y: -12))
        earR.addLine(to: CGPoint(x: 2, y: -26))
        earR.addLine(to: CGPoint(x: 9, y: -13))
        earR.closeSubpath()
        hg.fill(earR, with: .color(bodyC))
        hg.stroke(earR, with: .color(outline), lineWidth: 1.2)
        let headR = CGRect(x: -17, y: -14, width: 36, height: 29)
        hg.fill(Path(ellipseIn: headR), with: .color(bodyC))
        hg.stroke(Path(ellipseIn: headR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = headTint(d) { hg.fill(Path(ellipseIn: headR), with: .color(col.opacity(a))) }
        // 刘海
        hg.fill(Path(ellipseIn: CGRect(x: -8, y: -15, width: 12, height: 8)), with: .color(maneC))
        // 吻部 + 鼻孔 + 嘴
        hg.fill(Path(ellipseIn: CGRect(x: 10, y: -8, width: 18, height: 15)),
                with: .color(Color(red: 0.90, green: 0.80, blue: 0.64)))
        hg.fill(Path(ellipseIn: CGRect(x: 19, y: -4, width: 4, height: 3.5)), with: .color(.black.opacity(0.4)))
        var mouth = Path()
        mouth.move(to: CGPoint(x: 22, y: 2))
        mouth.addQuadCurve(to: CGPoint(x: 16, y: 5), control: CGPoint(x: 21, y: 4.5))
        hg.stroke(mouth, with: .color(.black.opacity(0.35)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        if p.mouthOpen {
            hg.fill(Path(ellipseIn: CGRect(x: 17, y: 1.5, width: 7, height: 4.5)), with: .color(.black.opacity(0.3)))
        }
        drawEye(hg, CGPoint(x: 0, y: -5), p.eyes, eyelid: bodyC)
        if d.mood == .angry {
            var brow = Path()
            brow.move(to: CGPoint(x: -5, y: -12))
            brow.addLine(to: CGPoint(x: 4, y: -9))
            hg.stroke(brow, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        drawHeadSymptoms(&hg, t: t, d: d, mouthLocal: CGPoint(x: 26, y: -2))
        return HeadInfo(center: CGPoint(x: 30, y: -27), radius: 17, mouthTip: CGPoint(x: 56, y: -29))
    }
}
