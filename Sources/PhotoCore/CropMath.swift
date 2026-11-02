/// Vision 约定的人脸框：归一化坐标，原点左下。
public struct NormalizedFaceBox: Equatable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var area: Double { width * height }
}

/// 像素坐标裁剪框，原点左上。
public struct CropRect: Equatable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public enum CropMath {
    /// 依据人脸框计算证件照裁剪框：保持 `PhotoConfig.aspectWidth/aspectHeight` 比例，
    /// 人脸高度占裁剪高 `headHeightFractionOfFrame`，人脸中心位于顶部 `faceCenterYFractionOfFrame` 处，
    /// 越界时平移收缩进画面，比例不变。
    public static func cropRect(
        imageWidth: Double,
        imageHeight: Double,
        face: NormalizedFaceBox
    ) -> CropRect {
        let faceH = face.height * imageHeight
        let faceCx = (face.x + face.width / 2) * imageWidth
        let faceCyTopLeft = (1 - (face.y + face.height / 2)) * imageHeight

        var cropH = faceH / PhotoConfig.headHeightFractionOfFrame
        var cropW = cropH * PhotoConfig.aspectWidth / PhotoConfig.aspectHeight
        if cropW > imageWidth || cropH > imageHeight {
            let scale = min(imageWidth / cropW, imageHeight / cropH)
            cropW *= scale
            cropH *= scale
        }

        var x = faceCx - cropW / 2
        var y = faceCyTopLeft - PhotoConfig.faceCenterYFractionOfFrame * cropH
        x = min(max(x, 0), imageWidth - cropW)
        y = min(max(y, 0), imageHeight - cropH)
        return CropRect(x: x, y: y, width: cropW, height: cropH)
    }
}
