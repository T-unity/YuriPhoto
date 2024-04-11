import SwiftUI
import AVFoundation

struct CustomCameraView: UIViewRepresentable {
    class CameraUIView: UIView, AVCapturePhotoCaptureDelegate {
        private var captureSession: AVCaptureSession?
        private let photoOutput = AVCapturePhotoOutput()
        private var captureButton: UIButton?
        private var capturedImage: UIImage?
        private var imageView: UIImageView?
        private var previewLayer: AVCaptureVideoPreviewLayer?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            initializeSession()
            setupCaptureButton()
            setupImageView()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupImageView() {
            imageView = UIImageView(frame: self.bounds)
            imageView?.contentMode = .scaleAspectFit
            imageView?.isHidden = true
            if let imageView = imageView {
                self.addSubview(imageView)
//                print("ImageView added")  // デバッグ情報
            }
        }

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
        
        override func layoutSubviews() {
            super.layoutSubviews()
            imageView?.frame = self.bounds  // imageViewのフレームを更新
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

        @objc func savePhoto() {
            guard let imageToSave = capturedImage else { return }
            UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
            
            DispatchQueue.main.async {
                self.imageView?.isHidden = true
                self.previewLayer?.isHidden = false
                self.captureSession?.startRunning()
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
