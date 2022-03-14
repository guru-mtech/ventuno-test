//
//  ViewController.swift
//  VideoStream
//
//  Created by waioz on 13/03/22.
//

import UIKit
import AVFoundation

/*MARK: Offline Video Playback*/

class ViewController: UIViewController {
    //MARK: Outlets
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var videoPlayer: UIView!
    
    //MARK: Variables
//    private let videoURL = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
//
    private let videoURL = "https://v2s3z9v2.stackpathcdn.com/videos/output_03112021.mp4"
    //MARK: Video Component
    private var player : AVPlayer!
    
//    var configuration: URLSessionConfiguration?
//    var downloadSession: AVAssetDownloadURLSession?
    var downloadIdentifier = "\(Int(Date().timeIntervalSince1970))"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupPlayer(offlineURL: URL(string: videoURL)!)
        self.restorePendingDownloads()
    }
}

/*MARK: This Extension is having a triggered Actions of each components*/
extension ViewController {
    @IBAction func muteAction(_ sender: UIButton) {
        self.player.isMuted = !self.player.isMuted
        sender.setTitle(self.player.isMuted ? "Unmute" : "Mute", for: .normal)
    }
    @IBAction func playOrPause(_ sender: Any) {
        self.player.timeControlStatus == .paused ? self.player.play() : self.player.pause()
    }
    @IBAction func download(_ sender: Any) {
        self.progressView.isHidden = false
        downloadVideo()
    }
}
/*MARK: This Extension is having basic configuration functions*/
extension ViewController {
    /*MARK: SETUP Player*/
    func setupPlayer(offlineURL : URL){
        self.player = AVPlayer(url: offlineURL)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.videoPlayer.frame
        self.videoPlayer.layer.addSublayer(playerLayer)
        self.player.play()
    }
    
    /*MARK: Download Video*/

    func downloadVideo() {
        // Create new background session configuration.
        let configuration = URLSessionConfiguration.background(withIdentifier: downloadIdentifier)
      
        // Create a new AVAssetDownloadURLSession with background configuration, delegate, and queue
        let downloadSession = AVAssetDownloadURLSession(configuration: configuration,
                                                    assetDownloadDelegate: self,
                                                    delegateQueue: OperationQueue.main)
       

    
        if let url = URL(string: videoURL){
            var urlComponents = URLComponents(
                        url: url,
                        resolvingAgainstBaseURL: false
                )!
            urlComponents.scheme = "nothttps"
            let asset = AVURLAsset(url: urlComponents.url!)
            
            // Create new AVAssetDownloadTask for the desired asset
            let downloadTask = downloadSession.makeAssetDownloadTask(asset: asset,
                                                                      assetTitle: "MyDownloadTask",
                                                                      assetArtworkData: nil,
                                                                      options: nil)
            // Start task and begin download
            downloadTask?.resume()
        }
    }//end method
    
    /*MARK: Handle Download Complete*/

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        // Do not move the asset from the download location
        UserDefaults.standard.set(location.relativePath, forKey: "assetPath")
        self.setupPlayer(offlineURL: location)
    }
    
    /*MARK: Resume Download*/

    func restorePendingDownloads() {
        // Create session configuration with ORIGINAL download identifier
        let configuration = URLSessionConfiguration.background(withIdentifier: downloadIdentifier)
        
        // Create a new AVAssetDownloadURLSession
        let downloadSession = AVAssetDownloadURLSession(configuration: configuration,
                                                    assetDownloadDelegate: self,
                                                    delegateQueue: OperationQueue.main)
        
        // Grab all the pending tasks associated with the downloadSession
        downloadSession.getAllTasks { tasksArray in
            // For each task, restore the state in the app
            for task in tasksArray {
                guard let downloadTask = task as? AVAssetDownloadTask else { break }
                downloadTask.resume()
            }
        }
    }
    
}

/*MARK: It Deals the Session Delegates*/
extension ViewController : AVAssetDownloadDelegate{
    //MARK: Track the Download Progress
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        var percentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange = value.timeRangeValue
            percentComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        percentComplete *= 100
        progressView.progress = Float(percentComplete / 100.0)
    }
}

