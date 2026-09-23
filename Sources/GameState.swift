import Foundation
import Combine
import CoreGraphics

// MARK: - 基础类型

enum HPState: Int, Codable, Equatable {
    case bedridden, sick, wilted, normal, energetic

    init(hp: Double) {
        switch hp {
        case ..<15: self = .bedridden
        case ..<35: self = .sick
        case ..<55: self = .wilted
        case ..<80: self = .normal
        default:    self = .energetic
        }
    }

    var label: String {
        switch self {
        case .bedridden: return "卧床"
        case .sick:      return "生病"
        case .wilted:    return "蔫了"
        case .normal:    return "正常"
        case .energetic: return "元气"
        }
    }
}

enum Mood: Equatable { case none, angry, happy }

/// 监工动物：老朋友鹈鹕 + 十二生肖
enum Animal: String, CaseIterable, Codable {
    case pelican, rat, ox, tiger, rabbit, dragon, snake, horse, goat, monkey, rooster, dog, pig

    var name: String {
        switch self {
        case .pelican: return "鹈鹕"
        case .rat:     return "小老鼠"
        case .ox:      return "小牛"
        case .tiger:   return "小老虎"
        case .rabbit:  return "小兔子"
        case .dragon:  return "小青龙"
        case .snake:   return "小蛇"
        case .horse:   return "小马"
        case .goat:    return "小羊"
        case .monkey:  return "小猴子"
        case .rooster: return "小鸡"
        case .dog:     return "小狗"
        case .pig:     return "小猪"
        }
    }

    var emoji: String {
        switch self {
        case .pelican: return "🦩"
        case .rat:     return "🐀"
        case .ox:      return "🐂"
        case .tiger:   return "🐯"
        case .rabbit:  return "🐰"
        case .dragon:  return "🐉"
        case .snake:   return "🐍"
        case .horse:   return "🐴"
        case .goat:    return "🐐"
        case .monkey:  return "🐵"
        case .rooster: return "🐓"
        case .dog:     return "🐶"
        case .pig:     return "🐷"
        }
    }
}

enum Symptom: String, Codable, CaseIterable {
    case bandage, thermometer, shiver, dizzy, cough
}

struct DailyStats: Codable, Equatable {
    var sittingMinutes: Double = 0
    var deepMinutes: Double = 0
    var genuineBreaks: Int = 0
    var caughtBreaks: Int = 0
    var minHP: Double = 100
    var maxHP: Double = 0
    var hospitalized: Bool = false
}

enum WalkPhase: Equatable {
    case idle
    case walkingOut(start: Date)
    case resting(grace: Date, hpAtStart: Double)
    case walkingIn(start: Date, happy: Bool)
}

enum GameEvent {
    case entered(HPState)
    case breakCaught
    case breakGenuine
}

// MARK: - 空闲检测（无需任何系统权限）

final class IdleTracker {
    /// kCGAnyInputEventType：键盘 + 鼠标 + 触控板一切输入
    private static let anyInput = CGEventType(rawValue: UInt32.max)!

    /// 距离最近一次键鼠输入过了多少秒（系统级表，无需任何权限）
    func seconds() -> Double {
        Double(CGEventSource.secondsSinceLastEventType(.hidSystemState,
                                                       eventType: Self.anyInput))
    }
}

// MARK: - 游戏状态

final class GameState: ObservableObject {
    // 可调参数
    static let presentMax: TimeInterval = 600      // 10 分钟内有输入 = 在电脑前
    static let deepMinutes: Double = 45            // 连续坐满 45 分钟进入深度久坐
    static let decayPerMin: Double = 2             // 每分钟 -2 HP
    static let deepMultiplier: Double = 2          // 深度久坐衰减 x2
    static let recoveryPerMin: Double = 20         // 休息回血 +20 HP/min
    static let caughtPenalty: Double = 5           // 被抓包额外 -5 HP
    static let caughtKeep: Double = 0.3            // 被抓包后回血量只保留 30%
    static let breakGrace: TimeInterval = 1.5      // 点完按钮的宽限期（不算抓包）

    @Published var hp: Double = 100
    @Published var consecutiveSittingMinutes: Double = 0
    @Published var deepSitting = false
    @Published var mood: Mood = .none
    @Published var moodUntil = Date.distantPast
    @Published var bandageUntil = Date.distantPast   // 住院后的绷带特效
    @Published var symptoms: [Symptom] = []
    @Published var walk: WalkPhase = .idle
    @Published var animal: Animal = .pelican
    @Published var muted = false
    @Published var idleSeconds: Double = 0
    @Published var windowOriginX: Double = 0
    @Published var panelVisible = true
    @Published var loginItemEnabled = false

