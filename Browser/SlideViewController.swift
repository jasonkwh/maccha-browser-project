//
//  SlideViewController.swift
//  pipi-browser-project
//
//  Created by Jason Wong on 6/02/2016.
//  Copyright © 2016 Studios Pâtes, Jason Wong (mail: jasonkwh@gmail.com).
//

import UIKit

class SlideViewController: UIViewController {
    
    @IBOutlet weak var toolbar: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //define basic style of slide view
        self.view.backgroundColor = UIColor(netHex:0x2E2E2E)
        toolbar.barTintColor = UIColor(netHex:0x2E2E2E)
        toolbar.clipsToBounds = true
    }
    
    @IBAction func aboutAction(sender: AnyObject) {
        slideViewValue.aboutButton = true
        revealViewController().rightRevealToggleAnimated(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}