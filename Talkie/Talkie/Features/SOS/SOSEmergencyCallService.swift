//
//  SOSEmergencyCallService.swift
//  Talkie
//
//  Created by DS on 7/19/26.
//

import Foundation
import UIKit

enum SOSEmergencyCallService {
    static func call112(
        completion: @escaping (Bool) -> Void
    ) {
        guard let phoneURL = URL(string: "tel:112"),
              UIApplication.shared.canOpenURL(phoneURL) else {
            completion(false)
            return
        }
        
        UIApplication.shared.open(phoneURL) { didOpen in
            completion(didOpen)
        }
    }
}
