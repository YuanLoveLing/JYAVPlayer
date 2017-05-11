//
//  ViewController.swift
//  JYAVPlayer
//
//  Created by 靳志远 on 2017/5/10.
//  Copyright © 2017年 靳志远. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    /// 播放本地视频
    @IBAction func localButtonDidClick(_ sender: Any) {
        if let path = Bundle.main.path(forResource: "test.mp4", ofType: nil) {
            let url = URL(fileURLWithPath: path)
            JYVedioPlayerView.show(url: url)
        }
    }
    
    /// 播放在线视频
    @IBAction func onlineButtonDidClick(_ sender: Any) {
        if let url = URL(string: "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4") {
            JYVedioPlayerView.show(url: url)
        }
    }
}

