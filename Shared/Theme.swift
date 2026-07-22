import SwiftUI

/// 取自 iplayground.io/2026 官網的固定深色配色（亮黃 × 黑 × 日系科技感）。
enum Theme {
    static let accent = Color(hex: 0xD2FF00)   // 亮黃：強調、當前任務、按鈕
    static let bg = Color(hex: 0x000000)       // 全域背景
    static let surface = Color(hex: 0x14160F)  // 卡片
    static let surface2 = Color(hex: 0x282C20) // 次卡片 / 分隔
    static let ink = Color(hex: 0xF2F3EE)      // 主文字（近白）
    static let ink2 = Color(hex: 0xBFC2B8)     // 次要文字
    static let ink3 = Color(hex: 0x888B7F)     // 更弱文字
    static let rule = Color.white.opacity(0.14) // 細格線
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

extension Font {
    /// 等寬字型（日系科技感的數字與標籤）。
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
