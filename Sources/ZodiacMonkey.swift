import SwiftUI
import Foundation

extension PelicanArt {
    static func drawMonkeyBody(_ c: inout GraphicsContext, t: Double, d: PelicanDraw,
                               p: Pose, walkPhase: Double) -> HeadInfo {
        let bed = d.hpState == .bedridden
        let outline = Color(red: 0.62, green: 0.45, blue: 0.28)
        let bodyC = Color(red: 0.82, green: 0.62, blue: 0.42)
        let faceC = Color(red: 0.93, green: 0.85, blue: 0.72)

        // 长卷尾
        var tg = c
        tg.translateBy(x: -30, y: 8)
        tg.rotate(by: .degrees(p.swing2 * 0.8))
        var tail = Path()
        tail.move(to: .zero)
        tail.addQuadCurve(to: CGPoint(x: -13, y: -9), control: CGPoint(x: -19, y: 9))
        tail.addQuadCurve(to: CGPoint(x: -3, y: -1), control: CGPoint(x: 2, y: -16))
        tail.addQuadCurve(to: CGPoint(x: -9, y: -6), control: CGPoint(x: -14, y: -14))
        tg.stroke(tail, with: .color(bodyC), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        // 身体
        let bb = c
        let bodyR = CGRect(x: -34, y: -20, width: 64, height: 48)
        bb.fill(Path(ellipseIn: bodyR), with: .color(bodyC))
        bb.stroke(Path(ellipseIn: bodyR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = bodyTint(d) { bb.fill(Path(ellipseIn: bodyR), with: .color(col.opacity(a))) }
        // 浅色肚皮
        c.fill(Path(ellipseIn: CGRect(x: -16, y: -8, width: 30, height: 28)), with: .color(faceC))
        // 腿
        if !bed {
            drawLeg(c, hip: CGPoint(x: -12, y: 18), angle: -sin(walkPhase) * p.swing, color: bodyC, length: 12, width: 5)
            drawLeg(c, hip: CGPoint(x: 10, y: 18), angle: sin(walkPhase) * p.swing, color: bodyC, length: 12, width: 5)
        }
        // 头
        var hg = c
        hg.translateBy(x: 30, y: -27)
        hg.rotate(by: Angle(radians: p.headTilt))
        // 大圆耳（画在头前，露在外面）
        hg.fill(Path(ellipseIn: CGRect(x: -20, y: -8, width: 12, height: 12)), with: .color(bodyC))
        hg.stroke(Path(ellipseIn: CGRect(x: -20, y: -8, width: 12, height: 12)), with: .color(outline), lineWidth: 1.3)
        hg.fill(Path(ellipseIn: CGRect(x: -17, y: -5, width: 6, height: 6)), with: .color(earInner))
        hg.fill(Path(ellipseIn: CGRect(x: 8, y: -12, width: 12, height: 12)), with: .color(bodyC))
        hg.stroke(Path(ellipseIn: CGRect(x: 8, y: -12, width: 12, height: 12)), with: .color(outline), lineWidth: 1.3)
        hg.fill(Path(ellipseIn: CGRect(x: 11, y: -9, width: 6, height: 6)), with: .color(earInner))
        let headR = CGRect(x: -16, y: -15, width: 33, height: 30)
        hg.fill(Path(ellipseIn: headR), with: .color(bodyC))
        hg.stroke(Path(ellipseIn: headR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = headTint(d) { hg.fill(Path(ellipseIn: headR), with: .color(col.opacity(a))) }
        // 毛帽（头顶深色毛发，露出脸盘边缘）
        hg.fill(Path(ellipseIn: CGRect(x: -16, y: -15, width: 33, height: 15)),
                with: .color(Color(red: 0.70, green: 0.50, blue: 0.32)))
        // 浅色脸盘
        hg.fill(Path(ellipseIn: CGRect(x: -8, y: -10, width: 26, height: 22)), with: .color(faceC))
        // 呆毛
        var tuft = Path()
        tuft.move(to: CGPoint(x: -2, y: -15))
        tuft.addQuadCurve(to: CGPoint(x: 2, y: -21), control: CGPoint(x: -4, y: -20))
        hg.stroke(tuft, with: .color(outline), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        drawEye(hg, CGPoint(x: 0, y: -4), p.eyes, eyelid: faceC)
        if d.mood == .angry {
            var brow = Path()
            brow.move(to: CGPoint(x: -5, y: -11))
            brow.addLine(to: CGPoint(x: 4, y: -8))
            hg.stroke(brow, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        // 鼻点 + 笑嘴
        hg.fill(Path(ellipseIn: CGRect(x: 10, y: -2, width: 2.5, height: 2)), with: .color(Color(red: 0.75, green: 0.55, blue: 0.5)))
        hg.fill(Path(ellipseIn: CGRect(x: 14, y: -2, width: 2.5, height: 2)), with: .color(Color(red: 0.75, green: 0.55, blue: 0.5)))
        var mouth = Path()
        mouth.move(to: CGPoint(x: 9, y: 3))
        mouth.addQuadCurve(to: CGPoint(x: 16, y: 4), control: CGPoint(x: 12.5, y: 6.5))
        hg.stroke(mouth, with: .color(.black.opacity(0.4)), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
        if p.mouthOpen {
            hg.fill(Path(ellipseIn: CGRect(x: 10, y: 1.5, width: 7, height: 5)), with: .color(.black.opacity(0.3)))
        }
        drawHeadSymptoms(&hg, t: t, d: d, mouthLocal: CGPoint(x: 16, y: 4))
        return HeadInfo(center: CGPoint(x: 30, y: -27), radius: 16, mouthTip: CGPoint(x: 46, y: -23))
    }
}
