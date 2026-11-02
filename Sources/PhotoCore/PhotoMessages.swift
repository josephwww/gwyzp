/// 原版程序内嵌的完整校验文案（从 exe 的 .data 段逐字恢复）。
public enum PhotoMessages {
    /// 人脸检测失败 / 非正面人像（含亮度不合格）。
    public static let notPortrait = "打开照片文件不符合要求。请选择正面人像标准证件照片文件。"
    /// 头部比例不合格（photo.ini s_min/s_max）。
    public static let headProportion = "打开照片文件人像头部比例不符合要求。请选择头部比例适当的照片文件。"
    /// 背景非白/蓝。
    public static let background = "打开照片文件背景不符合要求。请选择白色或蓝色背景照片文件。"
    /// 像素数低于要求。
    public static let lowPixels = "打开照片文件像素数低。请选择高于或符合像素数要求的照片文件。"
    /// 非 JPG/JPEG 格式。
    public static let notJPEG = "打开照片文件类型不是JPG/JPEG格式，请选择JPG/JPEG格式照片文件。"
    /// 保存成功后的询问。
    public static let savedAskExit = "照片已保存成功，是否退出"
    /// 保存对话框标题。
    public static let saveTitle = "保存照片"
}
