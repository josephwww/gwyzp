import PhotoCore
import SwiftUI

/// 原版 interface00.bmp 皮肤（701×488）的实测区域坐标。
private enum SkinLayout {
    static let windowWidth: CGFloat = 701
    static let windowHeight: CGFloat = 488
    /// 照片显示区（皮肤上自带样例人像，载入合格照片后覆盖显示）。
    static let displayRect = CGRect(x: 112, y: 172, width: 214, height: 272)
    /// 右侧三个按钮位（皮肤从上到下：绿 / 红 / 金，图内已烙有原版文字）。
    static let buttonWidth: CGFloat = 200
    static let buttonHeight: CGFloat = 66
    static let buttonCenterX: CGFloat = 473
    static let greenY: CGFloat = 216
    static let redY: CGFloat = 304
    static let goldY: CGFloat = 392
    /// 顶部红带内的标题与说明行位置。
    static let titlePosition = CGPoint(x: 110, y: 32)
    static let captionPosition = CGPoint(x: 252, y: 158)
}

private enum SkinAssets {
    private static func load(_ name: String) -> NSImage {
        let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Resources")
            ?? Bundle.module.url(forResource: name, withExtension: "png")
        guard let url, let image = NSImage(contentsOf: url) else { return NSImage() }
        return image
    }

    static let skin = load("skin")
    static let open = load("button-green")
    static let exit = load("button-red")
    static let save = load("button-gold")
    static let saveDisabled = load("button-gray")
}

struct ContentView: View {
    @StateObject private var model = PhotoToolModel()

    var body: some View {
        ZStack {
            Image(nsImage: SkinAssets.skin)
                .resizable()
                .frame(width: SkinLayout.windowWidth, height: SkinLayout.windowHeight)

            Text("照片处理工具")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .position(SkinLayout.titlePosition)

            Text("请选择本人近期免冠正面证件照片（蓝底或白底，宽≥295、高≥413像素）")
                .font(.system(size: 12))
                .foregroundStyle(Color(white: 0.35))
                .position(SkinLayout.captionPosition)

            photoDisplay
            openButton
            saveButton
            exitButton
        }
        .frame(width: SkinLayout.windowWidth, height: SkinLayout.windowHeight)
        .alert(PhotoMessages.saveTitle, isPresented: $model.showSavedAlert) {
            Button("退出") {
                NSApp.terminate(nil)
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(PhotoMessages.savedAskExit)
        }
        .alert("照片处理工具", isPresented: $model.showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(model.errorMessage)
        }
    }

    /// 载入合格照片后覆盖皮肤上的样例人像。
    private var photoDisplay: some View {
        Group {
            if let image = model.previewImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.clear
            }
        }
        .frame(width: SkinLayout.displayRect.width, height: SkinLayout.displayRect.height)
        .clipped()
        .position(
            x: SkinLayout.displayRect.midX,
            y: SkinLayout.displayRect.midY)
    }

    private var openButton: some View {
        Button {
            model.openPhoto()
        } label: {
            Image(nsImage: SkinAssets.open)
                .resizable()
                .frame(width: SkinLayout.buttonWidth, height: SkinLayout.buttonHeight)
        }
        .buttonStyle(.plain)
        .position(x: SkinLayout.buttonCenterX, y: SkinLayout.greenY)
    }

    private var saveButton: some View {
        Button {
            model.savePhoto()
        } label: {
            Image(nsImage: model.canSave ? SkinAssets.save : SkinAssets.saveDisabled)
                .resizable()
                .frame(width: SkinLayout.buttonWidth, height: SkinLayout.buttonHeight)
        }
        .buttonStyle(.plain)
        .disabled(!model.canSave)
        .position(x: SkinLayout.buttonCenterX, y: SkinLayout.goldY)
    }

    private var exitButton: some View {
        Button {
            NSApp.terminate(nil)
        } label: {
            Image(nsImage: SkinAssets.exit)
                .resizable()
                .frame(width: SkinLayout.buttonWidth, height: SkinLayout.buttonHeight)
        }
        .buttonStyle(.plain)
        .position(x: SkinLayout.buttonCenterX, y: SkinLayout.redY)
    }
}
