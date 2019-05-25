//
//  PlayerDetailsView.swift
//  iPodcasts
//
//  Created by macOS on 3/11/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer

class PlayerDetailsView: UIView {

    var episode: Episode! {
        didSet {
            titleLabel.text = episode.title
            miniTitleLabel.text = episode.title
            authorLabel.text = episode.author
            
            setupNowPlayingInfo()
            
            guard let url = URL(string: episode.imageUrl ?? "") else { return }
            episodeImageView.sd_setImage(with: url)
            // Check
            //miniEpisodeImageView.sd_setImage(with: url)

            miniEpisodeImageView.sd_setImage(with: url) { (image, _, _, _) in
                
                guard let image = image else { return }
                
                var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
                
                let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { (_) -> UIImage in
                    return image
                })
                nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
            
            // Check
//            miniEpisodeImageView.sd_setImage(with: url) { (image, _, _, _) in
//                let image = self.episodeImageView.image ?? UIImage()
//                let artworkItem = MPMediaItemArtwork(boundsSize: .zero, requestHandler: { (size) -> UIImage in
//                    return image
//                })
//                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = artworkItem
//            }
            
            setupAudioSession()
            playEpisode()
        }
    }
    
    fileprivate func setupNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = episode.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = episode.author
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    fileprivate func playEpisode() {
        
        if episode.fileUrl != nil {
            playEpisodeUsingFileUrl()            
        } else {
            print("Trying to play: ", episode.streamUrl)
            
            guard let url = URL(string: episode.streamUrl) else { return }
            let playerItem = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: playerItem)
            player.play()
        }
        
    }
    
    fileprivate func playEpisodeUsingFileUrl() {
        guard let fileUrl = URL(string: episode.fileUrl ?? "") else { return }
        let fileName = fileUrl.lastPathComponent
        guard var trueLocation = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        trueLocation.appendPathComponent(fileName)
        
        let playerItem = AVPlayerItem(url: trueLocation)
        player.replaceCurrentItem(with: playerItem)
        player.play()
    }
    
    let player: AVPlayer = {
        let avPlayer = AVPlayer()
        avPlayer.automaticallyWaitsToMinimizeStalling = false
        return avPlayer
    }()
    
    fileprivate func observePlayerCurrentTime() {
        let interval = CMTimeMake(value: 1, timescale: 2)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] (time) in
            self?.currentTimeLabel.text = time.toStringFormat()
            let durationTime = self?.player.currentItem?.duration
            self?.durationLabel.text = durationTime?.toStringFormat()
            
            self?.updateCurrentTimeSlider()
            
//            self?.setupLockscreenCurrentTime()
        }
    }
    
