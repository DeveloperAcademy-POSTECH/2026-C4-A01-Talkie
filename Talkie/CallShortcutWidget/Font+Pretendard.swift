//
//  Font+Pretendard.swift
//  CallShortcutWidget
//
//  Created by DS on 7/23/26.
//

import SwiftUI

extension Font {
    enum PretendardWeight {
        case thin
        case extraLight
        case light
        case regular
        case medium
        case semiBold
        case bold
        case extraBold
        case black

        var name: String {
            switch self {
            case .thin:
                return "Pretendard-Thin"
            case .extraLight:
                return "Pretendard-ExtraLight"
            case .light:
                return "Pretendard-Light"
            case .regular:
                return "Pretendard-Regular"
            case .medium:
                return "Pretendard-Medium"
            case .semiBold:
                return "Pretendard-SemiBold"
            case .bold:
                return "Pretendard-Bold"
            case .extraBold:
                return "Pretendard-ExtraBold"
            case .black:
                return "Pretendard-Black"
            }
        }
    }

    static func pretendard(_ weight: PretendardWeight, size: CGFloat) -> Font {
        .custom(weight.name, size: size)
    }
}
