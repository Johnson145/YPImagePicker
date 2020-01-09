//
//  YPImagePicker.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 27/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

public protocol YPImagePickerDelegate: AnyObject {
    func noPhotos()
}

public protocol YPImagePickerSetupDelegate: YPImagePickerDelegate {
    func presentNewViewController(_ controller: UIViewController)
    func userDidSelectItem(_ items: [YPMediaItem])
}

open class YPImagePickerSetup {
    open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    public weak var delegate: YPImagePickerSetupDelegate?
    public var rootNavigation: RootNavigation? {
        get {
            return self.picker.rootNavigation
        }
        set {
            self.picker.rootNavigation = newValue
        }
    }

    private var _didFinishPicking: (([YPMediaItem], Bool) -> Void)?
    public func didFinishPicking(completion: @escaping (_ items: [YPMediaItem], _ cancelled: Bool) -> Void) {
        _didFinishPicking = completion
    }

    let config: YPImagePickerConfiguration

    open var preferredStatusBarStyle: UIStatusBarStyle {
        return config.preferredStatusBarStyle
    }

    private func didSelect(items: [YPMediaItem]) {
        _didFinishPicking?(items, false)
    }

    let loadingView = YPLoadingView()
    public var picker: YPPickerVC!

    public init(defaultMode: YPPickerScreen?, configuration: YPImagePickerConfiguration) {
        config = configuration
        picker = YPPickerVC(defaultMode: defaultMode, config: config)
        picker.imagePickerDelegate = self
    }

    open func emitDone() {
        self.picker.done()
    }

    open func setupLoadingView(in view: UIView){
        view.sv(
                loadingView
        )
        loadingView.fillContainer()
        loadingView.alpha = 0
    }

    open func setupPickerVC() -> YPPickerVC {
        picker.didClose = { [weak self] in
            self?._didFinishPicking?([], true)
        }

        picker.didSelectItems = { [weak self] items in
            self?.delegate?.userDidSelectItem(items)
            // Multiple items flow
            if items.count > 1 {
                if self?.config.library.skipSelectionsGallery == true {
                    self?.didSelect(items: items)
                    return
                } else {
                    guard let this = self else { return }
                    let selectionsGalleryVC = YPSelectionsGalleryVC(items: items, config: this.config) { _, items in
                        self?.didSelect(items: items)
                    }
                    if this.rootNavigation !== this {
                        selectionsGalleryVC.rootNavigation = this.rootNavigation
                    }
                    self?.delegate?.presentNewViewController(selectionsGalleryVC)
                    return
                }
            }

            // One item flow
            let item = items.first!
            switch item {
            case .photo(let photo):
                let completion = { (photo: YPMediaPhoto) in
                    let mediaItem = YPMediaItem.photo(p: photo)
                    // Save new image or existing but modified, to the photo album.
                    if self?.config.shouldSaveNewPicturesToAlbum == true {
                        let isModified = photo.modifiedImage != nil
                        if photo.fromCamera || (!photo.fromCamera && isModified) {
                            YPPhotoSaver.trySaveImage(photo.image, inAlbumNamed: self!.config.albumName)
                        }
                    }
                    self?.didSelect(items: [mediaItem])
                }

                func showCropVC(photo: YPMediaPhoto, completion: @escaping (_ aphoto: YPMediaPhoto) -> Void) {
                    guard let this = self else { return }
                    if case let YPCropType.rectangle(ratio) = this.config.showsCrop {
                        let cropVC = YPCropVC(image: photo.image, ratio: ratio, config: this.config)
                        cropVC.didFinishCropping = { croppedImage in
                            photo.modifiedImage = croppedImage
                            completion(photo)
                        }
                        self?.delegate?.presentNewViewController(cropVC)
                    } else {
                        completion(photo)
                    }
                }

                if self?.config.showsPhotoFilters == true {
                    let filterVC = YPPhotoFiltersVC(inputPhoto: photo,
                            isFromSelectionVC: false,
                            config: self!.config)
                    if self!.rootNavigation !== self! {
                        filterVC.rootNavigation = self!.rootNavigation
                    }
                    // Show filters and then crop
                    filterVC.didSave = { outputMedia in
                        if case let YPMediaItem.photo(outputPhoto) = outputMedia {
                            showCropVC(photo: outputPhoto, completion: completion)
                        }
                    }
                    self?.delegate?.presentNewViewController(filterVC)
                } else {
                    showCropVC(photo: photo, completion: completion)
                }
            case .video(let video):
                if self?.config.showsVideoTrimmer == true {
                    let videoFiltersVC = YPVideoFiltersVC.initWith(video: video,
                            isFromSelectionVC: false,
                            config: self!.config)
                    if self!.rootNavigation !== self {
                        videoFiltersVC.rootNavigation = self!.rootNavigation
                    }
                    videoFiltersVC.didSave = { [weak self] outputMedia in
                        self?.didSelect(items: [outputMedia])
                    }
                    self?.delegate?.presentNewViewController(videoFiltersVC)
                } else {
                    self?.didSelect(items: [YPMediaItem.video(v: video)])
                }
            }
        }

        return picker
    }
}

extension YPImagePickerSetup: ImagePickerDelegate {
    func noPhotos() {
        self.delegate?.noPhotos()
    }
}

open class YPImagePicker: UINavigationController {

    var setuper: YPImagePickerSetup

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.setuper.supportedInterfaceOrientations
    }

    public func didFinishPicking(completion: @escaping (_ items: [YPMediaItem], _ cancelled: Bool) -> Void) {
        self.setuper.didFinishPicking(completion: completion)
    }
    public weak var imagePickerDelegate: YPImagePickerDelegate?

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return setuper.preferredStatusBarStyle
    }

    /// Get a YPImagePicker instance with the default configuration.
    public convenience init() {
        self.init(configuration: YPImagePickerConfiguration())
    }
    
    /// Get a YPImagePicker with the specified configuration.
    public required init(configuration: YPImagePickerConfiguration) {
        self.setuper = YPImagePickerSetup(defaultMode: nil, configuration: configuration)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen // Force .fullScreen as iOS 13 now shows modals as cards by default.
        self.setuper.delegate = self
    }
    
    public init(defaultMode: YPPickerScreen, configuration: YPImagePickerConfiguration) {
        self.setuper = YPImagePickerSetup(defaultMode: nil, configuration: configuration)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen // Force .fullScreen as iOS 13 now shows modals as cards by default.
        self.setuper.delegate = self
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Emits the done event where the user selection is final and all callbacks get called
    public func emitDone() {
        self.setuper.emitDone()
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [setuper.picker]
        self.setuper.setupLoadingView(in: self.view)
        navigationBar.isTranslucent = false

        // If user has not customized the Nav Bar tintColor, then use black.
        if UINavigationBar.appearance().tintColor == nil {
            UINavigationBar.appearance().tintColor = .ypLabel
        }
    }
    
    deinit {
        print("Picker deinited 👍")
    }
    
}

extension YPImagePicker: YPImagePickerSetupDelegate {
    public func userDidSelectItem(_ items: [YPMediaItem]) {
        // Use Fade transition instead of default push animation
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.fade
        self.view.layer.add(transition, forKey: nil)
    }

    public func presentNewViewController(_ controller: UIViewController) {
        self.pushViewController(controller, animated: true)
    }

    public func noPhotos() {
        self.imagePickerDelegate?.noPhotos()
    }
}
