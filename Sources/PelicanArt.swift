import SwiftUI
import Foundation

// MARK: - 绘制参数

struct PelicanDraw {
    enum Pose { case standing, resting, walkingOut, walkingIn }
    var hpState: HPState
    var mood: Mood
    var pose: Pose
    var animal: Animal = .pelican
    var symptoms: [Symptom] = []
    var showBandage: Bool = false
    var away: Bool = false
    var walkT0: Double = 0
    var walkFromX: Double = 0
    var windowOriginX: Double = 0
}

enum EyeStyle {
    case open(r: CGFloat)
    case blink
    case half
    case x
    case happyArc
}

// MARK: - 动物绘制（全代码绘制，无素材）
//
// 统一约定（各动物 body 函数必须遵守）：
//  · 局部坐标：身体中心为原点，+x 朝右，+y 朝下；单位 ≈ pt（卡片画布 212×118）
//  · 框架已画：地面阴影、卧床 115° 整体旋转、漂浮特效（爱心/生气/星星/鼻涕气泡/毯子）
//  · 头部统一放在约 (30, -27)、半径 14~17，脸朝右；嘴/鼻尖（头部局部）约 (18…28, -3…2)
//  · 内容保持在 x ∈ [-55, 108]、y ∈ [-58, 62]（局部）内，避免卡片裁切
//  · 卧床（bedridden）时不画腿（身体被整体旋转）

enum PelicanArt {
    // MARK: 共享色板
    static let ink = Color(red: 0.13, green: 0.15, blue: 0.17)
    static let bodyLine = Color(red: 0.83, green: 0.88, blue: 0.91)
    static let beakColor = Color(red: 0.976, green: 0.659, blue: 0.145)
    static let pouchColor = Color(red: 0.976, green: 0.698, blue: 0.204)
    static let wingFill = Color(red: 0.94, green: 0.96, blue: 0.97)
    static let wingLine = Color(red: 0.80, green: 0.86, blue: 0.90)
    static let legFar = Color(red: 0.88, green: 0.54, blue: 0.0)
    static let legNear = Color(red: 0.969, green: 0.722, blue: 0.29)
    static let red = Color(red: 0.93, green: 0.32, blue: 0.34)
    static let sickTint = Color(red: 0.42, green: 0.78, blue: 0.45)
    static let angryTint = Color(red: 1.0, green: 0.4, blue: 0.4)
    static let pinkBlanket = Color(red: 1.0, green: 0.78, blue: 0.83)
    static let blanketLine = Color(red: 1.0, green: 0.62, blue: 0.70)
    static let nosePink = Color(red: 1.0, green: 0.56, blue: 0.67)
    static let earInner = Color(red: 1.0, green: 0.70, blue: 0.78)
    static let footOrange = Color(red: 1.0, green: 0.62, blue: 0.25)

    // MARK: 共享几何
    static let bodyRect = CGRect(x: -40, y: -27, width: 80, height: 54)
    static let bellyRect = CGRect(x: -30, y: -10, width: 46, height: 36)
    static let wingRect = CGRect(x: -25, y: -14, width: 50, height: 28)

    /// 各动物身体函数返回的头部信息（框架据此画漂浮特效）
    struct HeadInfo {
        var center: CGPoint     // 身体局部坐标
        var radius: CGFloat
        var mouthTip: CGPoint   // 嘴/鼻尖（身体局部），鼻涕/咳嗽气泡从这里出发
    }

    /// 姿势参数（框架统一计算，与动物无关）
    struct Pose {
        var yOff: Double        // 整体上下弹跳（框架已应用，body 函数不要再加）
        var headTilt: Double    // 头部倾斜（弧度，身体病歪/生气/走路）
        var swing2: Double      // 次要动效（约 -34…34，用于翅膀/耳朵/尾巴）
        var swing: Double       // 走路腿摆幅（0 或 0.5）
        var eyes: EyeStyle
        var mouthOpen: Bool
    }

    // MARK: 入口

    static func draw(_ ctx: inout GraphicsContext, size: CGSize, t: Double, d: PelicanDraw) {
        switch d.pose {
        case .standing:
            drawAnimal(&ctx, t: t, d: d,
                       anchor: CGPoint(x: size.width / 2 - 8, y: size.height - 58),
                       scale: 1.0, walkPhase: 0)
        case .resting:
            drawRestingScene(&ctx, size: size, t: t, d: d)
        case .walkingOut, .walkingIn:
            drawStrip(&ctx, t: t, d: d)
        }
    }

