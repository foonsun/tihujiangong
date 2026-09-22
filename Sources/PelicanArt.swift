import SwiftUI
import Foundation

// MARK: - 绘制参数

struct PelicanDraw {
    enum Pose { case standing, resting, walkingOut, walkingIn }
    var hpState: HPState
    var mood: Mood
    var pose: Pose
    var symptoms: [Symptom] = []
    var showBandage: Bool = false
    var away: Bool = false
    /// 走屏动画起点（timeIntervalSinceReferenceDate，已含 0.28s 窗口展开延迟）
    var walkT0: Double = 0
    /// 走屏起点（屏幕坐标 x）
    var walkFromX: Double = 0
    /// 当前窗口在屏幕上的 origin.x（走屏时用于把屏幕坐标换算回窗口坐标）
    var windowOriginX: Double = 0
}

enum EyeStyle { case open(CGFloat), blink, half, x, happyArc }

// MARK: - 鹈鹕（贴纸风：白身、橙嘴+喉囊、橙腿；局部坐标 = 身体中心，+x 朝右，+y 向下）

enum PelicanArt {

    // MARK: 配色（与 pelican-ride.html 一致）
    static let ink        = Color(red: 0.13, green: 0.15, blue: 0.17)
    static let bodyLine   = Color(red: 0.83, green: 0.88, blue: 0.91)
    static let belly      = Color(red: 0.93, green: 0.95, blue: 0.97)
    static let wingFill   = Color(red: 0.97, green: 0.985, blue: 0.995)
    static let wingLine   = Color(red: 0.86, green: 0.91, blue: 0.935)
    static let beak       = Color(red: 0.976, green: 0.659, blue: 0.145)   // #f9a825
    static let pouch      = Color(red: 0.976, green: 0.698, blue: 0.204)   // #f9b234
    static let legNear    = Color(red: 0.88, green: 0.54, blue: 0.00)      // #e08a00
    static let legFar     = Color(red: 0.97, green: 0.72, blue: 0.29)      // #f7b84a
    static let blanket    = Color(red: 1.00, green: 0.70, blue: 0.78)
    static let blanketLt  = Color(red: 1.00, green: 0.84, blue: 0.88)
    static let sweat      = Color(red: 0.75, green: 0.89, blue: 1.00)
    static let mucus      = Color(red: 0.65, green: 0.85, blue: 1.00)
    static let sickTint   = Color(red: 0.53, green: 0.78, blue: 0.36)
    static let angryTint  = Color(red: 1.00, green: 0.42, blue: 0.42)
    static let blush      = Color(red: 1.00, green: 0.62, blue: 0.69)
    static let red        = Color(red: 1.00, green: 0.36, blue: 0.36)
    static let gold       = Color(red: 1.00, green: 0.84, blue: 0.37)
    static let mouth      = Color(red: 0.55, green: 0.30, blue: 0.12)

    // MARK: 入口

    static func draw(_ ctx: inout GraphicsContext, size: CGSize, t: Double, d: PelicanDraw) {
        switch d.pose {
        case .standing:
            drawPelican(&ctx, t: t, d: d,
                        anchor: CGPoint(x: size.width / 2 - 8, y: size.height - 58),
                        scale: 1.0, walkPhase: 0)
        case .resting:
            drawRestingScene(&ctx, size: size, t: t, d: d)
        case .walkingOut, .walkingIn:
            drawStrip(&ctx, t: t, d: d)
        }
    }

    /// 全宽走屏：鹈鹕从窗口角落走向屏外（或走回来）
    static func drawStrip(_ ctx: inout GraphicsContext, t: Double, d: PelicanDraw) {
        let dur = 1.5
        let p = min(1, max(0, (t - d.walkT0) / dur))
        let e = p * p * (3 - 2 * p)   // smoothstep
        let off: Double = -140
        let screenX: Double
        if d.pose == .walkingOut {
            screenX = d.walkFromX + (off - d.walkFromX) * e
        } else {
            screenX = off + (d.walkFromX - off) * e
        }
        let xDraw = screenX - d.windowOriginX
        drawPelican(&ctx, t: t, d: d,
                    anchor: CGPoint(x: xDraw, y: 102),
                    scale: 1.2, walkPhase: t * 11)
    }

