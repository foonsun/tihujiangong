import SwiftUI
import Foundation

extension PelicanArt {
    static func drawTigerBody(_ c: inout GraphicsContext, t: Double, d: PelicanDraw,
                              p: Pose, walkPhase: Double) -> HeadInfo {
        let bed = d.hpState == .bedridden
        let outline = Color(red: 0.75, green: 0.45, blue: 0.18)
        let bodyC = Color(red: 0.96, green: 0.62, blue: 0.25)
        let stripeC = Color(red: 0.25, green: 0.20, blue: 0.18)

        // 大尾巴（末端深色环）
        var tg = c
        tg.translateBy(x: -30, y: -10)
        tg.rotate(by: .degrees(p.swing2 * 1.0))
        var tail = Path()
        tail.move(to: .zero)
        tail.addQuadCurve(to: CGPoint(x: -16, y: -14), control: CGPoint(x: -18, y: 2))
        tail.addQuadCurve(to: CGPoint(x: -20, y: 4), control: CGPoint(x: -10, y: -20))
        tg.stroke(tail, with: .color(bodyC), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
        var ring = Path()
        ring.move(to: CGPoint(x: -16.5, y: -8))
        ring.addLine(to: CGPoint(x: -19, y: 2))
        tg.stroke(ring, with: .color(stripeC), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
        // 身体
        let bb = c
        let bodyR = CGRect(x: -34, y: -22, width: 64, height: 50)
        bb.fill(Path(ellipseIn: bodyR), with: .color(bodyC))
        bb.stroke(Path(ellipseIn: bodyR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = bodyTint(d) { bb.fill(Path(ellipseIn: bodyR), with: .color(col.opacity(a))) }
        // 白肚皮
        c.fill(Path(ellipseIn: CGRect(x: -18, y: -6, width: 34, height: 28)),
               with: .color(Color(red: 0.99, green: 0.97, blue: 0.92)))
        // 背纹（5 道，更粗更弯）
        for sx in [-26.0, -17.0, -8.0, 1.0, 10.0] {
            var s = Path()
            s.move(to: CGPoint(x: sx, y: -19))
            s.addQuadCurve(to: CGPoint(x: sx + 6, y: -4), control: CGPoint(x: sx + 8, y: -13))
            c.stroke(s, with: .color(stripeC), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        }
        // 腿
        if !bed {
            drawLeg(c, hip: CGPoint(x: -14, y: 18), angle: -sin(walkPhase) * p.swing, color: bodyC, length: 12, width: 5.5)
            drawLeg(c, hip: CGPoint(x: 14, y: 18), angle: sin(walkPhase) * p.swing, color: bodyC, length: 12, width: 5.5)
            drawLeg(c, hip: CGPoint(x: -6, y: 21), angle: sin(walkPhase) * p.swing, color: bodyC, length: 12, width: 5.5)
            drawLeg(c, hip: CGPoint(x: 8, y: 21), angle: -sin(walkPhase) * p.swing, color: bodyC, length: 12, width: 5.5)
        }
        // 头
        var hg = c
        hg.translateBy(x: 30, y: -27)
        hg.rotate(by: Angle(radians: p.headTilt))
        // 圆耳 + 深色耳内
        hg.fill(Path(ellipseIn: CGRect(x: -16, y: -19, width: 11, height: 11)), with: .color(bodyC))
        hg.stroke(Path(ellipseIn: CGRect(x: -16, y: -19, width: 11, height: 11)), with: .color(outline), lineWidth: 1.3)
        hg.fill(Path(ellipseIn: CGRect(x: -13, y: -16, width: 5, height: 5)), with: .color(Color(red: 0.55, green: 0.35, blue: 0.2)))
        hg.fill(Path(ellipseIn: CGRect(x: 6, y: -20, width: 11, height: 11)), with: .color(bodyC))
        hg.stroke(Path(ellipseIn: CGRect(x: 6, y: -20, width: 11, height: 11)), with: .color(outline), lineWidth: 1.3)
        hg.fill(Path(ellipseIn: CGRect(x: 9, y: -17, width: 5, height: 5)), with: .color(Color(red: 0.55, green: 0.35, blue: 0.2)))
        let headR = CGRect(x: -17, y: -15, width: 34, height: 30)
        hg.fill(Path(ellipseIn: headR), with: .color(bodyC))
        hg.stroke(Path(ellipseIn: headR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = headTint(d) { hg.fill(Path(ellipseIn: headR), with: .color(col.opacity(a))) }
        // 额纹（王字纹）
        for sx in [-8.0, -2.0, 4.0] {
            var s = Path()
            s.move(to: CGPoint(x: sx, y: -14))
            s.addLine(to: CGPoint(x: sx, y: -8))
            hg.stroke(s, with: .color(stripeC), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        }
        var kingBar = Path()
        kingBar.move(to: CGPoint(x: -9, y: -11))
        kingBar.addLine(to: CGPoint(x: 5, y: -11))
        hg.stroke(kingBar, with: .color(stripeC), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        // 白眼圈（虎眼标志性浅纹，包住眼睛）
        hg.fill(Path(ellipseIn: CGRect(x: -7, y: -9, width: 14, height: 8)),
                with: .color(Color(red: 0.99, green: 0.97, blue: 0.92).opacity(0.9)))
        // 白吻 + 粉鼻 + 嘴
        hg.fill(Path(ellipseIn: CGRect(x: 4, y: -6, width: 18, height: 13)),
                with: .color(Color(red: 0.99, green: 0.97, blue: 0.92)))
        hg.fill(Path(ellipseIn: CGRect(x: 14, y: -4.5, width: 7, height: 5)), with: .color(nosePink))
        var mouth = Path()
        mouth.move(to: CGPoint(x: 17.5, y: 0.5))
        mouth.addQuadCurve(to: CGPoint(x: 13, y: 4.5), control: CGPoint(x: 17.5, y: 3.2))
        mouth.addQuadCurve(to: CGPoint(x: 22, y: 4.5), control: CGPoint(x: 17.5, y: 3.2))
        hg.stroke(mouth, with: .color(.black.opacity(0.35)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        if p.mouthOpen {
            hg.fill(Path(ellipseIn: CGRect(x: 14.5, y: 1, width: 6, height: 4.5)), with: .color(.black.opacity(0.3)))
        }
        drawEye(hg, CGPoint(x: 0, y: -5), p.eyes, eyelid: bodyC)
        if d.mood == .angry {
            var brow = Path()
            brow.move(to: CGPoint(x: -5, y: -12))
            brow.addLine(to: CGPoint(x: 4, y: -9))
            hg.stroke(brow, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        // 胡须
        for dy in [-3.0, 0.5] {
            var w = Path()
            w.move(to: CGPoint(x: 18, y: dy))
            w.addLine(to: CGPoint(x: 27, y: dy - 2))
            hg.stroke(w, with: .color(.black.opacity(0.25)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        }
        drawHeadSymptoms(&hg, t: t, d: d, mouthLocal: CGPoint(x: 21, y: -2))
        return HeadInfo(center: CGPoint(x: 30, y: -27), radius: 16, mouthTip: CGPoint(x: 51, y: -29))
    }
}