    // MARK: 统一绘制（阴影 + 旋转 + 调度 + 漂浮特效）

    static func drawAnimal(_ ctx: inout GraphicsContext, t: Double, d: PelicanDraw,
                           anchor: CGPoint, scale: CGFloat, walkPhase: Double) {
        let bed = d.hpState == .bedridden
        let p = pose(t: t, d: d, walkPhase: walkPhase)
        let shiver = d.symptoms.contains(.shiver) ? sin(t * 46) * 0.9 : 0

        // 地面阴影
        let shW: CGFloat = bed ? 112 : 92
        let shY: CGFloat = bed ? 40 : 52
        ctx.fill(Path(ellipseIn: CGRect(x: anchor.x - shW / 2 * scale,
                                        y: anchor.y + shY * scale - 8,
                                        width: shW * scale, height: 16)),
                 with: .color(.black.opacity(bed ? 0.14 : 0.11)))

        var c = ctx
        c.translateBy(x: anchor.x + shiver, y: anchor.y + p.yOff)
        c.scaleBy(x: scale, y: scale)
        if bed { c.rotate(by: .degrees(115)) }

        let head: HeadInfo
        switch d.animal {
        case .pelican: head = drawPelicanBody(&c, t: t, d: d, p: p, walkPhase: walkPhase)
        case .rat:     head = drawRatBody(&c, t: t, d: d, p: p, walkPhase: walkPhase)
        case .ox:      head = drawOxBody(&c, t: t, d: d, p: p, walkPhase: walkPhase)
        case .tiger:   head = drawTigerBody(&c, t: t, d: d, p: p, walkPhase: walkPhase)
        case .rabbit:  head = drawRabbitBody(&c, t: t, d: d, p: p, walkPhase: walkPhase)
        case .dragon:  head = drawDragonBody(&c, t: t, d: d, p: p, walkPhase: walkPhase)
        case .snake:   head = drawSnakeBody(&c, t: t, d: d, p: p, walkPhase: walkPhase)
        case .horse:   head = drawHorseBody(&c, t: t, d: d, p: p, walkPhase: walkPhase)
        case .goat:    head = drawGoatBody(&c, t: t, d: d, p: p, walkPhase: walkPhase)
        case .monkey:  head = drawMonkeyBody(&c, t: t, d: d, p: p, walkPhase: walkPhase)
        case .rooster: head = drawRoosterBody(&c, t: t, d: d, p: p, walkPhase: walkPhase)
        case .dog:     head = drawDogBody(&c, t: t, d: d, p: p, walkPhase: walkPhase)
        case .pig:     head = drawPigBody(&c, t: t, d: d, p: p, walkPhase: walkPhase)
        }
        drawFloatingEffects(&c, t: t, d: d, head: head)
    }

    private static func pose(t: Double, d: PelicanDraw, walkPhase: Double) -> Pose {
        let walking = walkPhase != 0
        var yOff: Double = 0
        var headTilt: Double = 0
        var swing2: Double = 0
        var eyes: EyeStyle = .open(r: 3)
        var mouthOpen = false
        switch d.hpState {
        case .energetic:
            yOff = -3 * abs(sin(t * 4.5))
            swing2 = sin(t * 6.2) * 22 - 8
        case .normal:
            swing2 = sin(t * 1.7) * 7
        case .wilted:
            headTilt = 0.18
            eyes = .half
        case .sick:
            headTilt = 0.12
            eyes = .open(r: 2.6)
        case .bedridden:
            eyes = .x
        }
        if d.mood == .happy {
            yOff = -4 * abs(sin(t * 5.5))
            headTilt -= 0.06
            swing2 = sin(t * 8) * 26 - 10
            eyes = .happyArc
            mouthOpen = true
        }
        if d.mood == .angry { headTilt -= 0.12 }
        if walking {
            yOff = -3 * abs(sin(walkPhase))
            headTilt -= 0.05
            swing2 = 0
        }
        if case .open = eyes, fmod(t + 0.9, 3.6) < 0.13 { eyes = .blink }
        return Pose(yOff: yOff, headTilt: headTilt, swing2: swing2,
                    swing: walking ? 0.5 : 0, eyes: eyes, mouthOpen: mouthOpen)
    }

