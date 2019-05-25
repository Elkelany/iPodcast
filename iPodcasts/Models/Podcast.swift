//
//  Podcast.swift
//  iPodcasts
//
//  Created by macOS on 3/6/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import UIKit

class Podcast: NSObject, Decodable, NSCoding {
    func encode(with aCoder: NSCoder) {
        aCoder.encode(trackName ?? "", forKey: "trackNameKey")
        aCoder.encode(artistName ?? "", forKey: "artistNameKey")
        aCoder.encode(artworkUrl600 ?? "", forKey: "artworkUrl600Key")
        aCoder.encode(feedUrl ?? "", forKey: "feedUrlKey")
    }
    
    required init?(coder aDecoder: NSCoder) {
        trackName = aDecoder.decodeObject(forKey: "trackNameKey") as? String
        artistName = aDecoder.decodeObject(forKey: "artistNameKey") as? String
        artworkUrl600 = aDecoder.decodeObject(forKey: "artworkUrl600Key") as? String
        feedUrl = aDecoder.decodeObject(forKey: "feedUrlKey") as? String
    }
    
    
    var trackName: String?
    var artistName: String?
    var artworkUrl600: String?
    var trackCount: Int?
    var feedUrl: String?
}
