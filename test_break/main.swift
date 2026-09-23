import Foundation

// 模拟：t=0 时 HP=60，点「起来休息」，离开 5 分钟（无任何输入），t=300 回来开始工作
let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)
func now(_ s: Double) -> Date { t0.addingTimeInterval(s) }

let gs = GameState()
gs.hp = 60

gs.startBreak()                                  // t=0 点按钮（此刻有输入）
var _e = gs.tick(now: now(0.1), idle: 0.1)
gs.finishWalkOut(now: now(0.28))                 // 0.28s 后走出卡片

var walkInPending = -1.0
func process(_ t: Double, _ idle: Double) {
    var ev = gs.tick(now: now(t), idle: idle)
    if walkInPending >= 0, t >= walkInPending {
        gs.finishWalkIn(now: now(t), happy: true)
        walkInPending = -1
    }
    for e in ev {
        if case .breakGenuine = e {
            gs.beginWalkIn(now: now(t), happy: true)
            walkInPending = t + 1.78
        }
    }
}

print("== 离开期间（没按 10 分钟离开线）==")
for t in stride(from: 0.5, through: 299.5, by: 0.5) {
    process(t, t)                                // 最后一次输入是 t=0
    switch t {
    case 10..<11, 60..<61, 122..<123, 150..<151, 200..<201, 299..<300:
        print(String(format: "t=%5.1f min  hp=%6.2f  连续坐=%5.2f  away=%@", t, gs.hp, gs.consecutiveSittingMinutes, gs.away ? "是" : "否"))
    default: break
    }
}

print("== t=300 回来开始工作 ==")
process(300.0, 0)
for t in stride(from: 300.5, through: 330.0, by: 0.5) {
    process(t, t - 300.0)
    switch t {
    case 300..<301, 310..<311, 320..<321, 329..<330:
        print(String(format: "t=%5.1f min  hp=%6.2f  连续坐=%5.2f  away=%@", t, gs.hp, gs.consecutiveSittingMinutes, gs.away ? "是" : "否"))
    default: break
    }
}
print("真休息次数:", gs.today.genuineBreaks, " 抓包次数:", gs.today.caughtBreaks)
