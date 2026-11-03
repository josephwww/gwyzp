import AppKit
import CoreGraphics
import ImageIO
import PhotoCore
import UniformTypeIdentifiers
import Vision

@MainActor
final class PhotoToolModel: ObservableObject {
    @Published var previewImage: NSImage?
    @Published var statusMessage = ""
    @Published var statusIsError = false
    @Published var canSave = false
    @Published var showSavedAlert = false

    private var sourceImage: CGImage?
    private var faceBox: NormalizedFaceBox?

    // MARK: - 打开照片

    func openPhoto() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.jpeg]
        panel.message = "请选择本人近期免冠正面电子证件照片（蓝底或白底，宽≥295、高≥413像素）"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        openPhoto(at: url)
    }

    func openPhoto(at url: URL) {
        canSave = false
        previewImage = nil
        faceBox = nil

        // 1. 格式：JPG/JPEG（扩展名 + 文件头 JPEG 魔数 FF D8 双重校验）
        guard FormatCheck.isJPEGFileExtension(url.pathExtension) else {
            reject(PhotoMessages.notJPEG)
            return
        }
        guard let header = try? Data(contentsOf: url, options: .mappedIfSafe).prefix(2),
              header == Data([0xFF, 0xD8])
        else {
            reject(PhotoMessages.notJPEG)
            return
        }
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(
                source, 0, [kCGImageSourceShouldCache: false] as CFDictionary)
        else {
            reject(PhotoMessages.notJPEG)
            return
        }

        // 2. 像素：宽 ≥295、高 ≥413（不放大低像素照片）
        guard PixelCheck.isValid(width: Double(image.width), height: Double(image.height)) else {
            reject(PhotoMessages.lowPixels)
            return
        }

        // 3. 正面人像：Vision 人脸检测，恰好一张脸
        let faces = FaceDetection.detectFaces(in: image)
        guard faces.count == 1, let face = faces.first else {
            reject(PhotoMessages.notPortrait)
            return
        }

        // 4. 头部比例：换算到 Haar 等效口径后校验 photo.ini 的 s_min/s_max
        let haarArea = face.area * PhotoConfig.haarEquivalentAreaScale
        guard HeadProportion.isValid(faceAreaFraction: haarArea) else {
            reject(PhotoMessages.headProportion)
            return
        }

        // 5. 亮度：人脸区域平均亮度落在 i_min/i_max
        let faceRect = pixelRect(for: face, in: image)
        if let luminance = FaceLuminance.mean(of: image, faceBoxPixel: faceRect) {
            guard IntensityCheck.isValid(meanLuminance: luminance) else {
                reject(PhotoMessages.notPortrait)
                return
            }
        }

        // 6. 背景：边框环多数判定为白色或蓝色
        if let sampler = PixelSampler(image: image, width: 64, height: 88) {
            let samples = sampler.borderRingSamples(bandFraction: 0.06).map { HSLConvert.hsl(from: $0) }
            let background = BackgroundClassifier.classifyBorder(samples: samples)
            guard background == .white || background == .blue else {
                reject(PhotoMessages.background)
                return
            }
        }

        sourceImage = image
        faceBox = face
        previewImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        canSave = true
        statusIsError = false
        statusMessage = "照片符合要求，可以保存。"
    }

    // MARK: - 保存照片

    func savePhoto() {
        guard let image = sourceImage, let face = faceBox else { return }
        let crop = CropMath.cropRect(
            imageWidth: Double(image.width), imageHeight: Double(image.height), face: face)
        let cropRect = CGRect(
            x: CGFloat(crop.x), y: CGFloat(crop.y),
            width: CGFloat(crop.width), height: CGFloat(crop.height)
        ).integral.intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard
            cropRect.width > 0, cropRect.height > 0,
            let cropped = image.cropping(to: cropRect),
            let resized = ImageResizer.resize(
                cropped,
                to: CGSize(width: PhotoConfig.outputWidthPixels, height: PhotoConfig.outputHeightPixels)),
            let encoded = JPEGEncoder.encodeWithinBudget(resized, targetBytes: PhotoConfig.targetJPEGBytes)
        else {
            reject("保存照片文件失败，请重试。")
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.jpeg]
        panel.nameFieldStringValue = PhotoConfig.outputFileName
        panel.title = PhotoMessages.saveTitle
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try encoded.data.write(to: url)
        } catch {
            reject("写入文件失败：\(error.localizedDescription)")
            return
        }
        canSave = false
        statusIsError = false
        statusMessage =
            "已保存 \(url.lastPathComponent)（\(Int(PhotoConfig.outputWidthPixels))×\(Int(PhotoConfig.outputHeightPixels))，\(encoded.data.count) 字节，质量 \(String(format: "%.2f", encoded.quality))）"
        showSavedAlert = true
    }

    // MARK: - 私有

    private func reject(_ message: String) {
        statusIsError = true
        statusMessage = message
    }

    /// Vision 归一化（原点左下）→ CGImage 像素坐标（原点左上）。
    private func pixelRect(for face: NormalizedFaceBox, in image: CGImage) -> CGRect {
        let w = Double(image.width)
        let h = Double(image.height)
        return CGRect(
            x: CGFloat(face.x * w),
            y: CGFloat((1 - face.y - face.height) * h),
            width: CGFloat(face.width * w),
            height: CGFloat(face.height * h)
        )
    }
}