    var dateKey: String = GameState.key(for: Date())
    var daily: [String: DailyStats] = [:]
    var lastSeen = Date()
    /// 鹈鹕走屏时的起点（屏幕坐标 x）
    var walkFromScreenX: Double = 0

    var hpState: HPState { HPState(hp: hp) }

    var inBreak: Bool {
        if case .resting = walk { return true }
        return false
    }

    var hospitalizedToday: Bool { (daily[dateKey] ?? DailyStats()).hospitalized }

    /// 离开电脑超过 10 分钟且不在休息中（真休息结束后人还没回来也算离开）
    var away: Bool {
        if inBreak { return false }
        if idleSeconds >= Self.presentMax { return true }
        return breakEndedAt != nil
    }

    private var lastTick: Date = Date()
    private var lastHPState: HPState = .energetic
    /// 真休息结束的时刻：在用户回来（产生输入）之前，不恢复「坐下掉血」
    var breakEndedAt: Date?

    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    static func key(for d: Date) -> String { keyFormatter.string(from: d) }

    var today: DailyStats {
        get { daily[dateKey, default: DailyStats()] }
        set { daily[dateKey] = newValue }
    }

    // MARK: 主循环（10Hz）

    @discardableResult
    func tick(now: Date, idle: Double) -> [GameEvent] {
        var events: [GameEvent] = []
        rollDayIfNeeded(now: now)

        var dt = now.timeIntervalSince(lastTick)
        lastTick = now
        guard dt > 0 else { return events }
        dt = min(dt, 120)   // 休眠/唤醒安全上限

        idleSeconds = idle

        switch walk {
        case .resting(let grace, let hpAtStart):
            // 休息中：实时回血
            hp = min(100, hp + Self.recoveryPerMin * dt / 60)
            if hp >= 100 {
                // 回满 = 真休息
                today.genuineBreaks += 1
                consecutiveSittingMinutes = 0
                deepSitting = false
                breakEndedAt = now   // 人多半还在外面：回来前不掉血
                events.append(.breakGenuine)
            } else if now.timeIntervalSince(grace) > 0,
                      idle < now.timeIntervalSince(grace) {
                // 宽限期之后有过任何输入 = 被抓包
                let recovered = hp - hpAtStart
                hp = max(0, hpAtStart + recovered * Self.caughtKeep - Self.caughtPenalty)
                today.caughtBreaks += 1
                events.append(.breakCaught)
            }
        default:
            // 「在电脑前工作」= 最近 10 分钟内有输入，且（真休息结束后）人已经回来
            let lastInput = now.addingTimeInterval(-idle)
            let returned = breakEndedAt.map { lastInput >= $0 } ?? true
            if idle < Self.presentMax && returned {
                breakEndedAt = nil
                // 在电脑前坐着：掉血
                consecutiveSittingMinutes += dt / 60
                today.sittingMinutes += dt / 60
                deepSitting = consecutiveSittingMinutes >= Self.deepMinutes
                if deepSitting { today.deepMinutes += dt / 60 }
                let rate = Self.decayPerMin * (deepSitting ? Self.deepMultiplier : 1)
                hp = max(0, hp - rate * dt / 60)
            } else if idle >= Self.presentMax {
                // 离开超过 10 分钟：重置连续久坐，并按休息速度回血
                consecutiveSittingMinutes = 0
                deepSitting = false
                hp = min(100, hp + Self.recoveryPerMin * dt / 60)
            } else {
                // 真休息结束但人还没回来：暂停（不掉血，HP 已是满的）
                consecutiveSittingMinutes = 0
                deepSitting = false
            }
        }

        today.minHP = min(today.minHP, hp)
        today.maxHP = max(today.maxHP, hp)

        let s = hpState
        if s != lastHPState {
            lastHPState = s
            events.append(.entered(s))
            if s == .sick {
                // 进入生病：随机抽 1~2 个稳定症状
                if symptoms.isEmpty {
                    let pool = Symptom.allCases.shuffled()
                    symptoms = Array(pool.prefix(Int.random(in: 1...2)))
                }
            } else if s != .bedridden {
                symptoms = []
            }
        }
        if mood != .none && now > moodUntil { mood = .none }
        return events
    }

