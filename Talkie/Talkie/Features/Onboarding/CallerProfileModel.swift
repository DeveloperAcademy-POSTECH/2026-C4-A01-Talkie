//
//  CallerProfileModel.swift
//  Talkie
//
//  Created by DS on 7/13/26.
//

import Foundation
import SwiftData

@Model
final class CallerProfileModel {
    var name: String
    
    init(name: String) {
        self.name = name
    }
}
