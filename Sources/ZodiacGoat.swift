import SwiftUI
import Foundation

extension PelicanArt {
    static func drawGoatBody(_ c: inout GraphicsContext, t: Double, d: PelicanDraw,
                             p: Pose, walkPhase: Double) -> HeadInfo {
        let bed = d.hpState == .bedridden
        let outline = Color(red: 0.80, green: 0.75, blue: 0.66)
        let bodyC = Color(red: 0.95, green: 0.92, blue: 0.85)
        let faceC = Color(red: 0.90, green: 0.85, blue: 0.74)
        let hornC = Color(red: 0.85, green: 0.78, blue: 0.62)
        let legC = Color(red: 0.80, green: 0.70, blue: 0.55)

        // 蓬松羊毛（身体上缘一排小圆，更蓬松）
        c.fill(Path(ellipseIn: CGRect(x: -34, y: -22, width: 18, height: 16)), with: .color(bodyC))
        c.fill(Path(ellipseIn: CGRect(x: -24, y: -27, width: 17, height: 16)), with: .color(bodyC))
        c.fill(Path(ellipseIn: CGRect(x: -12, y: -29, width: 17, height: 17)), with: .color(bodyC))
        c.fill(Path(ellipseIn: CGRect(x: 0, y: -28, width: 17, height: 16)), with: .color(bodyC))
        c.fill(Path(ellipseIn: CGRect(x: 12, y: -24, width: 16, height: 14)), with: .color(bodyC))
        // 主身体
        let bb = c
        let bodyR = CGRect(x: -34, y: -20, width: 64, height: 50)
        bb.fill(Path(ellipseIn: bodyR), with: .color(bodyC))
        bb.stroke(Path(ellipseIn: bodyR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = bodyTint(d) { bb.fill(Path(ellipseIn: bodyR), with: .color(col.opacity(a))) }
        // 绒球尾
        var tg = c
        tg.translateBy(x: -36, y: -8)
        tg.rotate(by: .degrees(p.swing2 * 0.3))
        tg.fill(Path(ellipseIn: CGRect(x: -4, y: -4, width: 10, height: 10)), with: .color(bodyC))
        tg.stroke(Path(ellipseIn: CGRect(x: -4, y: -4, width: 10, height: 10)), with: .color(outline), lineWidth: 1.2)
        // 腿
        if !bed {
            drawLeg(c, hip: CGPoint(x: -14, y: 18), angle: -sin(walkPhase) * p.swing, color: legC, length: 12, width: 5)
            drawLeg(c, hip: CGPoint(x: 12, y: 18), angle: sin(walkPhase) * p.swing, color: legC, length: 12, width: 5)
            drawLeg(c, hip: CGPoint(x: -6, y: 21), angle: sin(walkPhase) * p.swing, color: legC, length: 12, width: 5)
            drawLeg(c, hip: CGPoint(x: 6, y: 21), angle: -sin(walkPhase) * p.swing, color: legC, length: 12, width: 5)
        }
        // 头
        var hg = c
        hg.translateBy(x: 30, y: -27)
        hg.rotate(by: Angle(radians: p.headTilt))
        // 弯角（画在头前）
        var hornL = Path()
        hornL.move(to: CGPoint(x: -11, y: -11))
        hornL.addQuadCurve(to: CGPoint(x: -23, y: -16), control: CGPoint(x: -20, y: -21))
        hg.stroke(hornL, with: .color(hornC), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
        var hornR = Path()
        hornR.move(to: CGPoint(x: 8, y: -13))
        hornR.addQuadCurve(to: CGPoint(x: 1, y: -27), control: CGPoint(x: 10, y: -24))
        hg.stroke(hornR, with: .color(hornC), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
        // 垂耳（画在头前）
        var earL = hg
        earL.translateBy(x: -13, y: -4)
        earL.rotate(by: .degrees(-30))
        earL.fill(Path(ellipseIn: CGRect(x: -9, y: -3, width: 12, height: 7)), with: .color(faceC))
        earL.stroke(Path(ellipseIn: CGRect(x: -9, y: -3, width: 12, height: 7)), with: .color(outline), lineWidth: 1.2)
        var earR = hg
        earR.translateBy(x: 11, y: -5)
        earR.rotate(by: .degrees(30))
        earR.fill(Path(ellipseIn: CGRect(x: -3, y: -3, width: 12, height: 7)), with: .color(faceC))
        earR.stroke(Path(ellipseIn: CGRect(x: -3, y: -3, width: 12, height: 7)), with: .color(outline), lineWidth: 1.2)
        let headR = CGRect(x: -16, y: -14, width: 32, height: 29)
        hg.fill(Path(ellipseIn: headR), with: .color(faceC))
        hg.stroke(Path(ellipseIn: headR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = headTint(d) { hg.fill(Path(ellipseIn: headR), with: .color(col.opacity(a))) }
        // 山羊胡（两瓣胡须）
        hg.fill(Path(ellipseIn: CGRect(x: 9, y: 10, width: 6, height: 9)), with: .color(bodyC))
        hg.fill(Path(ellipseIn: CGRect(x: 13, y: 12, width: 5, height: 7)), with: .color(bodyC))
        // 鼻 + 嘴
        hg.fill(Path(ellipseIn: CGRect(x: 14, y: -3, width: 6, height: 4.5)), with: .color(nosePink))
        var mouth = Path()
        mouth.move(to: CGPoint(x: 16.5, y: 2))
        mouth.addQuadCurve(to: CGPoint(x: 12, y: 6), control: CGPoint(x: 16.5, y: 4.5))
        mouth.addQuadCurve(to: CGPoint(x: 21, y: 6), control: CGPoint(x: 16.5, y: 4.5))
        hg.stroke(mouth, with: .color(.black.opacity(0.35)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        if p.mouthOpen {
            hg.fill(Path(ellipseIn: CGRect(x: 13.5, y: 2.5, width: 6, height: 4)), with: .color(.black.opacity(0.3)))
        }
        drawEye(hg, CGPoint(x: 1, y: -5), p.eyes, eyelid: faceC)
        if d.mood == .angry {
            var brow = Path()
            brow.move(to: CGPoint(x: -4, y: -12))
            brow.addLine(to: CGPoint(x: 5, y: -9))
            hg.stroke(brow, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        drawHeadSymptoms(&hg, t: t, d: d, mouthLocal: CGPoint(x: 20, y: -1))
        return HeadInfo(center: CGPoint(x: 30, y: -27), radius: 16, mouthTip: CGPoint(x: 50, y: -28))
    }
}
