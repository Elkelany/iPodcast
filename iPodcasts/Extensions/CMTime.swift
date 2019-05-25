//
//  CMTime.swift
//  iPodcasts
//
//  Created by macOS on 3/11/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import AVKit

extension CMTime {
    
    func toStringFormat() -> String {
        
        if CMTimeGetSeconds(self).isNaN {
            return "--:--"
        }
        
        let totalSeconds = Int(CMTimeGetSeconds(self))
        let seconds = totalSeconds % 60
        let minutes = totalSeconds % (60 * 60) / 60
        let hours = totalSeconds / 60 / 60
        var timeFormatString = ""
        
        if hours >= 1 {
            timeFormatString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            timeFormatString = String(format: "%02d:%02d", minutes, seconds)
        }
        
        return timeFormatString
    }
    
}
