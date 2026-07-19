//
//  SOSLocationService.swift
//  Talkie
//
//  Created by DS on 7/19/26.
//

import CoreLocation
import Foundation

@MainActor
final class SOSLocationService: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var locationRequestID: UUID?
    private var onSuccess: ((CLLocationCoordinate2D) -> Void)?
    private var onFailure: ((SOSError) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestCurrentLocation(
        onSuccess: @escaping (CLLocationCoordinate2D) -> Void,
        onFailure: @escaping (SOSError) -> Void
    ) {
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        
        handleAuthorizationStatus()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard onSuccess != nil, onFailure != nil else {
            return
        }
        
        handleAuthorizationStatus()
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let coordinate = locations.last?.coordinate else {
            finishWithFailure(.locationUnavailable)
            return
        }
        
        let success = onSuccess
        resetRequestState()
        success?(coordinate)
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        finishWithFailure(.locationUnavailable)
    }
    
    private func handleAuthorizationStatus() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationRequest()
        case .denied, .restricted:
            finishWithFailure(.locationPermissionDenied)
        @unknown default:
            finishWithFailure(.locationUnavailable)
        }
    }
    
    private func startLocationRequest() {
        let requestID = UUID()
        locationRequestID = requestID
        locationManager.requestLocation()
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(10))
            
            guard locationRequestID == requestID else {
                return
            }
            
            finishWithFailure(.locationUnavailable)
        }
    }
    
    private func finishWithFailure(_ error: SOSError) {
        let failure = onFailure
        resetRequestState()
        failure?(error)
    }
    
    private func resetRequestState() {
        locationRequestID = nil
        onSuccess = nil
        onFailure = nil
    }
}
