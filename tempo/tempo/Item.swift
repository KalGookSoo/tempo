//
//  Item.swift
//  tempo
//
//  Created by doyevskyi on 8/12/26.
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
