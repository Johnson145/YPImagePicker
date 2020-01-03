//
//  YPAlert.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

struct YPAlert {
    static func videoTooLongAlert(_ sourceView: UIView, config: YPImagePickerConfiguration) -> UIAlertController {
        let msg = String(format: config.wordings.videoDurationPopup.tooLongMessage,
                         "\(config.video.libraryTimeLimit)")
        let alert = UIAlertController(title: config.wordings.videoDurationPopup.title,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        alert.addAction(UIAlertAction(title: config.wordings.ok, style: UIAlertAction.Style.default, handler: nil))
        return alert
    }
    
    static func videoTooShortAlert(_ sourceView: UIView, config: YPImagePickerConfiguration) -> UIAlertController {
        let msg = String(format: config.wordings.videoDurationPopup.tooShortMessage,
                         "\(config.video.minimumTimeLimit)")
        let alert = UIAlertController(title: config.wordings.videoDurationPopup.title,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        alert.addAction(UIAlertAction(title: config.wordings.ok, style: UIAlertAction.Style.default, handler: nil))
        return alert
    }
}
