//
//  SenderCell.swift
//  ChatBot_Demo
//
//  Created by Shatadru Datta on 4/1/18.
//  Copyright © 2018 ARBSoftware. All rights reserved.
//

import UIKit

class SenderCell: BaseTableViewCell {
   
    @IBOutlet weak var imgSenderProf: UIImageView!
    @IBOutlet weak var lblSenderMessage: UILabel!
    override var datasource: AnyObject? {
        didSet {
            if datasource != nil {
                self.lblSenderMessage.text = datasource as? String
            }
        }
    }
    
}
