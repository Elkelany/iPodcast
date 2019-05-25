//
//  EpisodeCell.swift
//  iPodcasts
//
//  Created by macOS on 3/10/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import UIKit

class EpisodeCell: UITableViewCell {
    
    var episode: Episode! {
        didSet {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyy"
            pubDateLabel.text = dateFormatter.string(from: episode.pubDate)
            titleLabel.text = episode.title
            descriptionLabel.text = episode.description
            let url = URL(string: episode.imageUrl?.toSecureHTTPS() ?? "")
            episodeImageView.sd_setImage(with: url, completed: nil)
        }
    }
    
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var episodeImageView: UIImageView!
    @IBOutlet weak var pubDateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.numberOfLines = 2
        }
    }
    @IBOutlet weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.numberOfLines = 2
        }
    }
}
