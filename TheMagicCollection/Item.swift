//
//  Item.swift
//  TheMagicCollection
//
//  Created by Adam Jolicoeur on 11/23/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
