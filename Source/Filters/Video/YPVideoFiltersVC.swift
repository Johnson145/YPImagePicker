//
//  VideoFiltersVC.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 18.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos
import PryntTrimmerView

public class YPVideoFiltersVC: UIViewController, IsMediaFilterVC {

    weak var rootNavigation: RootNavigation?
    
    @IBOutlet weak var trimBottomItem: YPMenuItem! {
        didSet {
            trimBottomItem.config = config
        }
    }
    @IBOutlet weak var coverBottomItem: YPMenuItem!{
        didSet {
            coverBottomItem.config = config
        }
    }
    
    @IBOutlet weak var videoView: YPVideoView!
    @IBOutlet weak var trimmerView: TrimmerView!
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var coverThumbSelectorView: ThumbSelectorView!

    public var inputVideo: YPMediaVideo!
    public var inputAsset: AVAsset { return AVAsset(url: inputVideo.url) }
    
    private var playbackTimeCheckerTimer: Timer?
    private var imageGenerator: AVAssetImageGenerator?
    private var isFromSelectionVC = false
    
    var didSave: ((YPMediaItem) -> Void)?
    var didCancel: (() -> Void)?

    private(set) var config: YPImagePickerConfiguration = .init()

    /// Designated initializer
    public class func initWith(video: YPMediaVideo,
                               isFromSelectionVC: Bool,
                               config: YPImagePickerConfiguration) -> YPVideoFiltersVC {
        let vc = YPVideoFiltersVC(nibName: "YPVideoFiltersVC", bundle: Bundle(for: YPVideoFiltersVC.self))
        vc.config = config
        vc.inputVideo = video
        vc.isFromSelectionVC = isFromSelectionVC
        vc.rootNavigation = vc
        
        return vc
    }
    
    // MARK: - Live cycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        videoView.config = config

        view.backgroundColor = config.colors.filterBackgroundColor
        trimmerView.mainColor = config.colors.trimmerMainColor
        trimmerView.handleColor = config.colors.trimmerHandleColor
        trimmerView.positionBarColor = config.colors.positionLineColor
        trimmerView.maxDuration = config.video.trimmerMaxDuration
        trimmerView.minDuration = config.video.trimmerMinDuration
        
        coverThumbSelectorView.thumbBorderColor = config.colors.coverSelectorBorderColor
        
        trimBottomItem.textLabel.text = config.wordings.trim
        coverBottomItem.textLabel.text = config.wordings.cover

