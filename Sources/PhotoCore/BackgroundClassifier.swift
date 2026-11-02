/// 边框环背景分类：判断照片背景是白色、蓝色还是其他。
public enum BackgroundClass: Equatable {
    case white
    case blue
    case other
}

public enum BackgroundClassifier {
    public static let whiteMinLightness = 0.72
    public static let whiteMaxSaturation = 0.30
    public static let blueHueRangeMin = 190.0
    public static let blueHueRangeMax = 255.0
    public static let blueMinSaturation = 0.18
    /// 环上属于同一类别的样本占比达到该阈值才判定为该背景色。
    public static let requiredAgreement = 0.60

    public static func classify(sample: HSLColor) -> BackgroundClass {
        if sample.l >= whiteMinLightness && sample.s <= whiteMaxSaturation {
            return .white
        }
        if sample.h >= blueHueRangeMin && sample.h <= blueHueRangeMax && sample.s >= blueMinSaturation {
            return .blue
        }
        return .other
    }

    /// 对边框环采样点做多数判定。
    public static func classifyBorder(samples: [HSLColor]) -> BackgroundClass {
        guard !samples.isEmpty else { return .other }
        let whites = samples.filter { classify(sample: $0) == .white }.count
        let blues = samples.filter { classify(sample: $0) == .blue }.count
        let n = Double(samples.count)
        if Double(whites) / n >= requiredAgreement { return .white }
        if Double(blues) / n >= requiredAgreement { return .blue }
        return .other
    }
}
