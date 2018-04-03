//
//  SplashController.swift
//  ChatBot_Demo
//
//  Created by Shatadru Datta on 3/31/18.
//  Copyright © 2018 ARBSoftware. All rights reserved.
//

import UIKit

class SplashController: UIViewController {

    @IBOutlet weak var imgLogo: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        UIView.animate(withDuration: 1.5, animations: {
            let secondViewController = self.storyboard?.instantiateViewController(withIdentifier: "ChatController") as! ChatController
            self.navigationController?.pushViewController(secondViewController, animated: true)
        })
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    

}
