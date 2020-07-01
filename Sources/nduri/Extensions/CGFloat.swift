//
//  CGFloat.swift
//
//  Created by Moritz Herbert on 01.07.20.
//

import UIKit

extension CGFloat {
    var stringValue: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 3
        numberFormatter.maximumFractionDigits = 3

        return numberFormatter.string(from: NSNumber(nonretainedObject: self)) ?? ""
    }
}