    // MARK: 共享小部件

    static func drawEye(_ ctx: GraphicsContext, _ e: CGPoint, _ style: EyeStyle, eyelid: Color = .white) {
        switch style {
        case .open(let rad):
            ctx.fill(Path(ellipseIn: CGRect(x: e.x - rad, y: e.y - rad, width: rad * 2, height: rad * 2)),
                     with: .color(ink))
            ctx.fill(Path(ellipseIn: CGRect(x: e.x - rad + rad * 0.35, y: e.y - rad + rad * 0.25,
                                            width: rad * 0.55, height: rad * 0.55)),
                     with: .color(.white))
        case .blink:
            var p = Path()
            p.move(to: CGPoint(x: e.x - 3.5, y: e.y))
            p.addLine(to: CGPoint(x: e.x + 3.5, y: e.y))
            ctx.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        case .half:
            ctx.fill(Path(ellipseIn: CGRect(x: e.x - 3, y: e.y - 3, width: 6, height: 6)), with: .color(ink))
            ctx.fill(Path(CGRect(x: e.x - 4, y: e.y - 4.5, width: 8, height: 4.6)), with: .color(eyelid))
            var line = Path()
            line.move(to: CGPoint(x: e.x - 3.5, y: e.y))
            line.addLine(to: CGPoint(x: e.x + 3.5, y: e.y))
            ctx.stroke(line, with: .color(ink), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        case .x:
            var p = Path()
            p.move(to: CGPoint(x: e.x - 3, y: e.y - 3))
            p.addLine(to: CGPoint(x: e.x + 3, y: e.y + 3))
            p.move(to: CGPoint(x: e.x + 3, y: e.y - 3))
            p.addLine(to: CGPoint(x: e.x - 3, y: e.y + 3))
            ctx.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        case .happyArc:
            var p = Path()
            p.move(to: CGPoint(x: e.x - 3.2, y: e.y + 0.5))
            p.addQuadCurve(to: CGPoint(x: e.x + 3.2, y: e.y + 0.5),
                           control: CGPoint(x: e.x, y: e.y - 4.5))
            ctx.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }

    static func drawLeg(_ ctx: GraphicsContext, hip: CGPoint, angle: Double, color: Color,
                        length: CGFloat = 24, width: CGFloat = 4.5) {
        var p = Path()
        p.move(to: CGPoint(x: hip.x, y: hip.y))
        p.addLine(to: CGPoint(x: hip.x + sin(angle) * 8, y: hip.y + cos(angle) * 12))
        p.addLine(to: CGPoint(x: hip.x + sin(angle) * 10, y: hip.y + length))
        ctx.stroke(p, with: .color(color),
                   style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        var foot = Path()
        foot.move(to: CGPoint(x: hip.x + sin(angle) * 10 - 3, y: hip.y + length))
        foot.addLine(to: CGPoint(x: hip.x + sin(angle) * 10 + 4, y: hip.y + length))
        ctx.stroke(foot, with: .color(color),
                   style: StrokeStyle(lineWidth: width + 0.5, lineCap: .round))
    }

    /// 生病/生气时的身体与头部染色
    static func bodyTint(_ d: PelicanDraw) -> (Color, Double)? {
        if d.hpState == .sick { return (sickTint, 0.30) }
        if d.mood == .angry { return (angryTint, 0.22) }
        return nil
    }
    static func headTint(_ d: PelicanDraw) -> (Color, Double)? {
        if d.hpState == .sick { return (sickTint, 0.34) }
        if d.mood == .angry { return (angryTint, 0.28) }
        return nil
    }

    /// 头部局部症状（坐标 = 头部局部，原点=头部中心，嘴/鼻尖=mouthLocal）
    static func drawHeadSymptoms(_ hg: inout GraphicsContext, t: Double, d: PelicanDraw,
                                 mouthLocal: CGPoint) {
        // 腮红（高兴）
        if d.mood == .happy {
            hg.fill(Path(ellipseIn: CGRect(x: 0, y: 2, width: 7, height: 4.5)),
                    with: .color(Color(red: 1, green: 0.5, blue: 0.55).opacity(0.4)))
        }
        // 体温计（浅蓝玻璃管叼在嘴边，红色水银在管子中段——嘴部无红色，别像抽烟）
        if d.symptoms.contains(.thermometer) {
            let mx = mouthLocal.x, my = mouthLocal.y
            let glass = Color(red: 0.88, green: 0.94, blue: 0.99)
            var p = Path()
            p.move(to: CGPoint(x: mx + 1, y: my - 0.5))
            p.addLine(to: CGPoint(x: mx + 15, y: my - 8))
            hg.stroke(p, with: .color(glass), style: StrokeStyle(lineWidth: 3.8, lineCap: .round))
            // 红色水银（管子中段，离嘴和管尖都有距离）
            var m = Path()
            m.move(to: CGPoint(x: mx + 4.5, y: my - 2.4))
            m.addLine(to: CGPoint(x: mx + 11.5, y: my - 5.9))
            hg.stroke(m, with: .color(red), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        }
        // 流鼻涕
        if d.hpState == .sick {
            var m = Path()
            let mx = mouthLocal.x, my = mouthLocal.y
            m.move(to: CGPoint(x: mx, y: my + 1))
            m.addQuadCurve(to: CGPoint(x: mx + 1.5, y: my + 12),
                           control: CGPoint(x: mx - 3.5, y: my + 7))
            m.addQuadCurve(to: CGPoint(x: mx, y: my + 1),
                           control: CGPoint(x: mx + 5.5, y: my + 7))
            hg.fill(m, with: .color(Color(red: 0.65, green: 0.85, blue: 1).opacity(0.9)))
        }
        // 口水（蔫了）
        if d.hpState == .wilted {
            let dx: CGFloat = -13, dy: CGFloat = -11
            var s = Path()
            s.move(to: CGPoint(x: dx, y: dy - 5))
            s.addQuadCurve(to: CGPoint(x: dx - 4, y: dy + 4), control: CGPoint(x: dx - 6.5, y: dy - 1))
            s.addQuadCurve(to: CGPoint(x: dx, y: dy + 5.5), control: CGPoint(x: dx + 4, y: dy + 4))
            s.addQuadCurve(to: CGPoint(x: dx, y: dy - 5), control: CGPoint(x: dx + 6.5, y: dy - 1))
            hg.fill(s, with: .color(Color(red: 0.75, green: 0.89, blue: 1).opacity(0.85)))
        }
        // 绷带
        if d.showBandage || d.symptoms.contains(.bandage) {
            hg.translateBy(x: 5, y: -11)
            hg.rotate(by: .degrees(-32))
            let br = CGRect(x: -12, y: -3.5, width: 24, height: 7)
            hg.fill(Path(roundedRect: br, cornerRadius: 3.5), with: .color(.white.opacity(0.92)))
            hg.stroke(Path(roundedRect: br, cornerRadius: 3.5), with: .color(.black.opacity(0.08)), lineWidth: 1)
            for dx in [-6.0, -2.0, 2.0, 6.0] {
                hg.fill(Path(ellipseIn: CGRect(x: dx - 0.9, y: -0.9, width: 1.8, height: 1.8)),
                        with: .color(.black.opacity(0.10)))
            }
            hg.rotate(by: .degrees(32))
            hg.translateBy(x: -5, y: 11)
        }
    }

    /// 漂浮特效（身体局部坐标；head 来自各动物 body 函数）
    static func drawFloatingEffects(_ ctx: inout GraphicsContext, t: Double, d: PelicanDraw,
                                    head: HeadInfo) {
        let hc = head.center
        // 元气星星
        if d.hpState == .energetic && d.mood == .none {
            let angs: [Double] = [1.1, 2.4, 3.9, 5.2]
            for (i, ang) in angs.enumerated() {
                let rr = 52 + 6 * sin(t * 2 + Double(i))
                let sp = CGPoint(x: sin(ang + t * 0.3) * rr, y: -12 + cos(ang + t * 0.3) * rr * 0.72)
                sparkle(ctx, at: sp, s: 3.5, alpha: 0.5 + 0.5 * sin(t * 5 + Double(i) * 1.7))
            }
        }
        // 爱心（高兴）
        if d.mood == .happy {
            for i in 0..<3 {
                let ph = fmod(t * 0.7 + Double(i) * 0.33, 1)
                let hx = hc.x + 16 + Double(i) * 9 + sin(t * 2 + Double(i)) * 3
                let hy = hc.y - 18 - ph * 26
                heart(ctx, at: CGPoint(x: hx, y: hy), s: 4.5 + Double(i), alpha: 1 - ph)
            }
        }
        // 生气
        if d.mood == .angry {
            angerMark(ctx, at: CGPoint(x: hc.x - 24, y: hc.y - 18))
            ctx.draw(Text("!!").font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(red),
                     at: CGPoint(x: hc.x + 30, y: hc.y - 18))
        }
        // 离开（？）
        if d.away {
            ctx.draw(Text("？").font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.52, green: 0.60, blue: 0.68)),
                   at: CGPoint(x: hc.x + 8, y: hc.y - 20 + sin(t * 2) * 2.5))
        }
        // 头晕星星
        if d.symptoms.contains(.dizzy) && d.hpState == .sick {
            for i in 0..<3 {
                let ang = t * 3 + Double(i) * 2.09
                let sp = CGPoint(x: hc.x + cos(ang) * 27, y: hc.y - 6 + sin(ang) * 13)
                sparkle(ctx, at: sp, s: 3.2, alpha: 0.9)
            }
        }
        // 咳嗽气泡
        if d.symptoms.contains(.cough) && d.hpState != .bedridden {
            for i in 0..<2 {
                let ph = fmod(t * 1.4 + Double(i) * 0.4, 1)
                let pp = CGPoint(x: head.mouthTip.x + 14 + ph * 12, y: head.mouthTip.y - 2 - ph * 8)
                let rr = 2.2 + ph * 3.5
                ctx.fill(Path(ellipseIn: CGRect(x: pp.x - rr, y: pp.y - rr * 0.8,
                                                width: rr * 2, height: rr * 1.6)),
                         with: .color(.gray.opacity(0.35 * (1 - ph))))
            }
        }
        // 粉色毯子（卧床）
        if d.hpState == .bedridden {
            var g = ctx
            g.opacity = 0.97
            let bl = CGRect(x: -2, y: -40, width: 56, height: 76)
            g.fill(Path(roundedRect: bl, cornerRadius: 20), with: .color(pinkBlanket))
            for yy in stride(from: -24.0, through: 26.0, by: 12) {
                var line = Path()
                line.move(to: CGPoint(x: -2, y: yy))
                line.addLine(to: CGPoint(x: 54, y: yy))
                g.stroke(line, with: .color(blanketLine), lineWidth: 2.5)
            }
            g.stroke(Path(roundedRect: bl, cornerRadius: 20),
                     with: .color(.black.opacity(0.06)), lineWidth: 1.5)
        }
    }

    static func heart(_ ctx: GraphicsContext, at p: CGPoint, s: Double, alpha: Double) {
        let g = Color(red: 1.0, green: 0.45, blue: 0.52).opacity(max(0, alpha))
        let r = s * 0.62
        var path = Path()
        path.addEllipse(in: CGRect(x: p.x - r, y: p.y - r * 0.7, width: r * 2, height: r * 2))
        path.addEllipse(in: CGRect(x: p.x, y: p.y - r * 0.7, width: r * 2, height: r * 2))
        ctx.fill(path, with: .color(g))
        var tri = Path()
        tri.move(to: CGPoint(x: p.x - r * 0.95, y: p.y + r * 0.25))
        tri.addLine(to: CGPoint(x: p.x + r * 1.95, y: p.y + r * 0.25))
        tri.addLine(to: CGPoint(x: p.x + r * 0.5, y: p.y + r * 2.1))
        tri.closeSubpath()
        ctx.fill(tri, with: .color(g))
    }

    static func sparkle(_ ctx: GraphicsContext, at p: CGPoint, s: Double, alpha: Double) {
        let col = Color(red: 1.0, green: 0.85, blue: 0.30).opacity(max(0, alpha))
        var path = Path()
        path.move(to: CGPoint(x: p.x, y: p.y - s))
        path.addQuadCurve(to: CGPoint(x: p.x + s, y: p.y), control: p)
        path.addQuadCurve(to: CGPoint(x: p.x, y: p.y + s), control: p)
        path.addQuadCurve(to: CGPoint(x: p.x - s, y: p.y), control: p)
        path.addQuadCurve(to: CGPoint(x: p.x, y: p.y - s), control: p)
        ctx.fill(path, with: .color(col))
    }

    static func angerMark(_ ctx: GraphicsContext, at p: CGPoint) {
        let g = ctx
        let cols: [Color] = [Color(red: 0.95, green: 0.45, blue: 0.35), Color(red: 1.0, green: 0.65, blue: 0.25),
                             Color(red: 0.95, green: 0.45, blue: 0.35), Color(red: 1.0, green: 0.65, blue: 0.25)]
        for (i, a) in [0.55, 1.57, 2.6, 3.6].enumerated() {
            let tip = CGPoint(x: p.x + cos(a) * 9, y: p.y + sin(a) * 9)
            let base = CGPoint(x: p.x + cos(a) * 2.5, y: p.y + sin(a) * 2.5)
            var perp = CGVector(dx: -sin(a), dy: cos(a))
            if i % 2 == 1 { perp = CGVector(dx: sin(a), dy: -cos(a)) }
            var path = Path()
            path.move(to: tip)
            path.addLine(to: CGPoint(x: base.x + perp.dx * 3, y: base.y + perp.dy * 3))
            path.addLine(to: CGPoint(x: base.x - perp.dx * 3, y: base.y - perp.dy * 3))
            path.closeSubpath()
            g.fill(path, with: .color(cols[i]))
        }
    }

    // MARK: 走屏（全宽顶条）

    static func drawStrip(_ ctx: inout GraphicsContext, t: Double, d: PelicanDraw) {
        let duration = 1.5
        let p = min(1, max(0, (t - d.walkT0) / duration))
        let e = p * p * (3 - 2 * p)
        var xDraw = d.walkFromX
        switch d.pose {
        case .walkingOut: xDraw = d.walkFromX + (-140 - d.walkFromX) * e
        case .walkingIn:  xDraw = -140 + (d.walkFromX + 140) * e
        default: break
        }
        drawAnimal(&ctx, t: t, d: d,
                   anchor: CGPoint(x: xDraw, y: 102), scale: 1.2, walkPhase: t * 14)
    }

    // MARK: 休息小场景（草地 + 小动物散步）

    static func drawRestingScene(_ ctx: inout GraphicsContext, size: CGSize, t: Double, d: PelicanDraw) {
        let groundY = size.height - 16
        ctx.fill(Path(CGRect(x: 0, y: groundY, width: size.width, height: size.height - groundY)),
                 with: .color(Color(red: 0.85, green: 0.91, blue: 0.80)))
        for (i, sp) in [18.0, 30.0, 12.0].enumerated() {
            let period = size.width + 60
            let bx = size.width - 30 - fmod(t * sp + Double(i) * 90, period) + 30
            let by = groundY - 4 - Double(i) * 3
            let br = 10 + Double(i) * 3
            ctx.fill(Path(ellipseIn: CGRect(x: bx - br, y: by - br * 0.7, width: br * 2, height: br * 1.4)),
                     with: .color(Color(red: 0.55, green: 0.72, blue: 0.45).opacity(0.5 + 0.15 * Double(i))))
        }
        var d2 = d
        d2.pose = .standing
        // 脚（anchor + 26*0.52）正好落在 groundY
        drawAnimal(&ctx, t: t, d: d2,
                   anchor: CGPoint(x: size.width / 2, y: groundY - 13.5),
                   scale: 0.52, walkPhase: t * 10)
    }

    // MARK: 鹈鹕（老朋友，原班人马）

    static func drawPelicanBody(_ c: inout GraphicsContext, t: Double, d: PelicanDraw,
                                p: Pose, walkPhase: Double) -> HeadInfo {
        let bed = d.hpState == .bedridden
        let bodyRot: Double = (d.hpState == .wilted || d.hpState == .sick) ? 0.12 : 0

        if !bed { drawLeg(c, hip: CGPoint(x: -8, y: 22), angle: -sin(walkPhase) * p.swing, color: legFar) }
        var tail = Path()
        tail.move(to: CGPoint(x: -34, y: -6))
        tail.addLine(to: CGPoint(x: -52, y: 5))
        tail.addLine(to: CGPoint(x: -31, y: 9))
        tail.closeSubpath()
        c.fill(tail, with: .color(.white))
        c.stroke(tail, with: .color(bodyLine), lineWidth: 1.5)
        var bb = c
        bb.rotate(by: .degrees(bodyRot * 57.2958 - 10))
        bb.fill(Path(ellipseIn: bodyRect), with: .color(.white))
        bb.stroke(Path(ellipseIn: bodyRect), with: .color(bodyLine), lineWidth: 1.5)
        if let (col, a) = bodyTint(d) { bb.fill(Path(ellipseIn: bodyRect), with: .color(col.opacity(a))) }
        var bg = c
        bg.rotate(by: .degrees(bodyRot * 57.2958))
        bg.fill(Path(ellipseIn: bellyRect), with: .color(.white.opacity(0.6)))
        var wg = c
        wg.translateBy(x: -8, y: -4)
        wg.rotate(by: .degrees(p.swing2 + bodyRot * 60))
        wg.fill(Path(ellipseIn: wingRect), with: .color(wingFill))
        wg.stroke(Path(ellipseIn: wingRect), with: .color(wingLine), lineWidth: 1.2)
        if !bed { drawLeg(c, hip: CGPoint(x: 6, y: 24), angle: sin(walkPhase) * p.swing, color: legNear) }
        var neck = Path()
        neck.move(to: CGPoint(x: 22, y: -6))
        neck.addLine(to: CGPoint(x: 36, y: -26))
        c.stroke(neck, with: .color(.white), style: StrokeStyle(lineWidth: 13, lineCap: .round))
        var hg = c
        hg.translateBy(x: 38, y: -30)
        hg.rotate(by: Angle(radians: p.headTilt))
        let headR = CGRect(x: -15, y: -15, width: 30, height: 30)
        hg.fill(Path(ellipseIn: headR), with: .color(.white))
        hg.stroke(Path(ellipseIn: headR), with: .color(bodyLine), lineWidth: 1.5)
        if let (col, a) = headTint(d) { hg.fill(Path(ellipseIn: headR), with: .color(col.opacity(a))) }
        if p.mouthOpen {
            hg.fill(Path(CGRect(x: 12, y: 0.5, width: 10, height: 4.5)), with: .color(.black.opacity(0.35)))
        }
        var pouch = Path()
        pouch.move(to: CGPoint(x: 12, y: -1))
        pouch.addQuadCurve(to: CGPoint(x: 58, y: 2), control: CGPoint(x: 36, y: 13))
        pouch.addQuadCurve(to: CGPoint(x: 12, y: -1), control: CGPoint(x: 24, y: -1))
        hg.fill(pouch, with: .color(pouchColor))
        var beakP = Path()
        beakP.move(to: CGPoint(x: 12, y: -5))
        beakP.addLine(to: CGPoint(x: 58, y: 1))
        beakP.addLine(to: CGPoint(x: 14, y: -1))
        beakP.closeSubpath()
        hg.fill(beakP, with: .color(beakColor))
        hg.stroke(beakP, with: .color(.black.opacity(0.08)), lineWidth: 1)
        drawEye(hg, CGPoint(x: 4, y: -6), p.eyes)
        if d.mood == .angry {
            var brow = Path()
            brow.move(to: CGPoint(x: -1, y: -13))
            brow.addLine(to: CGPoint(x: 8, y: -9))
            hg.stroke(brow, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        drawHeadSymptoms(&hg, t: t, d: d, mouthLocal: CGPoint(x: 58, y: 1))
        return HeadInfo(center: CGPoint(x: 38, y: -30), radius: 15, mouthTip: CGPoint(x: 96, y: -29))
    }

    // MARK: 兔子（样板：长耳 + 粉鼻 + 毛球尾巴）

    static func drawRabbitBody(_ c: inout GraphicsContext, t: Double, d: PelicanDraw,
                               p: Pose, walkPhase: Double) -> HeadInfo {
        let bed = d.hpState == .bedridden
        let outline = Color(red: 0.80, green: 0.74, blue: 0.72)
        let bodyC = Color.white

        c.fill(Path(ellipseIn: CGRect(x: -42, y: -3, width: 15, height: 14)), with: .color(bodyC))
        c.stroke(Path(ellipseIn: CGRect(x: -42, y: -3, width: 15, height: 14)), with: .color(outline), lineWidth: 1.4)
        var bb = c
        bb.rotate(by: .degrees(-6))
        let bodyR = CGRect(x: -36, y: -22, width: 64, height: 50)
        bb.fill(Path(ellipseIn: bodyR), with: .color(bodyC))
        bb.stroke(Path(ellipseIn: bodyR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = bodyTint(d) { bb.fill(Path(ellipseIn: bodyR), with: .color(col.opacity(a))) }
        c.fill(Path(ellipseIn: CGRect(x: -14, y: -8, width: 28, height: 26)),
               with: .color(Color(red: 0.97, green: 0.95, blue: 0.94)))
        if !bed {
            drawLeg(c, hip: CGPoint(x: -10, y: 20), angle: -sin(walkPhase) * p.swing, color: earInner, length: 12, width: 7)
            drawLeg(c, hip: CGPoint(x: 8, y: 22), angle: sin(walkPhase) * p.swing, color: earInner, length: 12, width: 7)
        }
        var earL = c
        earL.translateBy(x: 22, y: -34)
        earL.rotate(by: .degrees(-10 + p.swing2 * 0.25))
        let earLR = CGRect(x: -5, y: -24, width: 10, height: 28)
        earL.fill(Path(ellipseIn: earLR), with: .color(bodyC))
        earL.stroke(Path(ellipseIn: earLR), with: .color(outline), lineWidth: 1.4)
        earL.fill(Path(ellipseIn: CGRect(x: -2.6, y: -18, width: 5.2, height: 17)), with: .color(earInner))
        var earR = c
        earR.translateBy(x: 37, y: -34)
        earR.rotate(by: .degrees(9 + p.swing2 * 0.25))
        let earRR = CGRect(x: -5, y: -24, width: 10, height: 28)
        earR.fill(Path(ellipseIn: earRR), with: .color(bodyC))
        earR.stroke(Path(ellipseIn: earRR), with: .color(outline), lineWidth: 1.4)
        earR.fill(Path(ellipseIn: CGRect(x: -2.6, y: -18, width: 5.2, height: 17)), with: .color(earInner))
        var hg = c
        hg.translateBy(x: 30, y: -26)
        hg.rotate(by: Angle(radians: p.headTilt))
        let headR = CGRect(x: -16, y: -14, width: 32, height: 28)
        hg.fill(Path(ellipseIn: headR), with: .color(bodyC))
        hg.stroke(Path(ellipseIn: headR), with: .color(outline), lineWidth: 1.5)
        if let (col, a) = headTint(d) { hg.fill(Path(ellipseIn: headR), with: .color(col.opacity(a))) }
        drawEye(hg, CGPoint(x: 5, y: -4), p.eyes)
        if d.mood == .angry {
            var brow = Path()
            brow.move(to: CGPoint(x: 0, y: -11))
            brow.addLine(to: CGPoint(x: 9, y: -8))
            hg.stroke(brow, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        var nose = Path()
        nose.move(to: CGPoint(x: 13, y: -2))
        nose.addLine(to: CGPoint(x: 18, y: 0))
        nose.addLine(to: CGPoint(x: 13, y: 2))
        nose.closeSubpath()
        hg.fill(nose, with: .color(nosePink))
        var mouth = Path()
        mouth.move(to: CGPoint(x: 15.5, y: 1.5))
        mouth.addQuadCurve(to: CGPoint(x: 11, y: 5.5), control: CGPoint(x: 15.5, y: 4))
        mouth.addQuadCurve(to: CGPoint(x: 20, y: 5.5), control: CGPoint(x: 15.5, y: 4))
        hg.stroke(mouth, with: .color(.black.opacity(0.35)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        for dy in [-1.0, 2.0] {
            var w = Path()
            w.move(to: CGPoint(x: 15, y: dy))
            w.addLine(to: CGPoint(x: 25, y: dy - 2))
            hg.stroke(w, with: .color(.black.opacity(0.15)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        }
        drawHeadSymptoms(&hg, t: t, d: d, mouthLocal: CGPoint(x: 18, y: 0))
        return HeadInfo(center: CGPoint(x: 30, y: -26), radius: 15, mouthTip: CGPoint(x: 48, y: -26))
    }
}

// MARK: - SwiftUI 视图

struct PelicanView: View {
    let draw: PelicanDraw
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                var c = ctx
                PelicanArt.draw(&c, size: size, t: t, d: draw)
            }
        }
    }
}
