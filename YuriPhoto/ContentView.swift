import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isCameraReady = false  // カメラの準備状態を追跡
    
    var body: some View {
        ZStack {
            if isCameraReady {
                CustomCameraView()
                    .edgesIgnoringSafeArea(.all)
            } else {
                ProgressView("Loading...")
                    .scaleEffect(1.5)  // ローディングアイコンを少し大きく表示
                    .onAppear {
                        initializeCamera()
                    }
            }
        }
    }

    // カメラ初期化のシミュレーション
    private func initializeCamera() {
        // ここでカメラの初期化処理を模倣（実際のプロジェクトではCustomCameraViewの初期化完了を待つ）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {  // 2秒後に完了とする
            isCameraReady = true  // カメラの準備完了
        }
    }
}

// SwiftUIでUIViewを使えるようにするための構造体
// https://developer.apple.com/documentation/swiftui/uiviewrepresentable
// SwiftUIでUIViewを使えるようにするための構造体
struct CustomCameraView: UIViewRepresentable {
    func makeUIView(context: Context) -> CameraUIView {
        CameraUIView()
    }
    
    func updateUIView(_ uiView: CameraUIView, context: Context) {}
}
