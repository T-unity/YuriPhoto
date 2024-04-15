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
struct CustomCameraView: UIViewRepresentable {
    // UIViewを継承したカスタムビュークラス。カメラ機能を実装しています。
    class CameraUIView: UIView, AVCapturePhotoCaptureDelegate {
        private var captureSession: AVCaptureSession?  // カメラのセッションを管理
        private let photoOutput = AVCapturePhotoOutput()  // 写真の出力を管理
        private var captureButton: UIButton?  // 撮影ボタン
        private var capturedImage: UIImage?  // 撮影した画像を保持
        private var imageView: UIImageView?  // 撮影した画像を表示するためのビュー
        private var previewLayer: AVCaptureVideoPreviewLayer?  // カメラからの映像を表示するレイヤー
        
        // 初期化処理
        override init(frame: CGRect) {
            super.init(frame: frame)
            initializeSession()  // カメラセッションの初期化
            setupCaptureButton()  // 撮影ボタンの設定
            setupImageView()  // imageViewの設定
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // imageViewの設定
        private func setupImageView() {
            imageView = UIImageView(frame: self.bounds)
            imageView?.contentMode = .scaleAspectFit
            imageView?.isHidden = true
            if let imageView = imageView {
                self.addSubview(imageView)
                //                print("ImageView added")  // デバッグ情報
            }
        }
        
        // 撮影ボタンの設定
        private func setupCaptureButton() {
            captureButton = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
            if let captureButton = captureButton {
                captureButton.backgroundColor = .white
                captureButton.layer.cornerRadius = 35
                captureButton.setTitle("撮影", for: .normal)
                captureButton.setTitleColor(.black, for: .normal)
                captureButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
                self.addSubview(captureButton)
                self.bringSubviewToFront(captureButton)
            }
        }
        
        // レイアウト調整時の処理
        override func layoutSubviews() {
            super.layoutSubviews()
            
            // カメラセッションの初期化をビューが表示される直前に行う
            if self.captureSession == nil {
                initializeSession()
            }
            
            imageView?.frame = self.bounds  // imageViewのフレームを更新
            captureButton?.center = CGPoint(x: self.bounds.midX, y: self.bounds.height - 100)
            self.bringSubviewToFront(captureButton!)
        }
        
        
        // カメラセッションの初期化
        private func initializeSession() {
            DispatchQueue.main.async {
                self.captureSession = AVCaptureSession()
                guard let session = self.captureSession, let backCamera = AVCaptureDevice.default(for: .video),
                      let input = try? AVCaptureDeviceInput(device: backCamera) else {
                    return
                }
                
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                if session.canAddOutput(self.photoOutput) {
                    session.addOutput(self.photoOutput)
                }
                
                self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
                guard let previewLayer = self.previewLayer else { return }
                
                previewLayer.frame = self.bounds
                previewLayer.videoGravity = .resizeAspectFill
                DispatchQueue.main.async {
                    self.layer.addSublayer(previewLayer)
                }
                
                session.startRunning()
            }
        }
        
        @objc func takePhoto() {
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
        
        // 写真が撮影された後の処理
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else { return }
            self.capturedImage = image
            
            DispatchQueue.main.async {
                self.imageView?.image = image
                self.imageView?.isHidden = false
                self.bringSubviewToFront(self.imageView!)
                //                print("Image should be visible now")  // デバッグ情報
                self.previewLayer?.isHidden = true
                self.captureButton?.setTitle("ダウンロード", for: .normal)
                self.captureButton?.removeTarget(self, action: #selector(self.takePhoto), for: .touchUpInside)
                self.captureButton?.addTarget(self, action: #selector(self.savePhoto), for: .touchUpInside)
            }
        }
        
        // 撮影ボタンが押された時のアクション
        @objc func retakePhoto() {
            DispatchQueue.main.async {
                self.imageView?.isHidden = true
                self.previewLayer?.isHidden = false
                self.captureSession?.startRunning()
                self.captureButton?.setTitle("撮影", for: .normal)
                self.captureButton?.removeTarget(self, action: #selector(self.retakePhoto), for: .touchUpInside)
                self.captureButton?.addTarget(self, action: #selector(self.takePhoto), for: .touchUpInside)
            }
        }
        
        @objc func hideImage() {
            DispatchQueue.main.async {
                // 画像を非表示にし、ボタンを再撮影用に設定
                self.imageView?.isHidden = true
                self.captureButton?.setTitle("撮影", for: .normal)
                self.captureButton?.removeTarget(self, action: #selector(self.hideImage), for: .touchUpInside)
                self.captureButton?.addTarget(self, action: #selector(self.takePhoto), for: .touchUpInside)
            }
        }
        
        // 「ダウンロード」ボタンが押された時のアクション
        @objc func savePhoto() {
            guard let imageToSave = capturedImage else { return }
            // 撮影した画像をフォトライブラリに保存する
            UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
            
            DispatchQueue.main.async {
                // 画像を非表示にし、カメラプレビューを再表示する
                self.imageView?.isHidden = true
                self.previewLayer?.isHidden = false
                // カメラセッションを再開する
                self.captureSession?.startRunning()
                // ボタンのタイトルを「撮影」に戻し、アクションを撮影に設定する
                self.captureButton?.setTitle("撮影", for: .normal)
                self.captureButton?.removeTarget(self, action: #selector(self.savePhoto), for: .touchUpInside)
                self.captureButton?.addTarget(self, action: #selector(self.takePhoto), for: .touchUpInside)
            }
        }
    }
    
    // UIViewRepresentableプロトコルのメソッド。UIViewを生成して返す。
    func makeUIView(context: Context) -> CameraUIView {
        return CameraUIView()
    }
    
    // UIViewRepresentableプロトコルのメソッド。UIViewの状態を更新する。
    func updateUIView(_ uiView: CameraUIView, context: Context) {}
}
