//
//  UIApplication.swift
//  iPodcasts
//
//  Created by macOS on 3/12/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import UIKit

extension UIApplication {
    static func mainTabBarController() -> MainTabBarController? {
        return shared.keyWindow?.rootViewController as? MainTabBarController
    }
}
