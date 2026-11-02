import PhotoCore
import SwiftUI

struct ContentView: View {
    @StateObject private var model = PhotoToolModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            photoArea
            Divider()
            controls
        }
        .frame(minWidth: 720, minHeight: 540)
        .alert(PhotoMessages.saveTitle, isPresented: $model.showSavedAlert) {
            Button("退出") {
                NSApp.terminate(nil)
            }
            Button("继续使用", role: .cancel) {}
        } message: {
            Text(PhotoMessages.savedAskExit)
        }
    }

    /// 复刻原版 interface00.bmp 的红色标题栏（#DD3A3E）。
    private var header: some View {
        ZStack {
            Rectangle().fill(Color(red: 0.867, green: 0.227, blue: 0.243))
            HStack {
                Text("照片处理工具")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text("报名照片处理工具")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 64)
    }

    private var photoArea: some View {
        Group {
            if let image = model.previewImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(16)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.rectangle")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("照片显示区域")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Text(model.statusMessage)
                .foregroundStyle(model.statusIsError ? Color.red : Color.green)
                .frame(maxWidth: .infinity, minHeight: 18)
            HStack(spacing: 24) {
                Button("打开照片文件") {
                    model.openPhoto()
                }
                .buttonStyle(.borderedProminent)
                Button("保存照片文件") {
                    model.savePhoto()
                }
                .buttonStyle(.bordered)
                .disabled(!model.canSave)
            }
        }
        .padding(20)
    }
}
