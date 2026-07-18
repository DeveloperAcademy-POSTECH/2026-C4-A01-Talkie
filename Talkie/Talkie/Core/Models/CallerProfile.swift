//
//  CallerProfile.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import Foundation
import SwiftData

@Model
final class CallerProfile {
    var name: String
    var scenario: Scenario?
    
    init(name: String) {
        self.name = name
    }
}


//@Model
//final class CallerProfileModel {
//    var name: String
//    
//    init(name: String) {
//        self.name = name
//    }
//}
