//
//  ViewController.swift
//  SwiftFunctionPointerFail
//
//  Created by Gene De Lisa on 4/9/15.
//  Copyright (c) 2015 Gene De Lisa. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        MIDIManager.sharedInstance.enableNetwork()
        var dests = MIDIManager.sharedInstance.getDestinations()
        
        for (key, value) in dests {
            println("dest \(key) \(value)")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

