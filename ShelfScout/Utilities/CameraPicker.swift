import AVFoundation
import SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> CameraCaptureViewController {
        let controller = CameraCaptureViewController()
        controller.onImage = { image in
            onImage(image)
            dismiss()
        }
        controller.onCancel = {
            dismiss()
        }
        controller.modalPresentationStyle = .fullScreen
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraCaptureViewController, context: Context) {}
}

final class CameraCaptureViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var onImage: ((UIImage) -> Void)?
    var onCancel: (() -> Void)?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "ShelfScout.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isConfigured = false

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.isHidden = true
        return label
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Cancel", for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        button.layer.cornerRadius = 18
        return button
    }()

    private let captureButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.layer.cornerRadius = 36
        button.layer.borderColor = UIColor.black.withAlphaComponent(0.35).cgColor
        button.layer.borderWidth = 4
        button.accessibilityLabel = "Take photo"
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupControls()
        requestCameraIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    private func setupControls() {
        view.addSubview(messageLabel)
        view.addSubview(cancelButton)
        view.addSubview(captureButton)

        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        captureButton.addTarget(self, action: #selector(captureTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            cancelButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            cancelButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 78),
            cancelButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 38),

            captureButton.widthAnchor.constraint(equalToConstant: 72),
            captureButton.heightAnchor.constraint(equalToConstant: 72),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),

            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28)
        ])
    }

    private func requestCameraIfNeeded() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showMessage("Camera is not available here. Choose Photos or continue manually.")
            captureButton.isHidden = true
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    granted ? self?.configureAndStart() : self?.showCameraDenied()
                }
            }
        case .denied, .restricted:
            showCameraDenied()
        @unknown default:
            showCameraDenied()
        }
    }

    private func configureAndStart() {
        if previewLayer == nil {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            layer.frame = view.bounds
            view.layer.insertSublayer(layer, at: 0)
            previewLayer = layer
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !isConfigured {
                do {
                    try configureSession()
                    isConfigured = true
                } catch {
                    DispatchQueue.main.async {
                        self.showMessage("Camera could not be started. Choose Photos or continue manually.")
                        self.captureButton.isHidden = true
                    }
                    return
                }
            }
            if !session.isRunning {
                session.startRunning()
            }
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        session.sessionPreset = .photo
        defer { session.commitConfiguration() }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) ??
            AVCaptureDevice.default(for: .video) else {
            throw AppError.message("Camera is not available.")
        }

        let input = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(input), session.canAddOutput(photoOutput) else {
            throw AppError.message("Camera could not be configured.")
        }

        session.addInput(input)
        session.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .quality
    }

    private func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, session.isRunning else { return }
            session.stopRunning()
        }
    }

    private func showCameraDenied() {
        captureButton.isHidden = true
        showMessage("Camera permission is disabled. Choose Photos or continue manually.")
    }

    private func showMessage(_ message: String) {
        messageLabel.text = message
        messageLabel.isHidden = false
    }

    @objc private func cancelTapped() {
        onCancel?()
    }

    @objc private func captureTapped() {
        guard isConfigured else { return }
        captureButton.isEnabled = false
        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .quality
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        captureButton.isEnabled = true
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            showMessage("Photo could not be captured. Try again or choose a photo.")
            return
        }
        stopSession()
        onImage?(image)
    }
}
