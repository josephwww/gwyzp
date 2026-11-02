/// 与原版 `photo.ini` `[PhotoInfo]` 节等价的阈值与规格参数。
///
/// 原文件内容：`s_min=0.05  s_max=0.1  i_min=0.1  i_max=0.7`
public enum PhotoConfig {
    /// 人脸框面积占整幅画面比例下限（原 s_min）。
    public static let faceAreaMin = 0.05
    /// 人脸框面积占整幅画面比例上限（原 s_max）。
    public static let faceAreaMax = 0.10
    /// 亮度有效下限（原 i_min）。
    public static let intensityMin = 0.1
    /// 亮度有效上限（原 i_max）。
    public static let intensityMax = 0.7

    /// 输入照片最小宽度（像素）。
    public static let minWidthPixels = 295.0
    /// 输入照片最小高度（像素）。
    public static let minHeightPixels = 413.0

    /// 输出宽度（一寸证件照 300dpi）。
    public static let outputWidthPixels = 295.0
    /// 输出高度（一寸证件照 300dpi）。
    public static let outputHeightPixels = 413.0
    /// 输出 JPEG 目标体积上限（约 10KB，对应说明书"保存后的照片大小在10K左右"）。
    public static let targetJPEGBytes = 10_240

    /// 裁剪后人脸高度占画面高度的目标比例（证件照构图惯例，原版 ROI 逻辑的等价实现）。
    public static let headHeightFractionOfFrame = 0.62
    /// 人脸中心距裁剪框顶部的目标比例。
    public static let faceCenterYFractionOfFrame = 0.42

    /// 输出裁剪宽高比。
    public static let aspectWidth = 295.0
    public static let aspectHeight = 413.0

    /// Vision 人脸框比原版 OpenCV Haar 框更贴合（约小 15% 线性 / 28% 面积）；
    /// 乘以该系数将 Vision 面积换算到 Haar 等效面积，保持与原版阈值同一口径。
    public static let haarEquivalentAreaScale = 1.4

    /// 输出默认文件名（原版行为）。
    public static let outputFileName = "报名照片.JPG"
}