        trimBottomItem.button.addTarget(self, action: #selector(selectTrim), for: .touchUpInside)
        coverBottomItem.button.addTarget(self, action: #selector(selectCover), for: .touchUpInside)
        
        // Remove the default and add a notification to repeat playback from the start
        videoView.removeReachEndObserver()
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(itemDidFinishPlaying(_:)),
                         name: .AVPlayerItemDidPlayToEndTime,
                         object: nil)
        
        // Set initial video cover
        imageGenerator = AVAssetImageGenerator(asset: self.inputAsset)
        imageGenerator?.appliesPreferredTrackTransform = true
        didChangeThumbPosition(CMTime(seconds: 1, preferredTimescale: 1))
        
        // Navigation bar setup
        title = config.wordings.trim
        if isFromSelectionVC {
            rootNavigation?.navigationItem.leftBarButtonItem = UIBarButtonItem(title: config.wordings.cancel,
            style: .plain,
            target: config.defaultCancelTarget != nil ? config.defaultCancelTarget : self,
            action: config.defaultCancelSelector != nil ? config.defaultCancelSelector : #selector(cancel))
            rootNavigation?.navigationItem.leftBarButtonItem?.tintColor = config.colors.tintColor
        }
        setupRightBarButtonItem()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        trimmerView.asset = inputAsset
        trimmerView.delegate = self
        
        coverThumbSelectorView.asset = inputAsset
        coverThumbSelectorView.delegate = self
        
        selectTrim()
        videoView.loadVideo(inputVideo)

        super.viewDidAppear(animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlaybackTimeChecker()
        videoView.stop()
    }
    
    func setupRightBarButtonItem() {
        let rightBarButtonTitle = isFromSelectionVC ? config.wordings.done : config.wordings.next
        rootNavigation?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: rightBarButtonTitle,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(save))
        rootNavigation?.navigationItem.rightBarButtonItem?.tintColor = config.colors.tintColor
    }
    
    // MARK: - Top buttons

    @objc public func save() {
        guard let didSave = didSave else { return print("Don't have saveCallback") }
        rootNavigation?.navigationItem.rightBarButtonItem = YPLoaders.defaultLoader(config: self.config)

        do {
            let asset = AVURLAsset(url: inputVideo.url)
            let trimmedAsset = try asset
                .assetByTrimming(startTime: trimmerView.startTime ?? CMTime.zero,
                                 endTime: trimmerView.endTime ?? inputAsset.duration)
            
            // Looks like file:///private/var/mobile/Containers/Data/Application
            // /FAD486B4-784D-4397-B00C-AD0EFFB45F52/tmp/8A2B410A-BD34-4E3F-8CB5-A548A946C1F1.mov
            let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingUniquePathComponent(pathExtension: config.video.fileType.fileExtension)
            
            try trimmedAsset.export(to: destinationURL, config: config) { [weak self] in
                guard let strongSelf = self else { return }
                
                DispatchQueue.main.async {
                    let resultVideo = YPMediaVideo(thumbnail: strongSelf.coverImageView.image!,
                                                   videoURL: destinationURL, asset: strongSelf.inputVideo.asset)
                    didSave(YPMediaItem.video(v: resultVideo))
                    strongSelf.setupRightBarButtonItem()
                }
            }
        } catch let error {
            print("💩 \(error)")
        }
    }
    
    @objc func cancel() {
        didCancel?()
    }
    
    // MARK: - Bottom buttons

    @objc public func selectTrim() {
        title = config.wordings.trim
        
        trimBottomItem.select()
        coverBottomItem.deselect()

        trimmerView.isHidden = false
        videoView.isHidden = false
        coverImageView.isHidden = true
        coverThumbSelectorView.isHidden = true
    }
    
    @objc public func selectCover() {
        title = config.wordings.cover
        
        trimBottomItem.deselect()
        coverBottomItem.select()
        
        trimmerView.isHidden = true
        videoView.isHidden = true
        coverImageView.isHidden = false
        coverThumbSelectorView.isHidden = false
        
        stopPlaybackTimeChecker()
        videoView.stop()
    }
    
    // MARK: - Various Methods

    // Updates the bounds of the cover picker if the video is trimmed
    // TODO: Now the trimmer framework doesn't support an easy way to do this.
    // Need to rethink a flow or search other ways.
    func updateCoverPickerBounds() {
        if let startTime = trimmerView.startTime,
            let endTime = trimmerView.endTime {
            if let selectedCoverTime = coverThumbSelectorView.selectedTime {
                let range = CMTimeRange(start: startTime, end: endTime)
                if !range.containsTime(selectedCoverTime) {
                    // If the selected before cover range is not in new trimeed range,
                    // than reset the cover to start time of the trimmed video
                }
            } else {
                // If none cover time selected yet, than set the cover to the start time of the trimmed video
            }
        }
    }
    
    // MARK: - Trimmer playback
    
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        if let startTime = trimmerView.startTime {
            videoView.player.seek(to: startTime)
        }
    }
    
    func startPlaybackTimeChecker() {
        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer
            .scheduledTimer(timeInterval: 0.05, target: self,
                            selector: #selector(onPlaybackTimeChecker),
                            userInfo: nil,
                            repeats: true)
    }
    
    func stopPlaybackTimeChecker() {
        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }
    
    @objc func onPlaybackTimeChecker() {
        guard let startTime = trimmerView.startTime,
            let endTime = trimmerView.endTime else {
            return
        }
        
        let playBackTime = videoView.player.currentTime()
        trimmerView.seek(to: playBackTime)
        
        if playBackTime >= endTime {
            videoView.player.seek(to: startTime,
                                  toleranceBefore: CMTime.zero,
                                  toleranceAfter: CMTime.zero)
            trimmerView.seek(to: startTime)
        }
    }
}

// MARK: - TrimmerViewDelegate
extension YPVideoFiltersVC: TrimmerViewDelegate {
    public func positionBarStoppedMoving(_ playerTime: CMTime) {
        videoView.player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        videoView.play()
        startPlaybackTimeChecker()
        updateCoverPickerBounds()
    }
    
    public func didChangePositionBar(_ playerTime: CMTime) {
        stopPlaybackTimeChecker()
        videoView.pause()
        videoView.player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
}

// MARK: - ThumbSelectorViewDelegate
extension YPVideoFiltersVC: ThumbSelectorViewDelegate {
    public func didChangeThumbPosition(_ imageTime: CMTime) {
        if let imageGenerator = imageGenerator,
            let imageRef = try? imageGenerator.copyCGImage(at: imageTime, actualTime: nil) {
            coverImageView.image = UIImage(cgImage: imageRef)
        }
    }
}