// MARK: - Vision 人脸检测

enum FaceDetection {
    /// 返回按面积从大到小排列的人脸框（归一化、原点左下）。
    static func detectFaces(in image: CGImage) -> [NormalizedFaceBox] {
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return []
        }
        let results = request.results
        return results
            .map {
                NormalizedFaceBox(
                    x: Double($0.boundingBox.minX),
                    y: Double($0.boundingBox.minY),
                    width: Double($0.boundingBox.width),
                    height: Double($0.boundingBox.height))
            }
            .sorted { $0.area > $1.area }
    }
}

// MARK: - 像素采样

/// 把图像绘制到小尺寸 RGBA 缓冲区做采样分析。
struct PixelSampler {
    let context: CGContext
    let width: Int
    let height: Int

    init?(image: CGImage, width: Int, height: Int) {
        guard
            let ctx = CGContext(
                data: nil, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        context = ctx
        self.width = width
        self.height = height
    }

    func rgba(x: Int, y: Int) -> PhotoCore.RGBColor {
        let pixels = context.data!.assumingMemoryBound(to: UInt8.self)
        let idx = (y * width + x) * 4
        return PhotoCore.RGBColor(
            r: Double(pixels[idx]) / 255.0,
            g: Double(pixels[idx + 1]) / 255.0,
            b: Double(pixels[idx + 2]) / 255.0)
    }

    /// 边框环采样：四周各取 bandFraction 宽的环形区域。
    func borderRingSamples(bandFraction: Double) -> [PhotoCore.RGBColor] {
        let bw = max(1, Int((Double(width) * bandFraction).rounded()))
        let bh = max(1, Int((Double(height) * bandFraction).rounded()))
        var samples: [PhotoCore.RGBColor] = []
        for x in 0..<width {
            for y in 0..<bh {
                samples.append(rgba(x: x, y: y))
                samples.append(rgba(x: x, y: height - 1 - y))
            }
        }
        if height > 2 * bh {
            for y in bh..<(height - bh) {
                for x in 0..<bw {
                    samples.append(rgba(x: x, y: y))
                    samples.append(rgba(x: width - 1 - x, y: y))
                }
            }
        }
        return samples
    }
}

// MARK: - 人脸亮度

enum FaceLuminance {
    /// 人脸区域平均亮度（0...1）。
    static func mean(of image: CGImage, faceBoxPixel: CGRect) -> Double? {
        let w = 32
        let h = 32
        guard
            faceBoxPixel.width > 0, faceBoxPixel.height > 0,
            let cropped = image.cropping(to: faceBoxPixel.integral),
            let ctx = CGContext(
                data: nil, width: w, height: h,
                bitsPerComponent: 8, bytesPerRow: w,
                space: CGColorSpace(name: CGColorSpace.genericGrayGamma2_2)!,
                bitmapInfo: CGImageAlphaInfo.none.rawValue)
        else { return nil }
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: w, height: h))
        let pixels = ctx.data!.assumingMemoryBound(to: UInt8.self)
        var sum = 0
        for i in 0..<(w * h) { sum += Int(pixels[i]) }
        return Double(sum) / Double(w * h) / 255.0
    }
}

// MARK: - 缩放与编码

enum ImageResizer {
    static func resize(_ image: CGImage, to size: CGSize) -> CGImage? {
        guard
            let ctx = CGContext(
                data: nil, width: Int(size.width), height: Int(size.height),
                bitsPerComponent: 8, bytesPerRow: Int(size.width) * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(origin: .zero, size: size))
        return ctx.makeImage()
    }
}

enum JPEGEncoder {
    static func encode(_ image: CGImage, quality: Double) -> Data? {
        let data = NSMutableData()
        guard
            let dest = CGImageDestinationCreateWithData(
                data, UTType.jpeg.identifier as CFString, 1, nil)
        else { return nil }
        CGImageDestinationAddImage(
            dest, image,
            [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }

    /// 二分搜索不超过 targetBytes 的最大质量（对应说明书"保存后的照片大小在10K左右"）。
    static func encodeWithinBudget(_ image: CGImage, targetBytes: Int) -> (data: Data, quality: Double)? {
        let lo = 0.05
        var low = lo
        var high = 1.0
        guard var best = encode(image, quality: lo) else { return nil }
        var bestQuality = lo
        for _ in 0..<8 {
            let mid = (low + high) / 2
            guard let data = encode(image, quality: mid) else { break }
            if data.count <= targetBytes {
                best = data
                bestQuality = mid
                low = mid
            } else {
                high = mid
            }
        }
        return (best, bestQuality)
    }
}
