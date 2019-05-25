//
//  Episode.swift
//  iPodcasts
//
//  Created by macOS on 3/10/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import Foundation
import FeedKit

struct Episode: Codable {
    let title: String
    let pubDate: Date
    let description: String
    var imageUrl: String?
    var fileUrl: String?
    let author: String
    let streamUrl: String
    
    init(feedItem: RSSFeedItem) {
        title = feedItem.title ?? ""
        pubDate = feedItem.pubDate ?? Date()
        description = feedItem.description ?? "" //feedItem.iTunes?.iTunesSubtitle ??
        imageUrl = feedItem.iTunes?.iTunesImage?.attributes?.href
        author = feedItem.iTunes?.iTunesAuthor ?? ""
        streamUrl = feedItem.enclosure?.attributes?.url ?? ""
    }
}
