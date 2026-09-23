import SwiftUI

// MARK: - 颜色扩展

extension HPState {
    var chipColor: Color {
        switch self {
        case .energetic: return Color(red: 0.18, green: 0.75, blue: 0.44)
        case .normal:    return Color(red: 0.35, green: 0.76, blue: 0.44)
        case .wilted:    return Color(red: 0.95, green: 0.72, blue: 0.22)
        case .sick:      return Color(red: 0.94, green: 0.55, blue: 0.30)
        case .bedridden: return Color(red: 0.96, green: 0.36, blue: 0.36)
        }
    }
}

// MARK: - 根视图（卡片 / 走屏条 切换）

struct PanelRootView: View {
    @ObservedObject var state: GameState
    let controller: PanelController

    var body: some View {
        if case .walkingOut = state.walk {
            PelicanView(draw: state.stripDraw)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if case .walkingIn = state.walk {
            PelicanView(draw: state.stripDraw)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            PanelCard(state: state, controller: controller)
        }
    }
}

// MARK: - 小窗卡片

struct PanelCard: View {
    @ObservedObject var state: GameState
    let controller: PanelController

    var body: some View {
        let inBreak = state.inBreak
        let st = state.hpState

        VStack(spacing: 7) {
            HStack(spacing: 6) {
                Text("\(state.animal.emoji) \(state.animal.name)监工")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.20, green: 0.27, blue: 0.35))
                Spacer()
                Text(st.label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(st.chipColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(st.chipColor.opacity(0.14)))
            }

            PelicanView(draw: state.inBreak ? state.restingDraw : state.standingDraw)
                .frame(width: 212, height: 118)

            // HP 条
            VStack(spacing: 3) {
                HStack {
                    Text("HP")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(state.hp.rounded())) / 100")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(st.chipColor)
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(red: 0.93, green: 0.95, blue: 0.97))
                        Capsule()
                            .fill(LinearGradient(colors: [st.chipColor.opacity(0.7), st.chipColor],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(8, g.size.width * CGFloat(state.hp / 100)))
                    }
                }
                .frame(height: 10)
            }

            Text(sittingText)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(sittingColor)
                .lineLimit(1)

            HStack(spacing: 8) {
                Button(action: { controller.startBreak() }) {
                    Text(inBreak ? "休息中…" : "🚶 起来休息")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.616, blue: 0.247),
                                                              Color(red: 1.0, green: 0.42, blue: 0.239)],
                                                     startPoint: .top, endPoint: .bottom))
                        )
                }
                .buttonStyle(.plain)
                .disabled(inBreak)
                .opacity(inBreak ? 0.5 : 1)

                Button(action: { controller.openStats() }) {
                    Text("📊")
                        .font(.system(size: 14))
                        .frame(width: 34, height: 30)
                        .background(iconBg)
                }
                .buttonStyle(.plain)

                Button(action: { controller.doHospital() }) {
                    Text(state.hospitalizedToday ? "✅" : "🏥")
                        .font(.system(size: 14))
                        .frame(width: 34, height: 30)
                        .background(iconBg)
                }
                .buttonStyle(.plain)
                .disabled(state.hospitalizedToday || inBreak)
                .opacity(state.hospitalizedToday || inBreak ? 0.5 : 1)
            }
        }
        .padding(12)
        .frame(width: 236, height: 262)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.93))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(red: 0.89, green: 0.93, blue: 0.96), lineWidth: 1))
        )
    }

    var iconBg: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(red: 0.95, green: 0.97, blue: 0.985))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(red: 0.87, green: 0.91, blue: 0.94), lineWidth: 1))
    }

    var sittingText: String {
        if state.inBreak { return "休息中 · 回血 +20/分 · 别动！" }
        if state.away { return "你离开啦…（不掉血，也别玩太久）" }
        let m = Int(state.consecutiveSittingMinutes)
        if state.deepSitting { return "⚠️ 深度久坐 ×2 · 已连续坐 \(m) 分钟" }
        return "已坐 \(m) 分钟 · 坐满 45 分钟掉血 ×2"
    }

    var sittingColor: Color {
        if state.inBreak { return Color(red: 0.25, green: 0.65, blue: 0.42) }
        if state.deepSitting { return Color(red: 0.89, green: 0.34, blue: 0.30) }
        return Color(red: 0.52, green: 0.60, blue: 0.68)
    }
}

