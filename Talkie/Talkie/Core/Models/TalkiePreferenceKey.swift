//
//  TalkiePreferenceKey.swift
//  Talkie
//

import Foundation

/// 여러 화면이 같은 UserDefaults 설정을 읽도록 키를 한 곳에서 관리합니다.
enum TalkiePreferenceKey {
    static let automaticCallRecordingEnabled = "automaticCallRecordingEnabled"
    static let iCloudSyncEnabled = "iCloudSyncEnabled"
    static let didAcknowledgeICloudRecordingSync = "didAcknowledgeICloudRecordingSync"
    static let widgetCallRequestID = "widgetCallRequestID"
}
