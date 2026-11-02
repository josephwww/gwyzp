/// RGB 颜色，各分量 0...1。
public struct RGBColor: Equatable {
    public let r: Double
    public let g: Double
    public let b: Double

    public init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }
}

/// HSL 颜色：h 为角度 0..<360，s/l 为 0...1。
public struct HSLColor: Equatable {
    public let h: Double
    public let s: Double
    public let l: Double

    public init(h: Double, s: Double, l: Double) {
        self.h = h
        self.s = s
        self.l = l
    }
}

public enum HSLConvert {
    public static func hsl(from c: RGBColor) -> HSLColor {
        let mx = max(c.r, max(c.g, c.b))
        let mn = min(c.r, min(c.g, c.b))
        let l = (mx + mn) / 2
        if mx == mn {
            return HSLColor(h: 0, s: 0, l: l)
        }
        let d = mx - mn
        let s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn)
        var h: Double
        if mx == c.r {
            h = (c.g - c.b) / d + (c.g < c.b ? 6 : 0)
        } else if mx == c.g {
            h = (c.b - c.r) / d + 2
        } else {
            h = (c.r - c.g) / d + 4
        }
        return HSLColor(h: h * 60, s: s, l: l)
    }
}
