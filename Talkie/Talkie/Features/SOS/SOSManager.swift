//
//  SOSManager.swift
//  Talkie
//
//  Created by DS on 7/19/26.   	
//

import Foundation
import MessageUI
import Observation

@MainActor
@Observable
final class SOSManager {
    var isLoading: Bool = false
    var currentError: SOSError?
    var hasEmergencyContacts: Bool = true
    var shouldShowMessageCompose: Bool = false
    var messageComposeMode: SOSMessageComposeMode = .locationShare
    var messageRecipients: [String] = []
    var messageBody: String = ""
    
    var locationError: SOSError? {
        currentError
    }
    
    @ObservationIgnored
    private let locationService = SOSLocationService()
    
    @ObservationIgnored
    private var pendingMessageRequest: SOSMessageRequest?
    
    func shareLocationToContacts(safetyContacts: [SafetyContact]) {
        guard !isLoading else {
            return
        }
        
        currentError = nil
        
        let recipients = safetyContacts
            .map(\.phoneNumber)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        guard !recipients.isEmpty else {
            hasEmergencyContacts = false
            currentError = .noEmergencyContacts
            return
        }
        
        guard MFMessageComposeViewController.canSendText() else {
            currentError = .messageUnavailable
            return
        }
        
        hasEmergencyContacts = true
        pendingMessageRequest = SOSMessageRequest(
            mode: .locationShare,
            recipients: recipients
        )
        requestLocationForPendingMessage()
    }
    
    func sendEmergencySMS112() {
        guard !isLoading else {
            return
        }
        
        currentError = nil
        
        guard MFMessageComposeViewController.canSendText() else {
            currentError = .messageUnavailable
            return
        }

        guard let emergencyNumber = SOSEmergencyDestination.phoneNumber else {
            currentError = .testEmergencyNumberNotConfigured
            return
        }
        
        pendingMessageRequest = SOSMessageRequest(
            mode: .emergencySMS112,
            recipients: [emergencyNumber]
        )
        requestLocationForPendingMessage()
    }
    
    func callEmergencyServices() {
        currentError = nil

        guard let emergencyNumber = SOSEmergencyDestination.phoneNumber else {
            currentError = .testEmergencyNumberNotConfigured
            return
        }
        
        SOSEmergencyCallService.call(
            phoneNumber: emergencyNumber
        ) { [weak self] didOpen in
            Task { @MainActor in
                guard !didOpen else {
                    return
                }
                
                self?.currentError = .cannotMakePhoneCall
            }
        }
    }
    
    func call112() {
        callEmergencyServices()
    }
    
    private func requestLocationForPendingMessage() {
        guard let pendingMessageRequest else {
            finishLocationRequest(with: .locationUnavailable)
            return
        }
        
        isLoading = true
        
        locationService.requestCurrentLocation(
            onSuccess: { [weak self] coordinate in
                guard let self else {
                    return
                }
                
                let mapLink = SOSMessageBuilder.googleMapsLink(from: coordinate)
                self.messageComposeMode = pendingMessageRequest.mode
                self.messageRecipients = pendingMessageRequest.recipients
                self.messageBody = SOSMessageBuilder.messageBody(
                    mode: pendingMessageRequest.mode,
                    mapLink: mapLink
                )
                self.pendingMessageRequest = nil
                self.isLoading = false
                self.shouldShowMessageCompose = true
            },
            onFailure: { [weak self] error in
                self?.finishLocationRequest(with: error)
            }
        )
    }
    
    private func finishLocationRequest(with error: SOSError) {
        isLoading = false
        pendingMessageRequest = nil
        currentError = error
    }
}
