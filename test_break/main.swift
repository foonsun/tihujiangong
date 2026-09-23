import Foundation
import Darwin
setvbuf(stdout, nil, _IONBF, 0)

let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)
func now(_ s: Double) -> Date { t0.addingTimeInterval(s) }

func process(_ gs: GameState, _ t: Double, _ idle: Double) -> [GameEvent] {
    gs.tick(now: now(t), idle: idle)
}

print("=== 场景1：点按钮休息 5 分钟（已有逻辑）===")
let gs1 = GameState()
gs1.hp = 60
gs1.startBreak()
var _e = gs1.tick(now: now(0.1), idle: 0.1)
gs1.finishWalkOut(now: now(0.28))
var walkInPending = -1.0
func proc1(_ t: Double, _ idle: Double) {
    var ev = gs1.tick(now: now(t), idle: idle)
    if walkInPending >= 0, t >= walkInPending { gs1.finishWalkIn(now: now(t), happy: true); walkInPending = -1 }
    for e in ev { if case .breakGenuine = e { gs1.beginWalkIn(now: now(t), happy: true); walkInPending = t + 1.78 } }
}
for t in stride(from: 0.5, through: 299.5, by: 0.5) { proc1(t, t) }
proc1(300.0, 0)
for t in stride(from: 300.5, through: 305.0, by: 0.5) { proc1(t, t - 300.0) }
print(String(format: "回来时 hp=%.2f（应≈100），真休息=%d", gs1.hp, gs1.today.genuineBreaks))

print("=== 场景2：没点按钮，离开 20 分钟（新逻辑：离开≥10分钟回血）===")
let gs2 = GameState()
gs2.hp = 50
// 一直无输入（最后一次输入在 t=0），全程没点按钮
for t in stride(from: 0.5, through: 1200.0, by: 5.0) {
    _ = process(gs2, t, t)
    switch t {
    case 595..<600, 1195..<1200:
        print(String(format: "t=%4.0fmin  hp=%5.1f  连续坐=%4.1f  away=%@", t, gs2.hp, gs2.consecutiveSittingMinutes, gs2.away ? "是" : "否"))
    default: break
    }
}
// t=1200s(20min) 回来
_ = process(gs2, 1205.0, 0)
print(String(format: "回来时 hp=%.2f（前10min坐着掉血、后10min回血），久坐=%.1f 分钟", gs2.hp, gs2.consecutiveSittingMinutes))
