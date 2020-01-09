//
//  YPPhotoCapture.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 08/03/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

protocol YPPhotoCapture: class {
    
    // Public api
    func start(with previewView: UIView, completion: @escaping () -> Void)
    func stopCamera()
    func focus(on point: CGPoint)
    func zoom(began: Bool, scale: CGFloat)
    func tryToggleFlash()
    var hasFlash: Bool { get }
    var currentFlashMode: YPFlashMode { get }
    func flipCamera(completion: @escaping () -> Void)
    func shoot(completion: @escaping (Data) -> Void)
    var videoLayer: AVCaptureVideoPreviewLayer! { get set }
    var device: AVCaptureDevice? { get }
    
    // Used by Default extension
    var previewView: UIView! { get set }
    var isCaptureSessionSetup: Bool { get set }
    var isPreviewSetup: Bool { get set }
    var sessionQueue: DispatchQueue { get }
    var session: AVCaptureSession { get }
    var output: AVCaptureOutput { get }
    var deviceInput: AVCaptureDeviceInput? { get set }
    var initVideoZoomFactor: CGFloat { get set }

    var config: YPImagePickerConfiguration { get }
    func configure()
}

func newPhotoCapture(config: YPImagePickerConfiguration) -> YPPhotoCapture {
    if #available(iOS 10.0, *) {
        return PostiOS10PhotoCapture(config: config)
    } else {
        return PreiOS10PhotoCapture(config: config)
    }
}

enum YPFlashMode {
    case off
    case on
    case auto
}

extension YPFlashMode {
    func flashImage(config: YPImagePickerConfiguration) -> UIImage {
        switch self {
        case .on: return config.icons.flashOnIcon
        case .off: return config.icons.flashOffIcon
        case .auto: return config.icons.flashAutoIcon
        }
    }
}
