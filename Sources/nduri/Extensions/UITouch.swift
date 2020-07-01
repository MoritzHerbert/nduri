//
//  UITouch.swift
//
//  Created by Moritz Herbert on 01.07.20.
//

import UIKit

extension UITouch {
    /// pass in window in case you dont know a more exact location to start searching for the very child view containing the touch
    func frameOfTouchedView(startingIn view: UIView) -> CGRect? {
        let absoluteLocation = location(in: nil)

        if view.subviews.isEmpty, view.frame.contains(absoluteLocation) {
            return view.frame
        }

        for (_, subview) in view.subviews.enumerated() {
            if subview.frame.contains(absoluteLocation) {
                return frameOfTouchedView(startingIn: subview)
            }
        }

        return UIApplication.shared.keyWindow?.frame ?? nil
    }
}
