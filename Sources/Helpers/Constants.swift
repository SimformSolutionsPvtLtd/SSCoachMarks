//
//  Constants.swift
//  SSCoachMarksDemo
//
//  Created by Yagnik Bavishi on 21/08/24.
//

import Foundation

/// A struct containing various constant values used throughout the CoachMarkView implementation.
///
/// These constants help maintain consistency and reduce magic numbers across the codebase.
public struct Constants {
    
    /// The default duration for automatic transitions, in seconds.
    public static let defaultAutoTransitionDuration: Double = 2.0
    
    /// The screen size used for the highlight view overlay, in points.
    static let highlightViewOverlayScreenSize: CGFloat = 500
    
    /// The spacing for the reverse mask in the highlight view, in points.
    static let highlightViewReverseMaskSpacing: CGFloat = 5
    
    /// The offset for the reverse mask in the highlight view, in points.
    static let highlightViewReverseMaskOffSet = 2.5
    
    /// The delay before animating the button click, in seconds.
    static let buttonClickedAnimationDelay = 0.25
    
    /// The delay before showing the CoachMarkView, in seconds.
    static let showCoachMarkViewDelay = 0.6
    
    /// The initial delay before showing the CoachMarkView for the first time, in seconds.
    static let showCoachMarkViewInitialDelay = 0.1
    
    /// The spacing between clear color areas in the highlight view, in points.
    static let highlightViewClearColorSpacing: CGFloat = 20
    
    /// The offset for the popover, in points.
    static let popOverOffset: CGFloat = 10
    
    /// The offset for the scroll view, in points.
    static let scrollViewOffset: CGFloat = 100
    
    /// The default font size for the coach mark title, in points.
    static let coachMarkTitleDefaultFontSize: CGFloat = 18
    
    /// The default font size for the coach mark description, in points.
    static let coachMarkDescriptionDefaultFontSize: CGFloat = 17
    
    /// The default font size for buttons, in points.
    static let buttonsDefaultFontSize: CGFloat = 12
    
    /// The default value for the overlay style's opacity.
    static let overlayStyleDefaultValue = 0.7
    
    /// Default text for the "Next" button in the CoachMarkView.
    static let nextButtonDefaultText: String = "Next"
     
    /// Default text for the "Back" button in the CoachMarkView.
    static let backButtonDefaultText: String = "Back"
    
    /// Default text for the "Done" button in the CoachMarkView.
    static let doneButtonDefaultText: String = "Done"
    
    /// Default text for the "Skip" button in the CoachMarkView.
    static let skipCoachMarkButtonDefaultText: String = "Skip"
        
}
