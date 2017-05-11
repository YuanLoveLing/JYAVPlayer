//
//  JYVedioPlayerView.swift
//  JYVedioPlayer
//
//  Created by 靳志远 on 2017/5/11.
//  Copyright © 2017年 靳志远. All rights reserved.
//

import UIKit
import AVFoundation

class JYVedioPlayerView: UIView {
    /// 关闭按钮
    @IBOutlet fileprivate weak var dismissButton: UIButton!
    /// 网络加载指示器
    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!
    
    /// 播放、暂停按钮
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var playPauseButtonLeftLC: NSLayoutConstraint!
    @IBOutlet weak var playPauseButtonWidthLC: NSLayoutConstraint!
    
    /// 当前播放时间
    @IBOutlet fileprivate weak var currentTimeLbl: UILabel!
    @IBOutlet weak var currentTimeLblLeftLC: NSLayoutConstraint!
    @IBOutlet weak var currentTimeLblWidthLC: NSLayoutConstraint!
    
    /// 总时长
    @IBOutlet fileprivate weak var durationLbl: UILabel!
    @IBOutlet weak var durationLblLeftLC: NSLayoutConstraint!
    @IBOutlet weak var durationLblRightLC: NSLayoutConstraint!
    
    /// 进度容器视图
    @IBOutlet weak var progressContainerView: UIView!
    @IBOutlet weak var progressContainerViewLeftLC: NSLayoutConstraint!
    
    /// 进度圆点视图
    @IBOutlet weak var progressDotView: UIView!
    @IBOutlet weak var progressDotViewLeftLC: NSLayoutConstraint!
    @IBOutlet weak var progressDotViewWidthLC: NSLayoutConstraint!
    
    /// 计时器：更新播放进度
    fileprivate var progressTimer: Timer?
    
    fileprivate var player: AVPlayer?
    fileprivate var playerItem: AVPlayerItem?
    fileprivate var playerLayer: AVPlayerLayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    /// 显示
    class func show(url: URL) {
        guard let playView = Bundle.main.loadNibNamed("JYVedioPlayerView", owner: nil, options: nil)?.first as? JYVedioPlayerView else {
            return
        }
        playView.playerItem = AVPlayerItem(url: url)
        playView.player = AVPlayer(playerItem: playView.playerItem)
        if NSString(string: UIDevice.current.systemVersion).integerValue >= 10 {// iOS10.0以后特殊处理一下
            /*
             ios10种AVPlayer增加了多个属性，其中有几个需要注意一下
             timeControlStatus
             automaticallyWaitsToMinimizeStalling: 自动等待以减少拖延
             */
            // 设置为非自动等待，以避免在线播放时缓冲时间过长
            playView.player?.automaticallyWaitsToMinimizeStalling = false
        }
        
        playView.playerLayer = AVPlayerLayer(player: playView.player)
        playView.playerLayer?.videoGravity = AVLayerVideoGravityResizeAspect
        playView.layer.insertSublayer(playView.playerLayer!, below: playView.dismissButton.layer)
        
        // 显示动画
        let window = UIApplication.shared.keyWindow
        window?.addSubview(playView)
        playView.frame = UIScreen.main.bounds
        playView.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
        window?.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.25, animations: {
            playView.transform = CGAffineTransform.identity
            
        }) { (_) in
            window?.isUserInteractionEnabled = true
            playView.activityIndicator.startAnimating()
        }
        
        // 开始播放
        playView.player?.play()
        
        /// KVO监听视频加载状态
        playView.playerItem?.addObserver(playView, forKeyPath: "status", options: .new, context: nil)
    }
    
    /// 关闭
    @IBAction fileprivate func dismissButtonDidClick(_ sender: Any) {
        // 移除KVO
        removeKVO()
        // 移除计时器
        removeProgressTimer()
        
        let window = UIApplication.shared.keyWindow
        window?.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.25, animations: {[weak self] in
            self?.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
            
        }) {[weak self] (_) in
            self?.removeFromSuperview()
            window?.isUserInteractionEnabled = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        playerLayer?.frame = bounds
        
        progressDotView.layer.cornerRadius = progressDotViewWidthLC.constant / 2
        progressDotView.layer.masksToBounds = true
    }
    
    deinit {
        print("\(#file): 88")
    }
}


// MARK: - KVO监听处理
extension JYVedioPlayerView {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            guard let playerItem = playerItem else {
                return
            }
            
            if playerItem.status == AVPlayerItemStatus.readyToPlay {// 加载成功
                // 移除网络加载指示器
                activityIndicator.stopAnimating()
                activityIndicator.isHidden = true
                
                // 添加计时器
                addProgressTimer()
                
            }else if playerItem.status == AVPlayerItemStatus.failed {// 加载失败
                // 移除网络加载指示器
                activityIndicator.stopAnimating()
                activityIndicator.isHidden = true
                
                let alertController = UIAlertController(title: "温馨提示", message: "视频加载失败", preferredStyle: .alert)
                let action = UIAlertAction(title: "知道了", style: .default, handler: nil)
                alertController.addAction(action)
                UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    /// 移除KVO
    fileprivate func removeKVO() {
        playerItem?.removeObserver(self, forKeyPath: "status")
    }
}


// MARK: - 计时器逻辑
extension JYVedioPlayerView {
    /// 添加计时器
    fileprivate func addProgressTimer() {
        removeProgressTimer()
        progressTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
    }
    
    /// 计时器触发方法
    @objc fileprivate func updateProgress() {
        guard let playerItem = playerItem  else {
            return
        }
        let currentTime = CMTimeGetSeconds(playerItem.currentTime())
        var duration = CMTimeGetSeconds(playerItem.duration)
        if duration.isNaN == true {// 当分母为0时，结果为inf（inf表示无穷大）
            duration = 0.001;
        }
        currentTimeLbl.text = stringWithTime(time: currentTime)
        durationLbl.text = stringWithTime(time: duration)
        
        // 更新进度条进度
        let percent = CGFloat(currentTime / duration)
        let proressContainerViewWith = bounds.width - playPauseButtonLeftLC.constant - playPauseButtonWidthLC.constant - currentTimeLblLeftLC.constant - 2 * currentTimeLblWidthLC.constant - progressContainerViewLeftLC.constant - durationLblLeftLC.constant - durationLblRightLC.constant
        progressDotViewLeftLC.constant = percent * (proressContainerViewWith - progressDotViewWidthLC.constant)
        
        if currentTime == duration {
            print("播放完毕")
            // 移除计时器
            removeProgressTimer()
        }
    }
    
    /// 移除计时器
    fileprivate func removeProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    /// 时间格式转换
    fileprivate func stringWithTime(time: Float64) -> (String) {
        let minute = Int(time / 60)
        let second = Int(time) % 60
        return String(format: "%02d:%02d", arguments: [minute, second])
    }
}










