//
//  ReceiverCell.swift
//  ChatBot_Demo
//
//  Created by Shatadru Datta on 4/1/18.
//  Copyright © 2018 ARBSoftware. All rights reserved.
//

import UIKit

class ReceiverCell: BaseTableViewCell {

    @IBOutlet weak var imgBotProf: UIImageView!
    @IBOutlet weak var lblBotMessage: UILabel!
    override var datasource: AnyObject? {
        didSet {
            if datasource != nil {
                self.lblBotMessage.text = datasource as? String
            }
        }
    }

}
