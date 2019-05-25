//
//  UserDefaults.swift
//  iPodcasts
//
//  Created by macOS on 3/13/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    static let favoritePodcastKey = "favoritePodcastKey"
    static let downloadedEpisodesKey = "downloadedEpisodesKey"
    
    func downloadEpisode(episode: Episode) {
        do {
            var episodes = downloadedEpisodes()
            episodes.append(episode)
//            insert episode at the front of the list
//            episodes.insert(episode, at: 0)
            let data = try JSONEncoder().encode(episodes)
            UserDefaults.standard.set(data, forKey: UserDefaults.downloadedEpisodesKey)
        } catch let encodeError {
            print("Download Encoding Error:", encodeError)
        }
    }
    
    func downloadedEpisodes() -> [Episode] {
        guard let episodesData = data(forKey: UserDefaults.downloadedEpisodesKey) else { return [] }
        do {
            let episodes = try JSONDecoder().decode([Episode].self, from: episodesData)
            return episodes
        } catch let decodeError {
            print("Decoding Error: ", decodeError)
        }
        return []
    }

    func savedPodcasts() -> [Podcast] {
        guard let savedPodcastsData = UserDefaults.standard.data(forKey: UserDefaults.favoritePodcastKey) else { return [] }
        guard let savedPodcasts = NSKeyedUnarchiver.unarchiveObject(with: savedPodcastsData) as? [Podcast] else { return [] }
        
        return savedPodcasts
    }
    
    func deletePodcast(podcast: Podcast) {
        let podcasts = savedPodcasts()
        let filteredPodcasts = podcasts.filter { (pdcst) -> Bool in
            return pdcst.trackName != podcast.trackName && pdcst.artistName != podcast.artistName
        }
        let data = NSKeyedArchiver.archivedData(withRootObject: filteredPodcasts)
        UserDefaults.standard.set(data, forKey: UserDefaults.favoritePodcastKey)
    }
    
    func deleteEpisode(episode: Episode) {
        let episodes = downloadedEpisodes()
        let filteredEpisodes = episodes.filter { (ep) -> Bool in
            return ep.title != episode.title && ep.author != episode.author
        }
        do {
            let data = try JSONEncoder().encode(filteredEpisodes)
            UserDefaults.standard.set(data, forKey: UserDefaults.downloadedEpisodesKey)
        } catch let encodeError {
            print("Deletion Encoding Error:", encodeError)
        }
    }
}
