import SwiftUI
import Foundation

extension PelicanArt {
    static func drawPigBody(_ c: inout GraphicsContext, t: Double, d: PelicanDraw,
                            p: Pose, walkPhase: Double) -> HeadInfo {
        let bed = d.hpState == .bedridden
        let outline = Color(red: 0.88, green: 0.60, blue: 0.64)
        let bodyC = Color(red: 0.98, green: 0.72, blue: 0.75)
        let darkPink = Color(red: 0.85, green: 0.50, blue: 0.55)

        // 卷尾巴
        var tg = c
        tg.translateBy(x: -36, y: 2)
        tg.rotate(by: .degrees(p.swing2 * 0.5))
        var curl = Path()
        curl.move(to: .zero)
        curl.addQuadCurve(to: CGPoint(x: -6, y: -6), control: CGPoint(x: -8, y: 4))
        curl.addQuadCurve(to: CGPoint(x: 2, y: -6), control: CGPoint(x: 2, y: -12))
        curl.addQuadCurve(to: CGPoint(x: 3, y: 0), control: CGPoint(x: -1, y: -8))
        tg.stroke(curl, with: .color(darkPink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        // 超圆身体
        let bb = c
        let bodyR = CGRect(x: -34, y: -20, width: 62, height: 50)
        bb.fill(Path(ellipseIn: bodyR), with: .color(bodyC))
        bb.stroke(Path(ellipseIn: bodyR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = bodyTint(d) { bb.fill(Path(ellipseIn: bodyR), with: .color(col.opacity(a))) }
        // 浅粉肚皮
        c.fill(Path(ellipseIn: CGRect(x: -16, y: -4, width: 30, height: 28)),
               with: .color(Color(red: 1.0, green: 0.82, blue: 0.84)))
        // 短腿
        if !bed {
            drawLeg(c, hip: CGPoint(x: -14, y: 16), angle: -sin(walkPhase) * p.swing, color: bodyC, length: 11, width: 5)
            drawLeg(c, hip: CGPoint(x: 12, y: 16), angle: sin(walkPhase) * p.swing, color: bodyC, length: 11, width: 5)
            drawLeg(c, hip: CGPoint(x: -6, y: 19), angle: sin(walkPhase) * p.swing, color: bodyC, length: 11, width: 5)
            drawLeg(c, hip: CGPoint(x: 6, y: 19), angle: -sin(walkPhase) * p.swing, color: bodyC, length: 11, width: 5)
        }
        // 头
        var hg = c
        hg.translateBy(x: 30, y: -27)
        hg.rotate(by: Angle(radians: p.headTilt))
        // 折耳（画在头前）
        var earL = Path()
        earL.move(to: CGPoint(x: -12, y: -10))
        earL.addLine(to: CGPoint(x: -16, y: -22))
        earL.addLine(to: CGPoint(x: -4, y: -14))
        earL.closeSubpath()
        hg.fill(earL, with: .color(Color(red: 0.93, green: 0.58, blue: 0.62)))
        hg.stroke(earL, with: .color(outline), lineWidth: 1.2)
        var earR = Path()
        earR.move(to: CGPoint(x: 4, y: -12))
        earR.addLine(to: CGPoint(x: 6, y: -25))
        earR.addLine(to: CGPoint(x: 12, y: -13))
        earR.closeSubpath()
        hg.fill(earR, with: .color(Color(red: 0.93, green: 0.58, blue: 0.62)))
        hg.stroke(earR, with: .color(outline), lineWidth: 1.2)
        let headR = CGRect(x: -16, y: -14, width: 33, height: 29)
        hg.fill(Path(ellipseIn: headR), with: .color(bodyC))
        hg.stroke(Path(ellipseIn: headR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = headTint(d) { hg.fill(Path(ellipseIn: headR), with: .color(col.opacity(a))) }
        // 腮红
        hg.fill(Path(ellipseIn: CGRect(x: -10, y: 0, width: 7, height: 5)),
                with: .color(Color(red: 1, green: 0.55, blue: 0.6).opacity(0.35)))
        // 猪鼻盘 + 鼻孔
        hg.fill(Path(ellipseIn: CGRect(x: 10, y: -6, width: 16, height: 11)),
                with: .color(Color(red: 1.0, green: 0.80, blue: 0.82)))
        hg.stroke(Path(ellipseIn: CGRect(x: 10, y: -6, width: 16, height: 11)), with: .color(outline), lineWidth: 1.2)
        hg.fill(Path(ellipseIn: CGRect(x: 15, y: -3.5, width: 3, height: 4)), with: .color(darkPink))
        hg.fill(Path(ellipseIn: CGRect(x: 20, y: -3.5, width: 3, height: 4)), with: .color(darkPink))
        // 嘴
        var mouth = Path()
        mouth.move(to: CGPoint(x: 17, y: 6))
        mouth.addQuadCurve(to: CGPoint(x: 12, y: 9), control: CGPoint(x: 16.5, y: 8.5))
        mouth.addQuadCurve(to: CGPoint(x: 22, y: 9), control: CGPoint(x: 17.5, y: 8.5))
        hg.stroke(mouth, with: .color(.black.opacity(0.35)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        if p.mouthOpen {
            hg.fill(Path(ellipseIn: CGRect(x: 14, y: 5.5, width: 6, height: 4)), with: .color(.black.opacity(0.3)))
        }
        drawEye(hg, CGPoint(x: 1, y: -5), p.eyes, eyelid: bodyC)
        if d.mood == .angry {
            var brow = Path()
            brow.move(to: CGPoint(x: -4, y: -12))
            brow.addLine(to: CGPoint(x: 5, y: -9))
            hg.stroke(brow, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        drawHeadSymptoms(&hg, t: t, d: d, mouthLocal: CGPoint(x: 26, y: -1))
        return HeadInfo(center: CGPoint(x: 30, y: -27), radius: 16, mouthTip: CGPoint(x: 56, y: -28))
    }
}
