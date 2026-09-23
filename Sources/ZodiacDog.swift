import SwiftUI
import Foundation

extension PelicanArt {
    static func drawDogBody(_ c: inout GraphicsContext, t: Double, d: PelicanDraw,
                            p: Pose, walkPhase: Double) -> HeadInfo {
        let bed = d.hpState == .bedridden
        let outline = Color(red: 0.62, green: 0.44, blue: 0.26)
        let bodyC = Color(red: 0.85, green: 0.63, blue: 0.40)
        let earC = Color(red: 0.65, green: 0.45, blue: 0.27)
        let muzzleC = Color(red: 0.95, green: 0.86, blue: 0.70)

        // 大尾巴（明显摇摆）
        var tg = c
        tg.translateBy(x: -28, y: -10)
        tg.rotate(by: .degrees(p.swing2 * 1.2))
        var tail = Path()
        tail.move(to: .zero)
        tail.addQuadCurve(to: CGPoint(x: -12, y: -14), control: CGPoint(x: -14, y: 2))
        tail.addQuadCurve(to: CGPoint(x: -16, y: -22), control: CGPoint(x: -4, y: -16))
        tg.stroke(tail, with: .color(bodyC), style: StrokeStyle(lineWidth: 5.5, lineCap: .round))
        // 身体
        let bb = c
        let bodyR = CGRect(x: -34, y: -20, width: 66, height: 48)
        bb.fill(Path(ellipseIn: bodyR), with: .color(bodyC))
        bb.stroke(Path(ellipseIn: bodyR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = bodyTint(d) { bb.fill(Path(ellipseIn: bodyR), with: .color(col.opacity(a))) }
        // 胸口浅斑
        c.fill(Path(ellipseIn: CGRect(x: 2, y: -8, width: 24, height: 28)), with: .color(muzzleC))
        // 红项圈 + 金吊牌
        c.fill(Path(roundedRect: CGRect(x: 10, y: -18, width: 16, height: 5), cornerRadius: 2.5), with: .color(red))
        c.fill(Path(ellipseIn: CGRect(x: 16, y: -14, width: 5, height: 5)),
               with: .color(Color(red: 0.98, green: 0.83, blue: 0.40)))
        // 腿（前浅后深）
        if !bed {
            drawLeg(c, hip: CGPoint(x: -16, y: 16), angle: -sin(walkPhase) * p.swing, color: Color(red: 0.75, green: 0.55, blue: 0.34), length: 13, width: 5)
            drawLeg(c, hip: CGPoint(x: 16, y: 16), angle: sin(walkPhase) * p.swing, color: Color(red: 0.75, green: 0.55, blue: 0.34), length: 13, width: 5)
            drawLeg(c, hip: CGPoint(x: -8, y: 20), angle: sin(walkPhase) * p.swing, color: bodyC, length: 13, width: 5)
            drawLeg(c, hip: CGPoint(x: 8, y: 20), angle: -sin(walkPhase) * p.swing, color: bodyC, length: 13, width: 5)
        }
        // 头
        var hg = c
        hg.translateBy(x: 30, y: -27)
        hg.rotate(by: Angle(radians: p.headTilt))
        let headR = CGRect(x: -17, y: -15, width: 34, height: 30)
        hg.fill(Path(ellipseIn: headR), with: .color(bodyC))
        hg.stroke(Path(ellipseIn: headR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = headTint(d) { hg.fill(Path(ellipseIn: headR), with: .color(col.opacity(a))) }
        // 垂耳（画在头后，盖住头边缘）
        var earL = hg
        earL.translateBy(x: -15, y: -5)
        earL.rotate(by: .degrees(18))
        earL.fill(Path(ellipseIn: CGRect(x: -5.5, y: -9, width: 11, height: 25)), with: .color(earC))
        earL.stroke(Path(ellipseIn: CGRect(x: -5.5, y: -9, width: 11, height: 25)), with: .color(outline), lineWidth: 1.2)
        var earR = hg
        earR.translateBy(x: 15, y: -5)
        earR.rotate(by: .degrees(-18))
        earR.fill(Path(ellipseIn: CGRect(x: -5.5, y: -9, width: 11, height: 25)), with: .color(earC))
        earR.stroke(Path(ellipseIn: CGRect(x: -5.5, y: -9, width: 11, height: 25)), with: .color(outline), lineWidth: 1.2)
        // 吻部 + 黑鼻 + 嘴
        hg.fill(Path(ellipseIn: CGRect(x: 6, y: -6, width: 20, height: 14)), with: .color(muzzleC))
        hg.fill(Path(ellipseIn: CGRect(x: 17, y: -4, width: 7, height: 5.5)), with: .color(.black.opacity(0.85)))
        var mouth = Path()
        mouth.move(to: CGPoint(x: 20, y: 1.5))
        mouth.addQuadCurve(to: CGPoint(x: 14, y: 5), control: CGPoint(x: 19, y: 4.5))
        hg.stroke(mouth, with: .color(.black.opacity(0.4)), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
        if p.mouthOpen || d.mood == .happy {
            hg.fill(Path(ellipseIn: CGRect(x: 16, y: 3, width: 6, height: 6)), with: .color(nosePink))
        }
        // 浅色眉点（狗狗的眉斑）
        hg.fill(Path(ellipseIn: CGRect(x: -3, y: -10, width: 6, height: 4)), with: .color(muzzleC))
        drawEye(hg, CGPoint(x: 0, y: -5), p.eyes, eyelid: bodyC)
        if d.mood == .angry {
            var brow = Path()
            brow.move(to: CGPoint(x: -5, y: -12))
            brow.addLine(to: CGPoint(x: 4, y: -9))
            hg.stroke(brow, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        drawHeadSymptoms(&hg, t: t, d: d, mouthLocal: CGPoint(x: 21, y: -2))
        return HeadInfo(center: CGPoint(x: 30, y: -27), radius: 17, mouthTip: CGPoint(x: 51, y: -29))
    }
}
