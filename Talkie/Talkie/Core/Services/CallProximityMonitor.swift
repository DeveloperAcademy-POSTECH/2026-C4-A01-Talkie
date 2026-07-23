//
//  CallProximityMonitor.swift
//  Talkie
//

import UIKit

/// 가상 통화 중 iPhone의 시스템 근접 센서를 실제 전화처럼 운용합니다.
///
/// `UIDevice`의 proximity monitoring을 켜면 얼굴이나 물체가 센서 가까이에 있을 때
/// iOS가 화면을 blank 처리해 실수로 화면을 누르는 입력을 막습니다. 앱이 밝기나
/// hit testing을 직접 바꾸지 않으므로 센서에서 멀어지면 시스템이 화면을 복원합니다.
@MainActor
final class CallProximityMonitor {
    private let device: UIDevice

    init() {
        device = .current
    }

    init(device: UIDevice) {
        self.device = device
    }

    /// 통화 중이고 수화부를 사용할 때만 근접 모니터링을 활성화합니다.
    /// 스피커 통화에서는 사용자가 화면을 보며 조작할 수 있도록 즉시 해제합니다.
    func update(isCallActive: Bool, isSpeakerEnabled: Bool) {
        let shouldEnable = isCallActive && !isSpeakerEnabled
        guard device.isProximityMonitoringEnabled != shouldEnable else { return }

        device.isProximityMonitoringEnabled = shouldEnable
        // 센서가 없는 기기는 true를 요청해도 값이 false로 유지됩니다. 이 경우 별도
        // fallback UI를 만들지 않고 기존 통화 화면과 터치 동작을 그대로 사용합니다.
    }

    /// 종료·거절·실패·다음 통화 준비 경로에서 호출해 시스템 센서 상태를 원복합니다.
    func stop() {
        guard device.isProximityMonitoringEnabled else { return }
        device.isProximityMonitoringEnabled = false
    }
}
