//
//  String.swift
//  iPodcasts
//
//  Created by macOS on 3/10/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import Foundation

extension String {
    func toSecureHTTPS() -> String {
        return self.contains("https") ? self : self.replacingOccurrences(of: "http", with: "https")
    }
}
