import SwiftUI

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
