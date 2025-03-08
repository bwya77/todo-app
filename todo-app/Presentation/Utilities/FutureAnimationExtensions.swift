//
//  FutureAnimationExtensions.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/8/25.
//

import SwiftUI

/// This file will contain extensions for the AnimateText library when it's integrated
/// in the future. Currently we're using our custom MonthAnimator implementation.

// Extension placeholder for future use
extension MonthAnimator {
    /// Convenience method for standardized animation settings
    static func standardMonthEffect(text: String) -> MonthAnimator {
        return MonthAnimator(
            text: text,
            animateByCharacter: false,
            height: 30,
            duration: 0.3
        )
    }
}
