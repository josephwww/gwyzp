public enum FormatCheck {
    /// 原版按文件扩展名校验 JPG/JPEG。
    public static func isJPEGFileExtension(_ pathExtension: String) -> Bool {
        let e = pathExtension.lowercased()
        return e == "jpg" || e == "jpeg"
    }

    /// ImageIO 的 JPEG 类型标识，用于扩展名之外的实际内容校验。
    public static let jpegTypeIdentifier = "public.jpeg"
}

public enum PixelCheck {
    /// 宽 ≥295 且 高 ≥413（一寸证件照 300dpi；同时阻止放大低像素照片使用）。
    public static func isValid(width: Double, height: Double) -> Bool {
        width >= PhotoConfig.minWidthPixels && height >= PhotoConfig.minHeightPixels
    }
}

public enum HeadProportion {
    /// faceAreaFraction：人脸框面积占整幅画面比例（photo.ini s_min/s_max 语义，
    /// 调用方需先用 `PhotoConfig.haarEquivalentAreaScale` 换算到 Haar 等效口径）。
    public static func isValid(faceAreaFraction: Double) -> Bool {
        (PhotoConfig.faceAreaMin...PhotoConfig.faceAreaMax).contains(faceAreaFraction)
    }
}

public enum IntensityCheck {
    /// meanLuminance：人脸区域平均亮度 0...1（photo.ini i_min/i_max 语义）。
    public static func isValid(meanLuminance: Double) -> Bool {
        (PhotoConfig.intensityMin...PhotoConfig.intensityMax).contains(meanLuminance)
    }
}