    /// 休息中的小场景：小鹈鹕原地溜达，灌木往左滚
    static func drawRestingScene(_ ctx: inout GraphicsContext, size: CGSize, t: Double, d: PelicanDraw) {
        let groundY = size.height - 16
        ctx.fill(Path(roundedRect: CGRect(x: 10, y: groundY, width: size.width - 20, height: 3), cornerRadius: 1.5),
                 with: .color(Color(red: 0.84, green: 0.91, blue: 0.83)))
        let span = Double(size.width) + 120
        for i in 0..<3 {
            let x = Double(size.width) + 60 - fmod(t * 90 + Double(i) * 95, span) - 60
            ctx.fill(Path(ellipseIn: CGRect(x: x - 7, y: groundY - 11, width: 14, height: 12)),
                     with: .color(Color(red: 0.44, green: 0.72, blue: 0.37)))
            ctx.fill(Path(ellipseIn: CGRect(x: x + 2, y: groundY - 8, width: 11, height: 9)),
                     with: .color(Color(red: 0.49, green: 0.75, blue: 0.38)))
        }
        var d2 = d
        d2.pose = .standing
        // 脚（anchor + 26*0.52）正好落在 groundY
        drawPelican(&ctx, t: t, d: d2,
                    anchor: CGPoint(x: size.width / 2, y: groundY - 13.5),
                    scale: 0.52, walkPhase: t * 10)
    }

    // MARK: 主体

