//
//  YPMenuItem.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 24/01/2018.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import Stevia

final class YPMenuItem: UIView {
    
    var configuration: YPImagePickerConfiguration!
    var textLabel = UILabel()
    var button = UIButton()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    convenience init(configuration: YPImagePickerConfiguration) {
        self.configuration = configuration
    }
    
    func setup() {
        backgroundColor = self.configuration.colors.bottomMenuItemBackgroundColor
        
        sv(
            textLabel,
            button
        )
        
        textLabel.centerInContainer()
        |-(10)-textLabel-(10)-|
        button.fillContainer()
        
        textLabel.style { l in
            l.textAlignment = .center
            l.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            l.textColor = self.configuration.colors.bottomMenuItemUnselectedTextColor
            l.adjustsFontSizeToFitWidth = true
            l.numberOfLines = 2
        }
    }

    func select() {
        textLabel.textColor = self.configuration.colors.bottomMenuItemSelectedTextColor
    }
    
    func deselect() {
        textLabel.textColor = self.configuration.colors.bottomMenuItemUnselectedTextColor
    }
}
