import SwiftUI
import AVFoundation

// UIViewを継承したカスタムビュークラス。カメラ機能を実装しています。
// https://developer.apple.com/documentation/uikit/uiview
// https://developer.apple.com/documentation/avfoundation/avcapturephotocapturedelegate
// UIViewクラスの継承と AVCapturePhotoCaptureDelegateプロトコルの実装を行なっている。
// プロトコル ≒ Goのインターフェースのようなもの。
class CameraUIView: UIView, AVCapturePhotoCaptureDelegate {
    ////////////////////////////////////////////
    // 変数定義
    ////////////////////////////////////////////
    private var captureSession: AVCaptureSession?  // カメラのセッションを管理
    private let photoOutput = AVCapturePhotoOutput()  // 写真の出力を管理
    private var captureButton: UIButton?  // 撮影ボタン
    private var capturedImage: UIImage?  // 撮影した画像を保持
    private var filteredImage: UIImage?  // フィルター適用後の画像を保持
    private var imageView: UIImageView?  // 撮影した画像を表示するためのビュー
    private var previewLayer: AVCaptureVideoPreviewLayer?  // カメラからの映像を表示するレイヤー
    private var currentCameraPosition: AVCaptureDevice.Position = .back // フロント、バックどちらのカメラを使用するか

    ////////////////////////////////////////////
    //  初期化処理
    ////////////////////////////////////////////
    // コンポーネントの初期化に関する制御
    // StoryboardやXIBからのビルドは不可
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // CameraUIViewクラスのインスタンスが作成される際に呼び出される
    // https://developer.apple.com/documentation/corefoundation/cgrect
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeSession()  // カメラセッションの初期化
        setupCaptureButton()  // 撮影ボタンの設定
        setupImageView()  // imageViewの設定
        setupFilterButton() // 画像加工
        setupCameraSwitchButton() // カメラ切り替えボタンの追加
    }
    // カメラセッションの初期化
    private func initializeSession() {
        // TODO: 重い処理が多いため軽量化したい。
        // https://developer.apple.com/documentation/avfoundation/avcapturesession
        self.captureSession = AVCaptureSession()
        
        // 入力デバイスのAPIコールに失敗した場合、早期リターン
        guard
            let session = self.captureSession,
            let backCamera = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: backCamera)
        else {
            print("Failed to initialize the camera device or input.")
            return
        }
        
        // https://developer.apple.com/documentation/avfoundation/avcapturesession/1387180-canaddinput
        if session.canAddInput(input) {
            session.addInput(input)
            //                    print("Input was added to the session.")
        } else {
            print("Cannot add input to the session.")
        }
        // https://developer.apple.com/documentation/avfoundation/avcapturesession/1388944-canaddoutput
        if session.canAddOutput(self.photoOutput) {
            session.addOutput(self.photoOutput)
            //                    print("Output was added to the session.")
        } else {
            print("Cannot add output to the session.")
        }
        
        // https://developer.apple.com/documentation/avfoundation/avcapturevideopreviewlayer
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        guard let previewLayer = self.previewLayer else {
            print("Failed to create AVCaptureVideoPreviewLayer.")
            return
        }
        
        // AVCaptureSession のリソース消費が大きいため非同期実行。
        DispatchQueue.main.async {
            // https://qiita.com/tanaka-tt/items/0b2df30e1c79638580f7
            previewLayer.frame = self.bounds
            previewLayer.videoGravity = .resizeAspectFill
            self.layer.addSublayer(previewLayer)
            // print("Preview layer was added to the view.")
            
            // https://developer.apple.com/documentation/avfoundation/avcapturesession/1388185-startrunning
            session.startRunning()
            //                print("Session is running.")
        }
    }
    // imageViewのセットアップ
    private func setupImageView() {
        // https://developer.apple.com/documentation/uikit/uiimageview
        imageView = UIImageView(frame: self.bounds)
        imageView?.contentMode = .scaleAspectFit
        imageView?.isHidden = true // 初期状態では非表示にしておく。

        if let imageView = imageView {
            // https://developer.apple.com/documentation/uikit/uiview/1622616-addsubview
            self.addSubview(imageView)
        }
    }

    ////////////////////////////////////////////
    // レイアウト調整
    ////////////////////////////////////////////
    // https://developer.apple.com/documentation/uikit/uiview/1622482-layoutsubviews
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView?.frame = self.bounds
        
        let buttonWidth: CGFloat = 70
        let buttonHeight: CGFloat = 70
        let buttonSpacing: CGFloat = 20

        // 撮影ボタンの位置を中央下部に配置
        captureButton?.frame = CGRect(x: (self.bounds.width - buttonWidth) / 2, y: self.bounds.height - buttonHeight - 20, width: buttonWidth, height: buttonHeight)

        // 保存せずに撮影モードに戻るボタンの配置
        if let retakeButton = self.viewWithTag(102) as? UIButton {
            retakeButton.frame = CGRect(x: captureButton!.frame.maxX + 20, y: captureButton!.frame.minY, width: 70, height: 70)
            retakeButton.isHidden = imageView?.isHidden ?? true  // imageViewが表示されているときのみボタンを表示
            self.bringSubviewToFront(retakeButton)
        } else {
            setupRetakeButton()
        }
        
        // レイアウト調整が行われるたびにボタンを最前面に
        if let switchButton = self.viewWithTag(103) as? UIButton {
            self.bringSubviewToFront(switchButton)
        }

        // フィルターボタンの位置を撮影ボタンの左に配置
        if let filterButton = self.viewWithTag(101) as? UIButton {
            filterButton.frame = CGRect(x: captureButton!.frame.minX - buttonWidth - buttonSpacing, y: captureButton!.frame.minY, width: buttonWidth, height: buttonHeight)
            filterButton.isHidden = imageView?.isHidden ?? true
            self.bringSubviewToFront(filterButton)
            print("Filter button adjusted with frame: \(filterButton.frame)")
        } else {
            let filterButton = UIButton(frame: CGRect(x: captureButton!.frame.minX - buttonWidth - buttonSpacing, y: captureButton!.frame.minY, width: buttonWidth, height: buttonHeight))
            filterButton.backgroundColor = .gray
            filterButton.layer.cornerRadius = 35
            filterButton.setTitle("フィルター", for: .normal)
            filterButton.addTarget(self, action: #selector(applyFilterAndDisplay), for: .touchUpInside)
            filterButton.tag = 101
            self.addSubview(filterButton)
            self.bringSubviewToFront(filterButton)
            print("Filter button created and added with frame: \(filterButton.frame)")
        }

        self.bringSubviewToFront(captureButton!)
    }

    ////////////////////////////////////////////
    // ボタンのセットアップ
    ////////////////////////////////////////////
    // 撮影ボタンのセットアップ
    private func setupCaptureButton() {
        // https://developer.apple.com/documentation/uikit/uibutton
        captureButton = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        // if let = オプショナルバインディング
        // 通常UIButtonのインスタンス作成時に nil が返される事はない
        if let captureButton = captureButton {
            captureButton.backgroundColor = .white
            captureButton.layer.cornerRadius = 35
            //            captureButton.setTitle("撮影", for: .normal)
            //            captureButton.setTitleColor(.black, for: .normal)
            let iconImage = UIImage(named: "shutter")
            captureButton.setImage(iconImage, for: .normal)
            
            // // ボタンのタップイベントに関数を関連付け
            captureButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
            
            // ボタンをビューの前面に追加
            self.addSubview(captureButton)
            self.bringSubviewToFront(captureButton)
        }
    }
    // 撮影ボタン設定時にフィルター適用ボタンも追加
    // フィルターボタンの初期化をsetupメソッドに移動し、初期状態で隠れないようにする。
    private func setupFilterButton() {
        let filterButton = UIButton(frame: CGRect(x: 20, y: 20, width: 70, height: 70))
        filterButton.backgroundColor = .gray
        filterButton.layer.cornerRadius = 35
        filterButton.setTitle("フィルター", for: .normal)
        filterButton.addTarget(self, action: #selector(applyFilterAndDisplay), for: .touchUpInside)
        filterButton.tag = 101  // ボタンにタグを設定
        self.addSubview(filterButton)
    }
    // 画像を保存せずに再撮影するためのボタン
    private func setupRetakeButton() {
        let retakeButton = UIButton(frame: CGRect(x: 20, y: 20, width: 70, height: 70))
        retakeButton.backgroundColor = .white
        retakeButton.layer.cornerRadius = 35
        let retakeIcon = UIImage(named: "retake")
        retakeButton.setImage(retakeIcon, for: .normal)
        
        retakeButton.addTarget(self, action: #selector(hideImage), for: .touchUpInside)
        retakeButton.tag = 102  // ボタンにタグを設定
        self.addSubview(retakeButton)
    }
    ////////////////////////////////////////////
    // フロントとバックのカメラを切り替える
    ////////////////////////////////////////////
    private func setupCameraSwitchButton() {
        let switchButton = UIButton(frame: CGRect(x: 20, y: 70, width: 70, height: 70))
        switchButton.backgroundColor = .gray
        switchButton.layer.cornerRadius = 35
        switchButton.setTitle("切替", for: .normal)
        switchButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        switchButton.tag = 103  // ボタンにタグを設定
        self.addSubview(switchButton)
        self.bringSubviewToFront(switchButton)  // ボタンを最前面に移動
    }
    @objc func switchCamera() {
        // セッションの一時停止
        captureSession?.stopRunning()

        // 現在のカメラ入力を取り除く
        if let inputs = captureSession?.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                captureSession?.removeInput(input)
            }
        }
        
        // 使用するカメラの切り替え
        let newPosition: AVCaptureDevice.Position = (currentCameraPosition == .back) ? .front : .back
        currentCameraPosition = newPosition
        let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition)
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newCamera!)
            captureSession?.addInput(newInput)
        } catch {
            print("Failed to switch cameras: \(error)")
            return
        }
        
        // セッション再開
        captureSession?.startRunning()
    }
    ////////////////////////////////////////////
    // 写真撮影
    ////////////////////////////////////////////
    // 写真を撮影する。
    @objc func takePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    // 写真撮影後のレビュー状態から再び写真撮影ができる状態へとUIをリセットする
    @objc func retakePhoto() {
        DispatchQueue.main.async {
            self.imageView?.isHidden = true
            self.previewLayer?.isHidden = false
            self.captureSession?.startRunning()
            self.captureButton?.removeTarget(self, action: #selector(self.retakePhoto), for: .touchUpInside)
            self.captureButton?.addTarget(self, action: #selector(self.takePhoto), for: .touchUpInside)
        }
    }
    // 写真が撮影された後の処理
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // DEBUG
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            print("Photo captured successfully")
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Failed to convert photo to UIImage.")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Failed to convert photo to UIImage.")
            return
        }
        
        // フロントカメラの場合、画像を反転させる
        var processedImage = image
        if currentCameraPosition == .front, let cgImage = image.cgImage {
            processedImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .leftMirrored)
        }
        
        // 反転処理後の画像をcapturedImageに保存
        self.capturedImage = processedImage
        
        // UI更新はメインスレッドで行う
        DispatchQueue.main.async {
            if let imageView = self.imageView {
                // imageView.image = image
                imageView.image = self.capturedImage
                imageView.isHidden = false
                self.bringSubviewToFront(imageView)
                print("Image should be visible now")
            } else {
                print("imageView is nil")
            }
            
            // カメラ切り替えボタンを非表示に
            if let switchButton = self.viewWithTag(103) as? UIButton {
                switchButton.isHidden = true
            }
            
            self.previewLayer?.isHidden = true
            let downloadIcon = UIImage(named: "download")  // Assets.xcassetsから参照
            self.captureButton?.setImage(downloadIcon, for: .normal)
            
            self.captureButton?.removeTarget(self, action: #selector(self.takePhoto), for: .touchUpInside)
            self.captureButton?.addTarget(self, action: #selector(self.savePhoto), for: .touchUpInside)
        }
    }
    
    ////////////////////////////////////////////
    // 画像の保存
    ////////////////////////////////////////////
    // ダウンロードボタンが押された時
    @objc func savePhoto() {
        guard let imageToSave = filteredImage ?? capturedImage else {
            print("No image to save")
            return
        }
        // 撮影した画像をフォトライブラリに保存する
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        print("Image saved: \(imageToSave)")
        
        DispatchQueue.main.async {
            // 画像とフィルターボタンを非表示にし、カメラプレビューを再表示する
            self.imageView?.isHidden = true
            if let filterButton = self.viewWithTag(101) as? UIButton {
                filterButton.isHidden = true
            }
            self.previewLayer?.isHidden = false
            // カメラセッションを再開する
            self.captureSession?.startRunning()
            // ボタンのタイトルを「撮影」に戻し、アクションを撮影に設定する
            //            self.captureButton?.setTitle("撮影", for: .normal)
            let iconImage = UIImage(named: "shutter")
            self.captureButton?.setImage(iconImage, for: .normal)
            
            self.captureButton?.removeTarget(self, action: #selector(self.savePhoto), for: .touchUpInside)
            self.captureButton?.addTarget(self, action: #selector(self.takePhoto), for: .touchUpInside)
        }
    }
    // 画像を保存せずに撮影モードに戻る。
    @objc func hideImage() {
        DispatchQueue.main.async {
            // 画像を非表示にし、ボタンを再撮影用に設定
            self.imageView?.isHidden = true
            self.previewLayer?.isHidden = false
            self.captureSession?.startRunning()
            self.captureButton?.setImage(UIImage(named: "shutter"), for: .normal)
            self.captureButton?.removeTarget(self, action: #selector(self.hideImage), for: .touchUpInside)
            self.captureButton?.addTarget(self, action: #selector(self.takePhoto), for: .touchUpInside)
            
            // 保存せず撮影に戻るボタンを非表示
            if let retakeButton = self.viewWithTag(102) as? UIButton {
                retakeButton.isHidden = true
            }
            // カメラ切り替えボタンを表示
            if let switchButton = self.viewWithTag(103) as? UIButton {
                switchButton.isHidden = false
            }
        }
    }

    ////////////////////////////////////////////
    // フィルター
    ////////////////////////////////////////////
    // 撮影後のフィルター適用メソッド
    @objc func applyFilterAndDisplay() {
        if let originalImage = capturedImage, let filteredImage = applyFilter(to: originalImage) {
            imageView?.image = filteredImage
            self.filteredImage = filteredImage  // フィルター適用後の画像を保存
            print("Filter applied and image updated on screen")
        } else {
            print("Failed to apply filter")
        }
    }
    // 画像加工用のフィルター処理
    func applyFilter(to image: UIImage) -> UIImage? {
        let context = CIContext(options: nil)
        
        // 元の画像からCIImageを作成する際に、画像の向きを保持する
        guard let ciImage = CIImage(image: image),
              let filter = CIFilter(name: "CIPhotoEffectNoir") else { return nil }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        // フィルター処理を実行
        guard let output = filter.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        
        // 処理された画像をUIImageに変換する際に、元の画像の向きを指定する
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
