//
//  SOSEmergencyCallService.swift
//  Talkie
//
//  Created by DS on 7/19/26.
//

import Foundation
import UIKit

enum SOSEmergencyCallService {
    @MainActor
    static func call(phoneNumber: String) async -> Bool {
        guard let phoneURL = URL(string: "tel:\(phoneNumber)"),
              UIApplication.shared.canOpenURL(phoneURL) else {
            return false
        }

        return await withCheckedContinuation { continuation in
            UIApplication.shared.open(phoneURL) { didOpen in
                continuation.resume(returning: didOpen)
            }
        }
    }
}
