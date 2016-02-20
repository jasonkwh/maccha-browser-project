/*
*  ModalView.swift
*  quaza-browser-project
*
*  This Source Code Form is subject to the terms of the Mozilla Public
*  License, v. 2.0. If a copy of the MPL was not distributed with this
*  file, You can obtain one at http://mozilla.org/MPL/2.0/.
*
*  Created by Jason Wong on 15/02/2016.
*  Copyright © 2016 Studios Pâtes, Jason Wong (mail: jasonkwh@gmail.com).
*/

import UIKit

class ModalView: UIView {
    var bottomButtonHandler: (() -> Void)?
    var closeButtonHandler: (() -> Void)?
    
    @IBOutlet weak var alertPic: UIImageView!
    @IBOutlet weak var version: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet private weak var bottomButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var contents: UILabel!
    
    class func instantiateFromNib() -> ModalView {
        let view = UINib(nibName: "ModalView", bundle: nil).instantiateWithOwner(nil, options: nil).first as! ModalView
        
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.configure()
    }
    
    private func configure() {
        if(slideViewValue.aboutScreen == true) {
            alertPic.image = UIImage(named: "icon_face")
            self.version.text = "Quaza " + slideViewValue.version()
            self.contents.text = "Revolutionize your phablet web browsing experience!"
            self.contentView.backgroundColor = slideViewValue.windowCurColour
            slideViewValue.aboutScreen = false
        }
        if(slideViewValue.alertScreen == true) {
            alertPic.image = UIImage(named: "Alert")
            self.version.text = "Oops..!"
            self.contents.text = slideViewValue.alertContents
            self.contentView.backgroundColor = UIColor(netHex:0xE74C3C)
            slideViewValue.alertScreen = false
        }
        self.contentView.layer.cornerRadius = 5.0
        self.closeButton.layer.cornerRadius = CGRectGetHeight(self.closeButton.bounds) / 2.0
        self.closeButton.layer.shadowColor = UIColor.blackColor().CGColor
        self.closeButton.layer.shadowOffset = CGSizeZero
        self.closeButton.layer.shadowOpacity = 0.3
        self.closeButton.layer.shadowRadius = 2.0
    }
    
    @IBAction func handleBottomButton(sender: UIButton) {
        self.bottomButtonHandler?()
    }
    @IBAction func handleCloseButton(sender: UIButton) {
        self.closeButtonHandler?()
    }
}