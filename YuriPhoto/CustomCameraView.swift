import SwiftUI
import AVFoundation

struct CustomCameraView: UIViewRepresentable {
    class CameraUIView: UIView, AVCapturePhotoCaptureDelegate {
        private var captureSession: AVCaptureSession?
        private let photoOutput = AVCapturePhotoOutput()
        private var captureButton: UIButton?
        private var capturedImage: UIImage?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            initializeSession()
            setupCaptureButton()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupCaptureButton() {
            // 撮影ボタンを初期化して追加
            captureButton = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
            if let captureButton = captureButton {
                captureButton.backgroundColor = .white
                captureButton.layer.cornerRadius = 35
                captureButton.setTitle("撮影", for: .normal)
                captureButton.setTitleColor(.black, for: .normal)
                captureButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
                self.addSubview(captureButton)
            }
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            captureButton?.center = CGPoint(x: self.bounds.midX, y: self.bounds.height - 100)
            self.bringSubviewToFront(captureButton!)
        }
        
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
                
                let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                previewLayer.frame = self.bounds
                previewLayer.videoGravity = .resizeAspectFill
                self.layer.addSublayer(previewLayer)
                
                session.startRunning()
            }
        }
        
        @objc func takePhoto() {
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let imageData = photo.fileDataRepresentation() else { return }
            self.capturedImage = UIImage(data: imageData)
            
            // 撮影後はボタンのタイトルを「ダウンロード」に変更
            DispatchQueue.main.async {
                self.captureButton?.setTitle("ダウンロード", for: .normal)
                self.captureButton?.removeTarget(self, action: #selector(self.takePhoto), for: .touchUpInside)
                self.captureButton?.addTarget(self, action: #selector(self.savePhoto), for: .touchUpInside)
            }
        }
        
        @objc func savePhoto() {
            guard let imageToSave = capturedImage else { return }
            UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
            
            // 保存後はボタンを非表示にするか、必要に応じてさらなる処理を行う
            DispatchQueue.main.async {
                self.captureButton?.setTitle("撮影", for: .normal)
                self.captureButton?.removeTarget(self, action: #selector(self.savePhoto), for: .touchUpInside)
                self.captureButton?.addTarget(self, action: #selector(self.takePhoto), for: .touchUpInside)
            }
        }
    }
    
    func makeUIView(context: Context) -> CameraUIView {
        return CameraUIView()
    }
    
    func updateUIView(_ uiView: CameraUIView, context: Context) {}
}