//    fileprivate func setupLockscreenCurrentTime() {
//
//        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
//
//        guard let currentItemDuration = player.currentItem?.duration else { return }
//
//        let durationInSeconds = CMTimeGetSeconds(currentItemDuration)
//
//        let elapsedTime = CMTimeGetSeconds(player.currentTime())
//
//        nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
//
//        nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = durationInSeconds
//
//        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
//    }
    
    fileprivate func updateCurrentTimeSlider() {
        
        let currentTimeSeconds = CMTimeGetSeconds(player.currentTime())
        let durationSeconds = CMTimeGetSeconds(player.currentItem?.duration ?? CMTimeMake(value: 1, timescale: 1))
        
        let percentage = currentTimeSeconds / durationSeconds
        currentTimeSlider.value = Float(percentage)
    }
    
    var panGesture: UIPanGestureRecognizer!
    
    fileprivate func setupGestures() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapMaximize)))
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        miniPlayerView.addGestureRecognizer(panGesture)
        maximizedStackView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleDismissalPan)))
    }
    
    @objc func handleDismissalPan(gesture: UIPanGestureRecognizer) {
        
        if gesture.state == .changed {
            
            let translation = gesture.translation(in: superview)
            maximizedStackView.transform = CGAffineTransform(translationX: 0, y: translation.y)
        } else if gesture.state == .ended {
            
            let translation = gesture.translation(in: superview)
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.maximizedStackView.transform = .identity
                
                if translation.y > 100 {
                    let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController
                    mainTabBarController?.minimizePlayerDetails()
                }
                
            })
        }
        
    }
    
    fileprivate func setupAudioSession() {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let sessionErr {
            print("Failed to activate sessoin:", sessionErr)
        }
    }
    
    fileprivate func setupRemoteControl() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            self.player.play()
            self.playPauseButton.setImage(UIImage(named: "pause"), for: .normal)
            self.miniPlayPauseButton.setImage(UIImage(named: "pause"), for: .normal)
            self.setupElapsedTime(playbackRate: 1)
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            self.player.pause()
            self.playPauseButton.setImage(UIImage(named: "play"), for: .normal)
            self.miniPlayPauseButton.setImage(UIImage(named: "play"), for: .normal)
            self.setupElapsedTime(playbackRate: 0)
           return .success
        }
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            
            self.handlePlayPause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget(self, action: #selector(handleNextTrack))
        
        commandCenter.previousTrackCommand.addTarget(self, action: #selector(handlePreviousTrack))
        
    }
    
    
    var playlistEpisods = [Episode]()
    
    @objc fileprivate func handleNextTrack() {
        // May need to be commented
        playlistEpisods.forEach({ print($0.title)})
        
        if playlistEpisods.count == 0 {
            return
        }
        
        let currentEpisodeIndex = playlistEpisods.index { (ep) -> Bool in
            
            return self.episode.title == ep.title && self.episode.author == ep.author
            
        }
        
        guard let index = currentEpisodeIndex else { return }
        
        let nextEpisode: Episode
        
        if index == playlistEpisods.count - 1 {
            nextEpisode = playlistEpisods[0]
        } else {
            nextEpisode = playlistEpisods[index + 1]
        }
        
        self.episode = nextEpisode
    }
    
    @objc fileprivate func handlePreviousTrack() {
        // May need to be commented
        playlistEpisods.forEach({ print($0.title)})
        
        if playlistEpisods.count == 0 {
            return
        }
        
        let currentEpisodeIndex = playlistEpisods.index { (ep) -> Bool in
            
            return self.episode.title == ep.title && self.episode.author == ep.author
            
        }
        
        guard let index = currentEpisodeIndex else { return }
        
        let previousEpisode: Episode
        
        if index == 0 {
            previousEpisode = playlistEpisods.last!
        } else {
            previousEpisode = playlistEpisods[index - 1]
        }
        
        self.episode = previousEpisode
    }
    
    fileprivate func setupElapsedTime(playbackRate: Float) {
        let elapsedTime = CMTimeGetSeconds(player.currentTime())
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = playbackRate
    }
    
    fileprivate func observeBoundaryTime() {
        let time = CMTimeMake(value: 1, timescale: 3)
        let times = [NSValue(time: time)]
        player.addBoundaryTimeObserver(forTimes: times, queue: .main) { [weak self] in
            self?.enlargeEpisodeImageView()
            self?.setupLockscreenDuration()
        }
    }
    
    fileprivate func setupLockscreenDuration() {
        guard let duration = player.currentItem?.duration else { return }
        let durationInSeconds = CMTimeGetSeconds(duration)
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = durationInSeconds
        //MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = durationSeconds
    }
    
    fileprivate func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
//    deinit {
//        NotificationCenter.default.removeObserver(self, name: .AVAudioSessionInterruption, object: nil)
//    }
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        guard let type = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt else { return }
        
        if type == AVAudioSession.InterruptionType.began.rawValue {
            playPauseButton.setImage(UIImage(named: "play"), for: .normal)
            miniPlayPauseButton.setImage(UIImage(named: "play"), for: .normal)
        } else if type == AVAudioSession.InterruptionType.ended.rawValue {
            guard let options = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            if options == AVAudioSession.InterruptionOptions.shouldResume.rawValue {
                player.play()
                playPauseButton.setImage(UIImage(named: "pause"), for: .normal)
                miniPlayPauseButton.setImage(UIImage(named: "pause"), for: .normal)
            }
        }
        
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupRemoteControl()
        
        setupGestures()
        
        setupInterruptionObserver()
        
        observePlayerCurrentTime()
        
        observeBoundaryTime()
    }
    
    static func initFromNib() -> PlayerDetailsView {
        return Bundle.main.loadNibNamed("PlayerDetailsView", owner: self, options: nil)?.first as! PlayerDetailsView
    }
    
    deinit {
        print("PlayerDetailsView memory being reclaimed...")
    }
    
    //MARK:- IB Actions and Outlets
    
    
    @IBOutlet weak var miniEpisodeImageView: UIImageView!
    @IBOutlet weak var miniTitleLabel: UILabel!
    @IBOutlet weak var miniPlayPauseButton: UIButton! {
        didSet {
            //playPauseButton.setImage(UIImage(named: "pause"), for: .normal)
            miniPlayPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
            miniPlayPauseButton.transform = self.shrunkenTransform
            //Check
            //miniPlayPauseButton.imageEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
        }
    }
    @IBOutlet weak var miniFastForwadButton: UIButton! {
        didSet {
            seekToTime(delta: 15)
            miniFastForwadButton.transform = self.shrunkenTransform
            //Check
//            miniFastForwardButton.imageEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
//            miniFastForwardButton.addTarget(self, action: #selector(handleFastForward(_:)), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var miniPlayerView: UIView!
    @IBOutlet weak var maximizedStackView: UIStackView!
    
    @IBAction func handleCurrentTimeSliderChange(_ sender: Any) {
        
        let percentage = currentTimeSlider.value
        guard let duration = player.currentItem?.duration else { return }
        let durationInSeconds = CMTimeGetSeconds(duration)
        let seekTimeInSeconds = Float64(percentage) * durationInSeconds
        let seekTime = CMTimeMakeWithSeconds(seekTimeInSeconds, preferredTimescale: 1)
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = seekTime //seekTimeInSeconds
        player.seek(to: seekTime)
    }
    
    @IBAction func handleFastForward(_ sender: Any) {
        seekToTime(delta: 15)
    }
    
    @IBAction func handleRewind(_ sender: Any) {
        seekToTime(delta: -15)
    }
    
    fileprivate func seekToTime(delta: Float64) {
        
        let fifteenSeconds = CMTimeMakeWithSeconds(delta, preferredTimescale: 1)
        let seekTime = CMTimeAdd(player.currentTime(), fifteenSeconds)
        player.seek(to: seekTime)
    }
    
    // Compare with the one above
//    fileprivate func seekToCurrentTime(delta: Int64) {
//        let fifteenSeconds = CMTimeMake(delta, 1)
//        let seekTime = CMTimeAdd(player.currentTime(), fifteenSeconds)
//        player.seek(to: seekTime)
//    }
    
    @IBAction func handleVolumeChange(_ sender: UISlider) {
        player.volume = sender.value
    }
    
    @IBOutlet weak var currentTimeSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBAction func handleDismiss(_ sender: Any) {
        
        let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController
        mainTabBarController?.minimizePlayerDetails()
    }
    
    fileprivate func enlargeEpisodeImageView() {
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.episodeImageView.transform = .identity
        })
    }
    
    fileprivate let shrunkenTransform = CGAffineTransform(scaleX: 0.7, y: 0.7)
    
    fileprivate func shrinkEpisodeImageView() {
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.episodeImageView.transform = self.shrunkenTransform
        })
    }
    
    @IBOutlet weak var episodeImageView: UIImageView! {
        didSet {
            episodeImageView.layer.cornerRadius = 5
            episodeImageView.clipsToBounds = true
            episodeImageView.transform = shrunkenTransform
        }
    }
    
    @IBOutlet weak var playPauseButton: UIButton! {
        didSet {
            playPauseButton.setImage(UIImage(named: "pause"), for: .normal)
            playPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        }
    }
    
    @objc func handlePlayPause() {
        
        if player.timeControlStatus == .playing {
            player.pause()
            playPauseButton.setImage(UIImage(named: "play"), for: .normal)
            miniPlayPauseButton.setImage(UIImage(named: "play"), for: .normal)
            shrinkEpisodeImageView()
            setupElapsedTime(playbackRate: 0)
        } else if player.timeControlStatus == .paused {
            player.play()
            playPauseButton.setImage(UIImage(named: "pause"), for: .normal)
            miniPlayPauseButton.setImage(UIImage(named: "pause"), for: .normal)
            enlargeEpisodeImageView()
            setupElapsedTime(playbackRate: 1)
        }
    }
    
    @IBOutlet weak var authorLabel: UILabel!
    
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.numberOfLines = 2
        }
    }
}
