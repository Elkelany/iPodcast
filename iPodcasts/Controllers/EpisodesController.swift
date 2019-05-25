//
//  EpisodesController.swift
//  iPodcasts
//
//  Created by macOS on 3/10/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import UIKit
import FeedKit

class EpisodesController: UITableViewController {
    
    var podcast: Podcast? {
        didSet {
            navigationItem.title = podcast?.trackName
            fetchEpisodes()
        }
    }
    
    fileprivate func fetchEpisodes() {
        
        guard let feedUrl = podcast?.feedUrl else { return }
        
        APIService.shared.fetchEpisodes(feedUrl: feedUrl) { (episodes) in
            
            self.episodes = episodes
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    fileprivate let cellId = "cellId"
    
    var episodes = [Episode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBarButtons()
    }
    
    //MARK:- Setup Work
    
    fileprivate func setupNavigationBarButtons() {
        
        let savedPodcasts = UserDefaults.standard.savedPodcasts()
        
        if savedPodcasts.index(where: { $0.trackName == self.podcast?.trackName && $0.artistName == self.podcast?.artistName}) != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "heart"), style: .plain, target: nil, action: nil)
        } else {
            navigationItem.rightBarButtonItems = [
                UIBarButtonItem(title: "Favorite", style: .plain, target: self, action: #selector(handleSaveFavorite)), //UIBarButtonItem(title: "Fetch", style: .plain, target: self, action: #selector(handleFetchSavedPodcasts))
                
            ]
        }
    }
    
    // The following function might need to be deleted along with its caller commented above
    @objc fileprivate func handleFetchSavedPodcasts() {
        guard let data = UserDefaults.standard.data(forKey: UserDefaults.favoritePodcastKey) else { return }
        let savedPodcasts = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Podcast]
    }
    
    @objc fileprivate func handleSaveFavorite() {
        guard let podcast = self.podcast else { return }
        var listOfPodcasts = UserDefaults.standard.savedPodcasts()
        listOfPodcasts.append(podcast)
        let data = NSKeyedArchiver.archivedData(withRootObject: listOfPodcasts)
        UserDefaults.standard.set(data, forKey: UserDefaults.favoritePodcastKey)
        
        showBadgeHighlight()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "heart"), style: .plain, target: nil, action: nil)
    }
    
    fileprivate func showBadgeHighlight() {
        UIApplication.mainTabBarController()?.viewControllers?[1].tabBarItem.badgeValue = "New"
    }
    
    fileprivate func setupTableView() {
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
        tableView.tableFooterView = UIView()
    }
    
    //MARK:- UITableView
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let downloadAction = UITableViewRowAction(style: .normal, title: "Download") { (_, _) in
            UserDefaults.standard.downloadEpisode(episode: self.episodes[indexPath.row])
            APIService.shared.downloadEpisode(episode: self.episodes[indexPath.row])
        }
        return [downloadAction]
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let activityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicatorView.color = .darkGray
        activityIndicatorView.startAnimating()
        
        return activityIndicatorView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return episodes.isEmpty ? 200 : 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let episode = episodes[indexPath.row]
        //////////
        UIApplication.mainTabBarController()?.maximizePlayerDetails(episode: episode, playlistEpisodes: self.episodes)
        
        //Check the following logic
        
//        let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController
//        mainTabBarController?.maximizePlayerDetails(episode: episode, playlistEpisodes: self.episodes)
        
//        let episode = episodes[indexPath.row]
//        print("Trying to play episode: ", episode.title)
//
//        let window = UIApplication.shared.keyWindow
//
//        let playerDetailsView = PlayerDetailsView.initFromNib()
//
//        playerDetailsView.episode = episode
//
//        playerDetailsView.frame = self.view.frame
//        window?.addSubview(playerDetailsView)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! EpisodeCell
        let episode = episodes[indexPath.row]
        cell.episode = episode

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 134
    }
    
}