    static func drawPelican(_ ctx: inout GraphicsContext, t: Double, d: PelicanDraw,
                            anchor: CGPoint, scale: CGFloat, walkPhase: Double) {
        let bed = d.hpState == .bedridden
        let walking = walkPhase != 0

        // ---- 姿态参数
        var yOff: Double = 0
        var bodyRot: Double = 0
        var headTilt: Double = 0
        var wingRot: Double = 0
        var eyes: EyeStyle = .open(3)
        var beakOpen = false

        switch d.hpState {
        case .energetic:
            yOff = -5 * abs(sin(t * 3.1))
            wingRot = sin(t * 6.2) * 22 - 8
            eyes = .open(3.4)
            beakOpen = true
        case .normal:
            yOff = -2 * sin(t * 1.7)
            wingRot = sin(t * 1.7) * 7
        case .wilted:
            yOff = 3
            bodyRot = 7
            headTilt = 0.38
            wingRot = 28
            eyes = .half
        case .sick:
            yOff = 1.5
            headTilt = 0.12
            wingRot = 18
            eyes = .half
        case .bedridden:
            headTilt = 0.22
            eyes = .x
        }
        if d.mood == .happy && !bed {
            yOff = -4 * abs(sin(t * 4.2))
            wingRot = sin(t * 8) * 26 - 10
            eyes = .happyArc
            beakOpen = true
        }
        if d.mood == .angry && !bed {
            headTilt -= 0.16
        }
        if walking {
            yOff = -3 * abs(sin(walkPhase))
            headTilt -= 0.05
            wingRot = sin(walkPhase * 2) * 12
        }
        // 眨眼（只对圆眼）
        if case .open = eyes, fmod(t + 0.9, 3.6) < 0.13 {
            eyes = .blink
        }
        let shiver = (d.symptoms.contains(.shiver) && !bed) ? sin(t * 42) * 1.3 : 0.0

        // ---- 影子（不随身体旋转）
        let shW: CGFloat = bed ? 112 : 92
        let shY: CGFloat = bed ? 40 : 52
        ctx.fill(Path(ellipseIn: CGRect(x: anchor.x - shW / 2 * scale,
                                        y: anchor.y + shY * scale - 8,
                                        width: shW * scale, height: 16)),
                 with: .color(.black.opacity(bed ? 0.14 : 0.11)))

        var c = ctx
        c.translateBy(x: anchor.x + shiver, y: anchor.y + yOff)
        c.scaleBy(x: scale, y: scale)
        if bed { c.rotate(by: .degrees(115)) }

        let swing: Double = walking ? 0.5 : 0.0

        // 远腿
        if !bed {
            drawLeg(c, hip: CGPoint(x: -8, y: 22), angle: -sin(walkPhase) * swing, color: legFar)
        }

        // 尾巴
        var tail = Path()
        tail.move(to: CGPoint(x: -34, y: -6))
        tail.addLine(to: CGPoint(x: -52, y: 5))
        tail.addLine(to: CGPoint(x: -31, y: 9))
        tail.closeSubpath()
        c.fill(tail, with: .color(.white))
        c.stroke(tail, with: .color(bodyLine), lineWidth: 1.2)

        // 身体
        let bodyRect = CGRect(x: -40, y: -27, width: 80, height: 54)
        var bg = c
        bg.rotate(by: .degrees(bodyRot - 10))
        bg.fill(Path(ellipseIn: bodyRect), with: .color(.white))
        bg.stroke(Path(ellipseIn: bodyRect), with: .color(bodyLine), lineWidth: 1.5)

        // 肚皮
        var bl = c
        bl.rotate(by: .degrees(bodyRot))
        bl.fill(Path(ellipseIn: CGRect(x: -24, y: -2, width: 52, height: 26)), with: .color(belly))

        // 状态染色（生病绿 / 生气红）
        if d.hpState == .sick {
            var tg = c
            tg.rotate(by: .degrees(bodyRot - 10))
            tg.fill(Path(ellipseIn: bodyRect), with: .color(sickTint.opacity(0.30)))
        } else if d.mood == .angry && !bed {
            var tg = c
            tg.rotate(by: .degrees(bodyRot - 10))
            tg.fill(Path(ellipseIn: bodyRect), with: .color(angryTint.opacity(0.22)))
        }

        // 翅膀
        var wg = c
        wg.translateBy(x: -8, y: -4)
        wg.rotate(by: .degrees(wingRot))
        let wingRect = CGRect(x: -25, y: -13, width: 50, height: 26)
        wg.fill(Path(ellipseIn: wingRect), with: .color(wingFill))
        wg.stroke(Path(ellipseIn: wingRect), with: .color(wingLine), lineWidth: 1.5)

        // 近腿
        if !bed {
            drawLeg(c, hip: CGPoint(x: 6, y: 24), angle: sin(walkPhase) * swing, color: legNear)
        }

        // 脖子
        var neck = Path()
        neck.move(to: CGPoint(x: 22, y: -6))
        neck.addLine(to: CGPoint(x: 36, y: -26))
        c.stroke(neck, with: .color(.white), style: StrokeStyle(lineWidth: 13, lineCap: .round))

        // 头
        var hg = c
        hg.translateBy(x: 38, y: -30)
        hg.rotate(by: .radians(headTilt))
        drawHead(&hg, t: t, d: d, eyes: eyes, beakOpen: beakOpen)

        // ---- 身体局部特效
        let headAbs = CGPoint(x: 38, y: -30)

        if d.hpState == .energetic && d.mood == .none {
            let spots: [(Double, Double, Double)] = [(-40, -30, 4.5), (62, -46, 3.5), (30, 38, 3)]
            for (i, s) in spots.enumerated() {
                let a = (sin(t * 3.2 + Double(i) * 2.1) + 1) / 2 * 0.85
                sparkle(c, at: CGPoint(x: s.0, y: s.1), r: s.2, color: gold, alpha: a)
            }
        }
        if d.mood == .happy && !bed {
            for i in 0..<3 {
                let ph = fmod(t * 0.55 + Double(i) * 0.37, 1)
                heart(c, at: CGPoint(x: headAbs.x + 16 + Double(i) * 8, y: headAbs.y - 18 - ph * 26),
                      r: 7 - ph * 3, alpha: (1 - ph) * 0.9)
            }
        }
        if d.mood == .angry && !bed {
            angerMark(c, at: CGPoint(x: headAbs.x - 24, y: headAbs.y - 18))
            c.draw(Text("!!").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundColor(red),
                   at: CGPoint(x: headAbs.x + 30, y: headAbs.y - 18))
        }
        if d.away {
            c.draw(Text("？").font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.52, green: 0.60, blue: 0.68)),
                   at: CGPoint(x: headAbs.x + 8, y: headAbs.y - 20 + sin(t * 2) * 2.5))
        }
        if d.symptoms.contains(.dizzy) && !bed {
            for i in 0..<3 {
                let a = t * 2.4 + Double(i) * 2.094
                sparkle(c, at: CGPoint(x: headAbs.x + cos(a) * 27, y: headAbs.y + sin(a) * 13),
                        r: 4, color: gold, alpha: 0.85)
            }
        }
        if d.symptoms.contains(.cough) && !bed {
            for i in 0..<2 {
                let ph = fmod(t * 1.4 + Double(i) * 0.4, 1)
                let pp = CGPoint(x: headAbs.x + 58 + ph * 12, y: headAbs.y + 4 - ph * 8)
                c.fill(Path(ellipseIn: CGRect(x: pp.x - 3 - ph * 2, y: pp.y - 3 - ph * 2,
                                              width: 6 + ph * 4, height: 6 + ph * 4)),
                       with: .color(Color(red: 0.72, green: 0.78, blue: 0.84).opacity((1 - ph) * 0.7)))
            }
        }
        // 卧床：粉色毯子盖住下半身
        if bed {
            c.fill(Path(roundedRect: CGRect(x: -2, y: -40, width: 56, height: 76), cornerRadius: 14),
                   with: .color(blanket))
            for sx in [8.0, 22.0, 36.0] {
                c.fill(Path(roundedRect: CGRect(x: sx, y: -36, width: 7, height: 68), cornerRadius: 3.5),
                       with: .color(blanketLt.opacity(0.8)))
            }
        }
    }

    // MARK: 部件

    static func drawLeg(_ c: GraphicsContext, hip: CGPoint, angle: Double, color: Color) {
        let fx = hip.x + 26 * sin(angle)
        let fy = hip.y + 26 * cos(angle)
        var p = Path()
        p.move(to: hip)
        p.addLine(to: CGPoint(x: fx, y: fy))
        c.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        var g = c
        g.translateBy(x: fx, y: fy)
        g.rotate(by: .radians(angle * 0.5))
        g.fill(Path(ellipseIn: CGRect(x: -3, y: -4.5, width: 16, height: 9)), with: .color(color))
    }

    static func drawHead(_ hg: inout GraphicsContext, t: Double, d: PelicanDraw,
                         eyes: EyeStyle, beakOpen: Bool) {
        let headRect = CGRect(x: -15, y: -15, width: 30, height: 30)
        hg.fill(Path(ellipseIn: headRect), with: .color(.white))
        hg.stroke(Path(ellipseIn: headRect), with: .color(bodyLine), lineWidth: 1.5)
        if d.hpState == .sick {
            hg.fill(Path(ellipseIn: headRect), with: .color(sickTint.opacity(0.34)))
        } else if d.mood == .angry {
            hg.fill(Path(ellipseIn: headRect), with: .color(angryTint.opacity(0.28)))
        }

        // 张嘴时的嘴缝
        if beakOpen {
            var gap = Path()
            gap.move(to: CGPoint(x: 12, y: 1))
            gap.addLine(to: CGPoint(x: 56, y: 4))
            gap.addLine(to: CGPoint(x: 12, y: 8))
            gap.closeSubpath()
            hg.fill(gap, with: .color(mouth))
        }

        // 喉囊
        let pd: Double = beakOpen ? 4 : 0
        var pouchPath = Path()
        pouchPath.move(to: CGPoint(x: 12, y: -1 + pd))
        pouchPath.addCurve(to: CGPoint(x: 58, y: 2 + pd),
                           control1: CGPoint(x: 18, y: 27 + pd),
                           control2: CGPoint(x: 44, y: 31 + pd))
        pouchPath.addCurve(to: CGPoint(x: 12, y: -1 + pd),
                           control1: CGPoint(x: 40, y: 16 + pd),
                           control2: CGPoint(x: 24, y: 14 + pd))
        pouchPath.closeSubpath()
        hg.fill(pouchPath, with: .color(pouch))

        // 上喙
        var beakPath = Path()
        beakPath.move(to: CGPoint(x: 12, y: -5))
        beakPath.addLine(to: CGPoint(x: 58, y: 1))
        beakPath.addLine(to: CGPoint(x: 12, y: -1))
        beakPath.closeSubpath()
        hg.fill(beakPath, with: .color(beak))

        // 眼睛
        let e = CGPoint(x: 4, y: -6)
        switch eyes {
        case .open(let r):
            hg.fill(Path(ellipseIn: CGRect(x: e.x - r, y: e.y - r, width: 2 * r, height: 2 * r)),
                    with: .color(ink))
            hg.fill(Path(ellipseIn: CGRect(x: e.x - r + r * 0.35, y: e.y - r + r * 0.25,
                                           width: r * 0.55, height: r * 0.55)),
                    with: .color(.white))
        case .blink:
            var p = Path()
            p.move(to: CGPoint(x: e.x - 3.5, y: e.y))
            p.addLine(to: CGPoint(x: e.x + 3.5, y: e.y))
            hg.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        case .half:
            hg.fill(Path(ellipseIn: CGRect(x: e.x - 3, y: e.y - 3, width: 6, height: 6)), with: .color(ink))
            hg.fill(Path(CGRect(x: e.x - 4, y: e.y - 4.5, width: 8, height: 4.6)), with: .color(.white))
            var line = Path()
            line.move(to: CGPoint(x: e.x - 3.5, y: e.y))
            line.addLine(to: CGPoint(x: e.x + 3.5, y: e.y))
            hg.stroke(line, with: .color(ink), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        case .x:
            var p = Path()
            p.move(to: CGPoint(x: e.x - 3, y: e.y - 3)); p.addLine(to: CGPoint(x: e.x + 3, y: e.y + 3))
            p.move(to: CGPoint(x: e.x + 3, y: e.y - 3)); p.addLine(to: CGPoint(x: e.x - 3, y: e.y + 3))
            hg.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        case .happyArc:
            var p = Path()
            p.move(to: CGPoint(x: e.x - 3.2, y: e.y + 0.5))
            p.addQuadCurve(to: CGPoint(x: e.x + 3.2, y: e.y + 0.5),
                           control: CGPoint(x: e.x, y: e.y - 4.5))
            hg.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }

        // 生气眉
        if d.mood == .angry {
            var p = Path()
            p.move(to: CGPoint(x: e.x - 4, y: e.y - 6))
            p.addLine(to: CGPoint(x: e.x + 4.5, y: e.y - 3.5))
            hg.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }

        // 腮红
        if d.mood == .happy {
            hg.fill(Path(ellipseIn: CGRect(x: e.x - 2, y: e.y + 4, width: 8, height: 5)),
                    with: .color(blush.opacity(0.55)))
        }

        // 症状：体温计（从喙里伸出，红头朝外）
        if d.symptoms.contains(.thermometer) {
            var p = Path()
            p.move(to: CGPoint(x: 58, y: 0))
            p.addLine(to: CGPoint(x: 70, y: -8))
            hg.stroke(p, with: .color(.white), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            hg.fill(Path(ellipseIn: CGRect(x: 66, y: -10.5, width: 5, height: 5)), with: .color(red))
            hg.stroke(Path(ellipseIn: CGRect(x: 66, y: -10.5, width: 5, height: 5)),
                      with: .color(.white), lineWidth: 1)
        }
        // 生病：流鼻涕
        if d.hpState == .sick {
            let f = 0.75 + 0.25 * sin(t * 3.1)
            let bx = 16.0
            var drop = Path()
            drop.move(to: CGPoint(x: bx, y: 2))
            drop.addCurve(to: CGPoint(x: bx, y: 2 + 10 * f),
                          control1: CGPoint(x: bx + 2.6, y: 2 + 4 * f),
                          control2: CGPoint(x: bx + 2.6, y: 2 + 6.5 * f))
            drop.addCurve(to: CGPoint(x: bx, y: 2),
                          control1: CGPoint(x: bx - 2.6, y: 2 + 6.5 * f),
                          control2: CGPoint(x: bx - 2.6, y: 2 + 4 * f))
            drop.closeSubpath()
            hg.fill(drop, with: .color(mucus.opacity(0.92)))
        }
        // 蔫了：汗滴
        if d.hpState == .wilted {
            let wy = -12 + sin(t * 2.4) * 1.4
            var drop = Path()
            drop.move(to: CGPoint(x: -13, y: wy - 5))
            drop.addCurve(to: CGPoint(x: -13, y: wy + 4),
                          control1: CGPoint(x: -10.2, y: wy - 1),
                          control2: CGPoint(x: -10.6, y: wy + 2))
            drop.addCurve(to: CGPoint(x: -13, y: wy - 5),
                          control1: CGPoint(x: -15.4, y: wy + 2),
                          control2: CGPoint(x: -15.8, y: wy - 1))
            drop.closeSubpath()
            hg.fill(drop, with: .color(sweat.opacity(0.95)))
        }
        // 绷带（住院特效 / 症状）
        if d.showBandage || d.symptoms.contains(.bandage) {
            var g = hg
            g.translateBy(x: 5, y: -11)
            g.rotate(by: .degrees(-32))
            let bRect = CGRect(x: -9, y: -3.5, width: 18, height: 7)
            g.fill(Path(roundedRect: bRect, cornerRadius: 3), with: .color(.white.opacity(0.96)))
            g.stroke(Path(roundedRect: bRect, cornerRadius: 3), with: .color(Color(white: 0.85)), lineWidth: 1)
            g.fill(Path(ellipseIn: CGRect(x: -1.5, y: -1.5, width: 3, height: 3)),
                   with: .color(Color(white: 0.8)))
        }
    }

    // MARK: 小图形

    static func heart(_ c: GraphicsContext, at p: CGPoint, r: Double, alpha: Double) {
        var g = c
        g.opacity = alpha
        g.fill(Path(ellipseIn: CGRect(x: p.x - 0.85 * r, y: p.y - 0.7 * r, width: r, height: r)), with: .color(blush))
        g.fill(Path(ellipseIn: CGRect(x: p.x - 0.15 * r, y: p.y - 0.7 * r, width: r, height: r)), with: .color(blush))
        var tri = Path()
        tri.move(to: CGPoint(x: p.x - 0.78 * r, y: p.y - 0.12 * r))
        tri.addLine(to: CGPoint(x: p.x + 0.78 * r, y: p.y - 0.12 * r))
        tri.addLine(to: CGPoint(x: p.x, y: p.y + 0.72 * r))
        tri.closeSubpath()
        g.fill(tri, with: .color(blush))
    }

    static func sparkle(_ c: GraphicsContext, at p: CGPoint, r: Double, color: Color, alpha: Double) {
        var path = Path()
        let k = 0.36
        path.move(to: CGPoint(x: p.x, y: p.y - r))
        path.addQuadCurve(to: CGPoint(x: p.x + r, y: p.y), control: CGPoint(x: p.x + r * k, y: p.y - r * k))
        path.addQuadCurve(to: CGPoint(x: p.x, y: p.y + r), control: CGPoint(x: p.x + r * k, y: p.y + r * k))
        path.addQuadCurve(to: CGPoint(x: p.x - r, y: p.y), control: CGPoint(x: p.x - r * k, y: p.y + r * k))
        path.addQuadCurve(to: CGPoint(x: p.x, y: p.y - r), control: CGPoint(x: p.x - r * k, y: p.y - r * k))
        path.closeSubpath()
        var g = c
        g.opacity = alpha
        g.fill(path, with: .color(color))
    }

    static func angerMark(_ c: GraphicsContext, at p: CGPoint) {
        let g = c
        for a in [0.55, 1.57, 2.6, 3.6] {
            let dx = sin(a), dy = -cos(a)
            var line = Path()
            line.move(to: CGPoint(x: p.x + dx * 2.5, y: p.y + dy * 2.5))
            line.addLine(to: CGPoint(x: p.x + dx * 7, y: p.y + dy * 7))
            g.stroke(line, with: .color(red), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        }
    }
}

// MARK: - 视图

struct PelicanView: View {
    var draw: PelicanDraw
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                PelicanArt.draw(&ctx, size: size, t: t, d: draw)
            }
        }
        .allowsHitTesting(false)
    }
}
