import AppKit

// 鹈鹕监工 · Pelican Nanny
// 菜单栏常驻的久坐监工小窗：坐着掉血，起来休息回血，偷摸用电脑被抓包。

let app = NSApplication.shared
let controller = PanelController()
app.delegate = controller
app.setActivationPolicy(.accessory)
app.run()