    // MARK: 动作

    func startBreak() {
        guard !inBreak else { return }
        walk = .walkingOut(start: Date().addingTimeInterval(0.28))
    }

    func finishWalkOut(now: Date) {
        guard case .walkingOut = walk else { return }
        walk = .resting(grace: now.addingTimeInterval(Self.breakGrace), hpAtStart: hp)
    }

    func beginWalkIn(now: Date, happy: Bool) {
        walk = .walkingIn(start: now.addingTimeInterval(0.28), happy: happy)
    }

    func finishWalkIn(now: Date, happy: Bool) {
        guard case .walkingIn = walk else { return }
        walk = .idle
        if happy {
            mood = .happy
            moodUntil = now.addingTimeInterval(20)
        } else {
            mood = .angry
            moodUntil = now.addingTimeInterval(30)
        }
    }

    @discardableResult
    func freeHospitalization(now: Date) -> Bool {
        if hospitalizedToday || inBreak { return false }
        today.hospitalized = true
        hp = 100
        consecutiveSittingMinutes = 0
        deepSitting = false
        mood = .happy
        moodUntil = now.addingTimeInterval(20)
        bandageUntil = now.addingTimeInterval(20)
        lastHPState = .energetic
        return true
    }

    // MARK: 持久化

    struct Snapshot: Codable {
        var hp: Double
        var consecutiveSittingMinutes: Double
        var daily: [String: DailyStats]
        var lastSeen: Date
        var muted: Bool
        var symptoms: [Symptom]
        var dateKey: String
        var panelOrigin: [Double]
        /// 可选：旧版 state.json 没有该字段（默认鹈鹕）
        var animal: Animal?
    }

    func snapshot(origin: [Double]) -> Snapshot {
        lastSeen = Date()
        return Snapshot(hp: hp,
                        consecutiveSittingMinutes: consecutiveSittingMinutes,
                        daily: daily,
                        lastSeen: lastSeen,
                        muted: muted,
                        symptoms: symptoms,
                        dateKey: dateKey,
                        panelOrigin: origin,
                        animal: animal)
    }

    func restore(_ s: Snapshot) {
        hp = min(100, max(0, s.hp))
        consecutiveSittingMinutes = s.consecutiveSittingMinutes
        daily = s.daily
        muted = s.muted
        symptoms = s.symptoms
        animal = s.animal ?? .pelican
        lastSeen = s.lastSeen
        dateKey = Self.key(for: Date())
        // 关闭期间的补课掉血：上限 60 分钟，按 -2/分
        let gap = Date().timeIntervalSince(s.lastSeen)
        if gap > 60 {
            let mins = min(gap, 3600) / 60
            hp = max(0, hp - Self.decayPerMin * mins)
        }
        rollDayIfNeeded(now: Date())
        deepSitting = consecutiveSittingMinutes >= Self.deepMinutes
        walk = .idle
        mood = .none
        lastTick = Date()
        lastHPState = hpState
    }

    // MARK: 绘制参数

    func baseDraw() -> PelicanDraw {
        var d = PelicanDraw(hpState: hpState, mood: mood, pose: .standing)
        d.animal = animal
        d.symptoms = symptoms
        d.showBandage = Date() < bandageUntil
        d.away = away
        return d
    }

    var standingDraw: PelicanDraw { baseDraw() }

    var restingDraw: PelicanDraw {
        var d = baseDraw()
        d.pose = .resting
        return d
    }

    var stripDraw: PelicanDraw {
        var d = baseDraw()
        d.away = false
        switch walk {
        case .walkingOut(let s):
            d.pose = .walkingOut
            d.walkT0 = s.timeIntervalSinceReferenceDate
        case .walkingIn(let s, let happy):
            d.pose = .walkingIn
            d.walkT0 = s.timeIntervalSinceReferenceDate
            d.mood = happy ? .happy : .angry
        default:
            break
        }
        d.walkFromX = walkFromScreenX
        d.windowOriginX = windowOriginX
        return d
    }

    private func rollDayIfNeeded(now: Date) {
        let k = Self.key(for: now)
        if k != dateKey { dateKey = k }
        if daily[dateKey] == nil { daily[dateKey] = DailyStats() }
        // 只保留最近 8 天
        let keys = daily.keys.sorted()
        for key in keys.dropLast(8) { daily[key] = nil }
    }
}
