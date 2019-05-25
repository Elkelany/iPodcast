//
//  DownloadsController.swift
//  iPodcasts
//
//  Created by macOS on 3/13/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import UIKit

class DownloadsController: UITableViewController {
    
    let cellId = "cellId"
    
    var episodes = UserDefaults.standard.downloadedEpisodes()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupObservers()
    }
    
    fileprivate func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleDownloadProgress), name: .downloadProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDownloadComplete), name: .downloadComplete, object: nil)
    }
    
    @objc fileprivate func handleDownloadComplete(notification: Notification) {
        
        guard let episodeDownloadComplete = notification.object as? APIService.EpisodeDownloadCompleteTuple else { return }
        
        guard let index = episodes.index(where: { $0.title == episodeDownloadComplete.episodeTitle }) else { return }
        
        episodes[index].fileUrl = episodeDownloadComplete.fileUrl
    }
    
    @objc fileprivate func handleDownloadProgress(notification: Notification) {
        
        guard let userInfo = notification.userInfo as? [String: Any] else { return }
        guard let title = userInfo["title"] as? String else { return }
        guard let progress = userInfo["progress"] as? Double else { return }
        
        guard let index = episodes.index(where: { $0.title == title }) else { return }
        guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? EpisodeCell else { return }
        cell.progressLabel.isHidden = false
        
        cell.progressLabel.text = "\(Int(progress * 100))%"
        
        if progress == 1 {
            cell.progressLabel.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        episodes = UserDefaults.standard.downloadedEpisodes()
        tableView.reloadData()
        
    }
    
    // MARK:- Setup Functions
    
    fileprivate func setupTableView() {
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
    }
    
    // MARK:- UITableView
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let episode = episodes[indexPath.row]

        if episode.fileUrl != nil {
            UIApplication.mainTabBarController()?.maximizePlayerDetails(episode: episode, playlistEpisodes: episodes)
        } else {
            
            let alertController = UIAlertController(title: "File URL not found", message: "Cannot find local file, play using stream URL instead?", preferredStyle: .actionSheet)
            
            alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
                UIApplication.mainTabBarController()?.maximizePlayerDetails(episode: episode, playlistEpisodes: self.episodes)
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive))
            
            present(alertController, animated: true)
        }
        
        
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (_, _) in
            let selectedIndex = indexPath.row
            UserDefaults.standard.deleteEpisode(episode: self.episodes[selectedIndex])
            self.episodes.remove(at: selectedIndex)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        return [deleteAction]
    }
    // The following code may replace the above function
    /*
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     let episode = self.episodes[indexPath.row]
     episodes.remove(at: indexPath.row)
     tableView.deleteRows(at: [indexPath], with: .automatic)
     UserDefaults.standard.deleteEpisode(episode: episode)
     }
     */
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! EpisodeCell
        cell.episode = episodes[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 134
    }
    
}
