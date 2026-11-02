import SwiftUI

@main
struct PhotoToolApp: App {
    var body: some Scene {
        WindowGroup("照片处理工具") {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
