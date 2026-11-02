import XCTest
@testable import PhotoCore

final class PhotoCoreTests: XCTestCase {
    func testHSLPrimaryColors() {
        let red = HSLConvert.hsl(from: RGBColor(r: 1, g: 0, b: 0))
        XCTAssertEqual(red.h, 0, accuracy: 0.001)
        XCTAssertEqual(red.s, 1, accuracy: 0.001)
        XCTAssertEqual(red.l, 0.5, accuracy: 0.001)

        let blue = HSLConvert.hsl(from: RGBColor(r: 0, g: 0, b: 1))
        XCTAssertEqual(blue.h, 240, accuracy: 0.001)

        let white = HSLConvert.hsl(from: RGBColor(r: 1, g: 1, b: 1))
        XCTAssertEqual(white.s, 0, accuracy: 0.001)
        XCTAssertEqual(white.l, 1, accuracy: 0.001)

        let gray = HSLConvert.hsl(from: RGBColor(r: 0.5, g: 0.5, b: 0.5))
        XCTAssertEqual(gray.s, 0, accuracy: 0.001)
        XCTAssertEqual(gray.l, 0.5, accuracy: 0.001)
    }

    func testBackgroundClassifySingleSamples() {
        XCTAssertEqual(BackgroundClassifier.classify(sample: HSLColor(h: 0, s: 0.02, l: 0.95)), .white)
        XCTAssertEqual(BackgroundClassifier.classify(sample: HSLColor(h: 220, s: 0.55, l: 0.45)), .blue)
        XCTAssertEqual(BackgroundClassifier.classify(sample: HSLColor(h: 205, s: 0.35, l: 0.80)), .blue, "浅蓝也按蓝底通过")
        XCTAssertEqual(BackgroundClassifier.classify(sample: HSLColor(h: 120, s: 0.5, l: 0.4)), .other)
        XCTAssertEqual(BackgroundClassifier.classify(sample: HSLColor(h: 30, s: 0.6, l: 0.5)), .other, "红底不通过")
    }

    func testBackgroundMajorityVote() {
        let whites = Array(repeating: HSLColor(h: 0, s: 0.05, l: 0.9), count: 8)
        let others = Array(repeating: HSLColor(h: 120, s: 0.5, l: 0.4), count: 2)
        XCTAssertEqual(BackgroundClassifier.classifyBorder(samples: whites + others), .white)
        XCTAssertEqual(BackgroundClassifier.classifyBorder(samples: others), .other)

        let blues = Array(repeating: HSLColor(h: 210, s: 0.6, l: 0.5), count: 10)
        XCTAssertEqual(BackgroundClassifier.classifyBorder(samples: blues), .blue)

        let mixed = Array(repeating: HSLColor(h: 0, s: 0.05, l: 0.9), count: 5)
            + Array(repeating: HSLColor(h: 210, s: 0.6, l: 0.5), count: 5)
        XCTAssertEqual(BackgroundClassifier.classifyBorder(samples: mixed), .other)
    }

    func testHeadProportionBounds() {
        XCTAssertFalse(HeadProportion.isValid(faceAreaFraction: 0.049))
        XCTAssertTrue(HeadProportion.isValid(faceAreaFraction: 0.05))
        XCTAssertTrue(HeadProportion.isValid(faceAreaFraction: 0.10))
        XCTAssertFalse(HeadProportion.isValid(faceAreaFraction: 0.101))
    }

    func testIntensityBounds() {
        XCTAssertFalse(IntensityCheck.isValid(meanLuminance: 0.09))
        XCTAssertTrue(IntensityCheck.isValid(meanLuminance: 0.5))
        XCTAssertFalse(IntensityCheck.isValid(meanLuminance: 0.75))
    }

    func testFormatCheck() {
        XCTAssertTrue(FormatCheck.isJPEGFileExtension("jpg"))
        XCTAssertTrue(FormatCheck.isJPEGFileExtension("JPEG"))
        XCTAssertTrue(FormatCheck.isJPEGFileExtension("jpeg"))
        XCTAssertFalse(FormatCheck.isJPEGFileExtension("png"))
        XCTAssertFalse(FormatCheck.isJPEGFileExtension(""))
    }

    func testPixelCheck() {
        XCTAssertFalse(PixelCheck.isValid(width: 294, height: 413))
        XCTAssertFalse(PixelCheck.isValid(width: 295, height: 412))
        XCTAssertTrue(PixelCheck.isValid(width: 295, height: 413))
        XCTAssertTrue(PixelCheck.isValid(width: 1000, height: 1400))
    }

    func testCropRectAspectAndContainment() {
        // 1000x1400 图，人脸面积 6.25%（换算前）
        let face = NormalizedFaceBox(x: 0.35, y: 0.45, width: 0.25, height: 0.25)
        let r = CropMath.cropRect(imageWidth: 1000, imageHeight: 1400, face: face)
        XCTAssertEqual(r.width / r.height, PhotoConfig.aspectWidth / PhotoConfig.aspectHeight, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(r.x, 0)
        XCTAssertLessThanOrEqual(r.x + r.width, 1000)
        XCTAssertGreaterThanOrEqual(r.y, 0)
        XCTAssertLessThanOrEqual(r.y + r.height, 1400)
    }

    func testCropRectClampedToImage() {
        // 人脸贴左上角，裁剪框必须被拉回画面内且保持比例
        let face = NormalizedFaceBox(x: 0.0, y: 0.75, width: 0.224, height: 0.224)
        let r = CropMath.cropRect(imageWidth: 500, imageHeight: 700, face: face)
        XCTAssertGreaterThanOrEqual(r.x, -0.0001)
        XCTAssertGreaterThanOrEqual(r.y, -0.0001)
        XCTAssertLessThanOrEqual(r.x + r.width, 500.0001)
        XCTAssertLessThanOrEqual(r.y + r.height, 700.0001)
        XCTAssertEqual(r.width / r.height, PhotoConfig.aspectWidth / PhotoConfig.aspectHeight, accuracy: 0.001)
    }

    func testCropRectOversizedFaceShrinksProportionally() {
        // 裁剪宽超出画面宽度时按比例收缩（380 < 所需 387px 宽）
        let face = NormalizedFaceBox(x: 0.3, y: 0.3, width: 0.6, height: 0.6)
        let r = CropMath.cropRect(imageWidth: 380, imageHeight: 560, face: face)
        XCTAssertLessThanOrEqual(r.width, 380.0001)
        XCTAssertLessThanOrEqual(r.height, 560.0001)
        XCTAssertEqual(r.width / r.height, PhotoConfig.aspectWidth / PhotoConfig.aspectHeight, accuracy: 0.001)
    }
}
