//
//  SOSManager.swift
//  Talkie
//
//  Created by DS on 7/19/26.   	
//

import Foundation
import CoreLocation
import MessageUI
import Observation

enum SOSError: Error {
    case locationPermissionDenied
    case locationUnavailable
    case noEmergencyContacts
    case messageUnavailable
    
    var message: String {
        switch self {
        case .locationPermissionDenied:
            return "위치 권한이 허용되지 않았습니다."
        case .locationUnavailable:
            return "현재 위치를 가져올 수 없습니다."
        case .noEmergencyContacts:
            return "등록된 안전 연락망이 없습니다."
        case .messageUnavailable:
            return "이 기기에서는 문자 메시지를 보낼 수 없습니다."
        }
    }
}

@MainActor
@Observable
final class SOSManager: NSObject, CLLocationManagerDelegate {
    var isLoading: Bool = false
    var locationError: SOSError?
    var hasEmergencyContacts: Bool = true
    var shouldShowMessageCompose: Bool = false
    var messageRecipients: [String] = []
    var messageBody: String = ""
    
    @ObservationIgnored
    private let locationManager = CLLocationManager()
    
    @ObservationIgnored
    private var pendingRecipients: [String] = []
    
    @ObservationIgnored
    private var locationRequestID: UUID?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func shareLocationToContacts(emergencyContacts: [EmergencyContact]) {
        guard !isLoading else {
            return
        }
        
        locationError = nil
        
        let recipients = emergencyContacts
            .map(\.phoneNumber)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        guard !recipients.isEmpty else {
            hasEmergencyContacts = false
            locationError = .noEmergencyContacts
            return
        }
        
        guard MFMessageComposeViewController.canSendText() else {
            locationError = .messageUnavailable
            return
        }
        
        hasEmergencyContacts = true
        pendingRecipients = recipients
        handleLocationAuthorizationStatus()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleLocationAuthorizationStatus()
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else {
            finishLocationRequest(with: .locationUnavailable)
            return
        }
        
        let mapLink = makeGoogleMapsLink(from: location.coordinate)
        messageRecipients = pendingRecipients
        messageBody = makeLocationShareMessage(mapLink: mapLink)
        pendingRecipients = []
        isLoading = false
        locationRequestID = nil
        shouldShowMessageCompose = true
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        finishLocationRequest(with: .locationUnavailable)
    }
    
    private func handleLocationAuthorizationStatus() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            requestCurrentLocation()
        case .denied, .restricted:
            finishLocationRequest(with: .locationPermissionDenied)
        @unknown default:
            finishLocationRequest(with: .locationUnavailable)
        }
    }
    
    private func requestCurrentLocation() {
        let requestID = UUID()
        locationRequestID = requestID
        isLoading = true
        locationManager.requestLocation()
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(10))
            
            guard locationRequestID == requestID else {
                return
            }
            
            finishLocationRequest(with: .locationUnavailable)
        }
    }
    
    private func finishLocationRequest(with error: SOSError) {
        isLoading = false
        locationRequestID = nil
        pendingRecipients = []
        locationError = error
    }
    
    private func makeGoogleMapsLink(from coordinate: CLLocationCoordinate2D) -> String {
        "https://maps.google.com/?q=\(coordinate.latitude),\(coordinate.longitude)"
    }
    
    private func makeLocationShareMessage(mapLink: String) -> String {
        """
        [Talkie 위치 공유 알림] 현재 위험한 상황일 수 있습니다. 아래 링크에서 위치를 확인해주세요.
        현재 위치: \(mapLink)
        """
    }
    
    func sendEmergencySMS112() {
        print("112 문자 신고 트리거")
    }
    
    func call112() {
        print("112 전화 연결 트리거")
    }
}
