//
//  MessageComposerView.swift
//  Talkie
//
//  Created by DS on 7/19/26.
//

import SwiftUI
import MessageUI

struct MessageComposerView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    let onFinish: () -> Void
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let viewController = MFMessageComposeViewController()
        viewController.messageComposeDelegate = context.coordinator
        viewController.recipients = recipients
        viewController.body = body
        return viewController
    }
    
    func updateUIViewController(
        _ uiViewController: MFMessageComposeViewController,
        context: Context
    ) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }
}

extension MessageComposerView {
    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onFinish: () -> Void
        
        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }
        
        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            controller.dismiss(animated: true)
            onFinish()
        }
    }
}