// MARK: - 统计窗

struct StatsView: View {
    @ObservedObject var state: GameState

    var body: some View {
        let today = state.today
        let days = Self.last7Days

        VStack(alignment: .leading, spacing: 10) {
            Text("\(state.animal.emoji) \(state.animal.name)监工 · 统计")
                .font(.system(size: 15, weight: .bold, design: .rounded))

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    tile("久坐", Self.fmt(today.sittingMinutes) + " 分")
                    tile("深度久坐", Self.fmt(today.deepMinutes) + " 分")
                    tile("真休息", "\(today.genuineBreaks) 次")
                }
                HStack(spacing: 8) {
                    tile("被抓包", "\(today.caughtBreaks) 次")
                    tile("HP 区间", "\(Int(today.minHP))~\(Int(today.maxHP))")
                    tile("免费住院", today.hospitalized ? "已用" : "未用")
                }
            }

            Divider()

            Text("最近 7 天")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)

            HStack(spacing: 0) {
                Text("日期").frame(width: 76, alignment: .leading)
                Text("久坐(分)").frame(width: 70, alignment: .trailing)
                Text("深度(分)").frame(width: 70, alignment: .trailing)
                Text("休息").frame(width: 44, alignment: .trailing)
                Text("抓包").frame(width: 44, alignment: .trailing)
                Text("最低HP").frame(width: 60, alignment: .trailing)
                Spacer()
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(.secondary)

            ForEach(days, id: \.self) { key in
                let ds = state.daily[key] ?? DailyStats()
                HStack(spacing: 0) {
                    Text(Self.dayLabel(key)).frame(width: 76, alignment: .leading)
                    Text(Self.fmt(ds.sittingMinutes)).frame(width: 70, alignment: .trailing)
                    Text(Self.fmt(ds.deepMinutes)).frame(width: 70, alignment: .trailing)
                    Text("\(ds.genuineBreaks)").frame(width: 44, alignment: .trailing)
                    Text("\(ds.caughtBreaks)").frame(width: 44, alignment: .trailing)
                    Text(ds.sittingMinutes > 0 ? "\(Int(ds.minHP))" : "—")
                        .frame(width: 60, alignment: .trailing)
                    Spacer()
                }
                .font(.system(size: 11, design: .rounded))
                .padding(.vertical, 3)
                if key != days.first { Divider() }
            }

            Spacer(minLength: 4)

            Text("规则：坐着每分钟 −2 HP；连续坐满 45 分钟衰减 ×2。点「起来休息」，监工出门溜达、回血 +20/分，回满即休息成功；休息时动鼠标/键盘会被抓包（回血只算 30%、再 −5 HP，监工生气 30 秒）。离开电脑超过 10 分钟不掉血也不回血；每天可免费住院一次直接回满。菜单栏「换宠物」可在鹈鹕与十二生肖之间切换。")
                .font(.system(size: 10.5, design: .rounded))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 440, height: 480, alignment: .top)
        .background(Color.white.opacity(0.97))
    }

    func tile(_ k: String, _ v: String) -> some View {
        VStack(spacing: 3) {
            Text(k)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            Text(v)
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(red: 0.96, green: 0.975, blue: 0.99)))
    }

    static var last7Days: [String] {
        let cal = Calendar.current
        let today = Date()
        var out: [String] = []
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        for i in 0..<7 {
            if let d = cal.date(byAdding: .day, value: -i, to: today) {
                out.append(df.string(from: d))
            }
        }
        return out
    }

    static func dayLabel(_ key: String) -> String {
        if key == GameState.key(for: Date()) { return "今天" }
        let parts = key.split(separator: "-")
        guard parts.count == 3, let m = Int(parts[1]), let d = Int(parts[2]) else { return key }
        return "\(m)/\(d)"
    }

    static func fmt(_ v: Double) -> String {
        v >= 10 ? String(Int(v.rounded())) : String(format: "%.1f", v)
    }
}
