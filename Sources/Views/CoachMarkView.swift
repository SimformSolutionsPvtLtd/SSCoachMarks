//
//  CoachMarkView.swift
//  CoachworkDemo
//
//  Created by Yagnik Bavishi on 07/07/24.
//

import SwiftUI

// MARK: CoachMarkView
public struct CoachMarkView: ViewModifier {
    
    // MARK: - Variables
    
    /// A boolean indicating whether the coach mark should be shown. Default is true.
    public var isShowCoachMark: Bool = true
    
    /// A boolean indicating whether the coach mark transitions should occur automatically. Default is false. 
    public var isAutoTransition: Bool = false
    
    /// The duration (in seconds) for each automatic transition between coach marks. Default is 2.0 sec.
    public var autoTransitionDuration: Double = Constants.defaultAutoTransitionDuration
    
    /// An instance of `SSCoachMarkManager` that manages the CoachMark configuration and behaviour.
    public var coachMarkManager: SSCoachMarkManager = SSCoachMarkManager()
    
    /// A computed property that provides direct access to the `SSCoachMarkConfiguration` from `coachMarkManager`.
    /// - The `get` method returns the current configuration from `coachMarkManager`.
    /// - The `set` method allows updating the configuration of `coachMarkManager` with a new value.
    public var configuration: SSCoachMarkConfiguration {
        get {
            coachMarkManager.configuration
        }
        set {
            coachMarkManager.configuration = newValue
        }
    }
    
    /// This property can be used to subscribe to button event publishers and trigger events dynamically.
    public var buttonEventsCoordinator = ButtonEventsCoordinator()

    /// This property allows you to customize the appearance and behaviour of the "Skip" button by assigning any SwiftUI view to it. If `nil`, the default implementation will be used.
    public var skipCoachMarkButton: AnyView?
    
    /// This property allows you to customize the appearance and behavior of the "Next" button by assigning any SwiftUI view to it. If `nil`, the default implementation will be used.
    public var nextButtonContent: AnyView?
    
    /// This property allows you to customize the appearance and behavior of the "Back" button by assigning any SwiftUI view to it. If `nil`, the default implementation will be used.
    public var backButtonContent: AnyView?
    
    /// This property allows you to customize the appearance and behavior of the "Done" button by assigning any SwiftUI view to it. If `nil`, the default implementation will be used.
    public var doneButtonContent: AnyView?
    
    /// A closure that is called when the coach mark sequence finishes.
    public var onCoachMarkFinished: () -> ()
    
    /// A Boolean value that determines whether the Coach Mark should be shown. Defaults to `false`.
    @State var showCoachMark: Bool = false
    
    /// An integer value representing the index of the currently highlighted item in the Coach Mark sequence. Defaults to `0`.
    @State var currentHighlight: Int = 0
    
    /// A Boolean value that determines whether the Coach Mark should be hidden automatically. Defaults to `true`.
    @State var hideCoachMark: Bool = true
    
    /// An array of integers representing the order in which highlights are displayed.
    @State private var highlightOrder: [Int] = []
    
    /// A timer that can be used to control the duration and interval of automatic transitions between coach marks.
    @State private var timer: Timer?
    
    /// The height of the text description within the coach mark, used for layout purposes.
    @State private var descriptionTextHeight: CGFloat = 0
    
    /// Initializes a new `CoachMarkView` modifier with customizable behavior and appearance.
    ///
    /// - Parameters:
    ///   - isShowCoachMark: A Boolean value indicating whether the coach mark should be initially shown. Defaults to `true`.
    ///   - isAutoTransition: A Boolean value indicating whether transitions between coach marks should occur automatically. Defaults to `false`.
    ///   - autoTransitionDuration: The duration (in seconds) for each automatic transition. Defaults to `Constants.defaultAutoTransitionDuration`.
    ///   - coachMarkManager: An instance of `SSCoachMarkManager` that provides configuration for the coach mark. Defaults to a new instance.
    ///   - buttonEventsCoordinator: An instance of `ButtonEventsCoordinator` to handle button event coordination. Defaults to a new instance.
    ///   - skipCoachMarkButton: An optional custom SwiftUI view to replace the default "Skip" button.
    ///   - nextButtonContent: An optional custom SwiftUI view to replace the default "Next" button.
    ///   - backButtonContent: An optional custom SwiftUI view to replace the default "Back" button.
    ///   - doneButtonContent: An optional custom SwiftUI view to replace the default "Done" button.
    ///   - onCoachMarkFinished: A closure executed when the coach mark sequence is completed. Defaults to an empty closure.
    public init(
        isShowCoachMark: Bool = true,
        isAutoTransition: Bool = false,
        autoTransitionDuration: Double = Constants.defaultAutoTransitionDuration,
        coachMarkManager: SSCoachMarkManager = SSCoachMarkManager(),
        buttonEventsCoordinator: ButtonEventsCoordinator = ButtonEventsCoordinator(),
        skipCoachMarkButton: AnyView? = nil,
        nextButtonContent: AnyView? = nil,
        backButtonContent: AnyView? = nil,
        doneButtonContent: AnyView? = nil,
        onCoachMarkFinished: @escaping () -> () = {}
    ) {
        self.isShowCoachMark = isShowCoachMark
        self.isAutoTransition = isAutoTransition
        self.autoTransitionDuration = autoTransitionDuration
        self.coachMarkManager = coachMarkManager
        self.buttonEventsCoordinator = buttonEventsCoordinator
        self.skipCoachMarkButton = skipCoachMarkButton
        self.nextButtonContent = nextButtonContent
        self.backButtonContent = backButtonContent
        self.doneButtonContent = doneButtonContent
        self.onCoachMarkFinished = onCoachMarkFinished
    }

    public func body(content: Content) -> some View {
        content
            .onPreferenceChange(HighlightAnchorKey.self) { value in
                highlightOrder = Array(value.keys).sorted()
            }
            .overlayPreferenceValue(HighlightAnchorKey.self) { preference in
                if highlightOrder.indices.contains(currentHighlight), isShowCoachMark, hideCoachMark {
                    if let highlight = preference[highlightOrder[currentHighlight]] {
                        HighlightView(highlight: highlight)
                    }
                }
            }
            .onReceive(buttonEventsCoordinator.publisher(for: .next)) {
                nextButtonAction()
            }
            .onReceive(buttonEventsCoordinator.publisher(for: .back)) {
                backButtonAction()
            }
            .onReceive(buttonEventsCoordinator.publisher(for: .done)) {
                finishCoachMark()
            }
            .onReceive(buttonEventsCoordinator.publisher(for: .skip)) {
                finishCoachMark()
            }
    }
    
    // MARK: - Private Functions
    
    /// Creates a view that highlights a specified area on the screen and displays a coach mark with associated content.
    ///
    /// This function is used to create a view that overlays the entire screen, dimming the background and highlighting a specific area defined by the `highlight` parameter. It can display either a text description or a custom view within a popover, depending on the provided `Highlight` properties. The view also supports automatic transitions and manual navigation through different highlights.
    ///
    /// - Parameters:
    ///   - highlight: A `Highlight` object containing the details for the highlight, including the anchor for positioning, title, description, corner radius, style, scale, background color, and an optional custom view.
    ///
    /// - Returns: A view that highlights the specified area and displays associated content.
    @ViewBuilder
    private func HighlightView(highlight: Highlight) -> some View {
        GeometryReader { proxy in
            let highlightRect = proxy[highlight.anchor]
            let safeArea = proxy.safeAreaInsets
            let screenSize = proxy.size
            
            Rectangle()
                .fill(configuration.overlayStyle.overlayColor.opacity(configuration.overlayStyle.overlayOpacity))
                .frame(width: screenSize.width + Constants.highlightViewOverlayScreenSize, height: screenSize.height + Constants.highlightViewOverlayScreenSize)
                .reverseMask {
                    Rectangle()
                        .frame(width: highlightRect.width + Constants.highlightViewReverseMaskSpacing, height: highlightRect.height + Constants.highlightViewReverseMaskSpacing)
                        .clipShape(RoundedRectangle(cornerRadius: highlight.highlightViewCornerRadius, style: .circular))
                        .scaleEffect(highlight.scaleEffect)
                        .offset(x: highlightRect.minX - Constants.highlightViewReverseMaskOffSet, y: highlightRect.minY + safeArea.top - Constants.highlightViewReverseMaskOffSet)
                }
                .ignoresSafeArea()
                .onAppear {
                    updateAfterDelay(delay: Constants.showCoachMarkViewInitialDelay) {
                        showCoachMark = true
                    }
                    if isAutoTransition {
                        startTimer()
                    }
                }
                .modify {
                    if #available(iOS 17.0, *) {
                        $0.onChange(of: currentHighlight) { _, _ in
                            if isAutoTransition {
                                startTimer()
                            } else if currentHighlight >= highlightOrder.count - 1 && isAutoTransition {
                                stopTimer()
                            }
                        }
                    } else {
                        $0.onChange(of: currentHighlight) { _ in
                            if isAutoTransition {
                                startTimer()
                            } else if currentHighlight >= highlightOrder.count - 1 && isAutoTransition {
                                stopTimer()
                            }
                        }
                    }
                }
                        
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: highlightRect.width + Constants.highlightViewClearColorSpacing, height: highlightRect.height + Constants.highlightViewClearColorSpacing)
                .clipShape(RoundedRectangle(cornerRadius: highlight.highlightViewCornerRadius, style: .circular))
                .modify {
                    let popoverContent = {
                        popover(highlight: highlight, highlightRect: highlightRect)
                            .onAppear {
                                DispatchQueue.main.async {
                                    if let keyWindow = UIApplication.shared.connectedScenes
                                        .compactMap({ $0 as? UIWindowScene })
                                        .flatMap({ $0.windows })
                                        .first(where: { $0.isKeyWindow }) {
                                        
                                        if let uiVisualEffectContentView = keyWindow.findUIVisualEffectContentView() {
                                            uiVisualEffectContentView.backgroundColor = UIColor(highlight.coachMarkBackGroundColor)
                                        } else {
                                            print("uiVisualEffectContentView view not found")
                                        }
                                    }
                                }
                            }
                    }
                    
                    if #available(iOS 18.0, *) {
                        $0.popover(isPresented: $showCoachMark, content: popoverContent)
                            .offset(x: highlightRect.minX - Constants.popOverOffset, y: highlightRect.minY - Constants.popOverOffset)
                            .allowsHitTesting(!showCoachMark)
                    } else {
                        $0.popover(isPresented: $showCoachMark, content: popoverContent)
                            .offset(x: highlightRect.minX - Constants.popOverOffset, y: highlightRect.minY - Constants.popOverOffset)
                            .allowsHitTesting(!showCoachMark)
                    }
                }
        }
    }
    
    /// Starts a timer to handle automatic transitions between coach marks.
    ///
    /// This function stops any existing timer and then starts a new timer with a duration specified by `autoTransitionDuration`. When the timer fires, it advances to the next coach mark in the sequence. If the current highlight is the last one, it hides the coach marks and calls `onCoachMarkFinished()`. Otherwise, it transitions to the next highlight with a brief delay to show the coach mark again.
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: autoTransitionDuration, repeats: false) { _ in
            withAnimation {
                if currentHighlight >= highlightOrder.count - 1 {
                    finishCoachMark()
                } else {
                    nextButtonAction()
                }
            }
        }
    }
    
    /// Creates and returns a SwiftUI view representing a popover with the specified content.
    /// The popover can display either a description or a custom view for a given highlight.
    ///
    /// - Parameters:
    ///   - highlight: The `Highlight` object containing details for the popover's content.
    ///   - highlightRect: The `CGRect` representing the position and size of the highlighted area.
    ///
    /// - Returns: A SwiftUI view that displays a popover, which includes either a textual description or a custom view, along with navigation controls if necessary.
    ///
    /// The popover adapts its layout based on the height of the description text and the available screen space. If the description is too large to fit, it will be presented in a scrollable view. If a custom view is provided in the `Highlight` object, it will be displayed instead of the description. The popover also includes navigation controls for back, skip, next, and done actions if `isAutoTransition` is disabled.
    private func popover(highlight: Highlight, highlightRect: CGRect) -> some View {
        
        let customTitleFont = getCustomFont(customFontFamily: configuration.coachMarkTitleViewStyle.fontFamily,
                                            fontSize: configuration.coachMarkTitleViewStyle.fontSize,
                                            fontWeight: configuration.coachMarkTitleViewStyle.fontWeight)
        
        return VStack {
            if let description = highlight.description {
                VStack {
                    Text(highlight.title ?? "")
                        .font(customTitleFont)
                        .padding(.horizontal, 10)
                        .padding(.top, highlight.title == nil ? 0 : 20)
                        .foregroundStyle(configuration.coachMarkTitleViewStyle.foregroundStyle)
                    
                    if descriptionTextHeight > UIScreen.main.bounds.height - highlightRect.maxY - Constants.scrollViewOffset || descriptionTextHeight > UIScreen.main.bounds.height {
                        ScrollView {
                            coachMarkDescriptionView(description: description)
                        }
                    } else {
                        if descriptionTextHeight >= highlightRect.maxY && descriptionTextHeight > UIScreen.main.bounds.height {
                            ScrollView {
                                coachMarkDescriptionView(description: description)
                            }
                        } else {
                            coachMarkDescriptionView(description: description)
                        }
                    }
                }
            } else if let customCoachMarkView = highlight.customCoachMarkView {
                customCoachMarkView
                    .padding([.horizontal, .top], 10)
                    .padding(.bottom, isAutoTransition ? 10 : 0)
                    .interactiveDismissDisabled()
            }
            
            if !isAutoTransition {
                HStack {
                    if !(currentHighlight == 0) {
                        if let backButtonContent = backButtonContent {
                            backButtonContent
                        } else {
                            backButtonView
                        }
                    }
                    
                    if currentHighlight >= highlightOrder.count - 1 {
                        if let doneButtonContent = doneButtonContent {
                            doneButtonContent
                        } else {
                            doneButtonView
                        }
                    } else {
                        if (currentHighlight == 0) {
                            if let skipCoachMarkButton = skipCoachMarkButton {
                                skipCoachMarkButton
                            } else {
                                skipButtonView
                            }
                        }
                        
                        if let nextButtonContent = nextButtonContent {
                            nextButtonContent
                        } else {
                            nextButtonView
                        }
                    }
                }
                .padding(10)
            }
        }
        .presentationBackground(highlight.coachMarkBackGroundColor)
        .presentationCompactAdaptation(.popover)
    }
    
    /// Stops the timer responsible for automatic coach mark transitions.
    ///
    /// This function invalidates and clears the timer, preventing any scheduled automatic transitions from occurring.
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Private Views
    
    /// A view representing a "Skip" button in the UI.
    ///
    /// This button is configured with custom font styles and properties, including size, family, and weight. When tapped, it performs an animation to hide the coach mark and then triggers a completion handler. The button's appearance is customized with padding, background color, corner radius, and text styling.
    ///
    /// - Returns: A `ZStack` containing a `VStack` and `HStack` that arranges the button with custom styling.
    private var skipButton: some View {
        
        let customSkipCoachMarkFont = getCustomFont(customFontFamily: configuration.skipCoachMarkButtonStyle.fontFamily,
                                                    fontSize: configuration.skipCoachMarkButtonStyle.fontSize,
                                                    fontWeight: configuration.skipCoachMarkButtonStyle.fontWeight)
        
        return ZStack {
            VStack {
                Spacer()
                HStack {
                    if let skipButton = skipCoachMarkButton {
                        skipButton
                            .padding(.leading, 20)
                    } else {
                        Button(action: {
                            finishCoachMark()
                        }, label: {
                            Text(configuration.skipCoachMarkButtonStyle.buttonText)
                                .tint(configuration.skipCoachMarkButtonStyle.foregroundStyle)
                                .font(customSkipCoachMarkFont)
                                .padding(15)
                                .bold()
                                .background(configuration.skipCoachMarkButtonStyle.backgroundColor)
                                .cornerRadius(25)
                                .padding(.leading, 20)
                        })
                    }
                    Spacer()
                }
            }
        }
    }
    
    /// Creates a view displaying a description text with custom styling and dynamic height.
    ///
    /// This view uses the `getCustomFont` function to apply a custom font family, size, and weight to the description text. It measures the height of the text using a `GeometryReader` and updates the `descriptionTextHeight` state variable accordingly. The view is styled with padding, a fixed size, and conditional bottom padding based on the `isAutoTransition` state. The view also disables interactive dismissal to prevent it from being dismissed accidentally.
    ///
    /// - Parameter description: The text to display in the description view.
    /// - Returns: A `Text` view styled with the provided description and custom font, with dynamic height adjustment and additional styling for padding and frame configuration.
    private func coachMarkDescriptionView(description: String) -> some View {
        
        let customDescriptionFont = getCustomFont(customFontFamily: configuration.coachMarkDescriptionViewStyle.fontFamily,
                                                  fontSize: configuration.coachMarkDescriptionViewStyle.fontSize,
                                                  fontWeight: configuration.coachMarkDescriptionViewStyle.fontWeight)
        
        return Text(description)
            .overlay(
                GeometryReader { proxy in
                    Color.clear.preference(key: ContentLengthPreference.self, value: proxy.size.height)
                }
            )
            .onPreferenceChange(ContentLengthPreference.self) { value in
                DispatchQueue.main.async {
                    self.descriptionTextHeight = value
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .foregroundStyle(configuration.coachMarkDescriptionViewStyle.foregroundStyle)
            .frame(height: descriptionTextHeight)
            .font(customDescriptionFont)
            .padding(.bottom, isAutoTransition ? 10 : 0)
            .interactiveDismissDisabled()
    }
    
    /// Creates a view representing a "Back" button in the UI.
    ///
    /// This button is configured with custom font styles for its text, including family, size, and weight. When tapped, it hides the current coach mark, decrements the `currentHighlight` value, and then shows the coach mark again after a brief delay. The button's appearance is customized with a background color and corner radius. The text styling is applied using a custom button text modifier.
    ///
    /// - Returns: A `Button` view styled with custom font properties, background color, and corner radius. The button’s action updates the coach mark visibility and highlight index with a delay.
    private var backButtonView: some View {
        
        let customBackFont = getCustomFont(customFontFamily: configuration.backButtonStyle.fontFamily,
                                           fontSize: configuration.backButtonStyle.fontSize,
                                           fontWeight: configuration.backButtonStyle.fontWeight)
        
        return Button(action: {
            backButtonAction()
        }) {
            Text(configuration.backButtonStyle.buttonText)
                .unFilledButtonTextModifier(foregroundStyle: configuration.backButtonStyle.foregroundStyle, font: customBackFont)
        }
        .background(configuration.backButtonStyle.backgroundColor)
        .cornerRadius(10)
    }
    
    /// Creates a view representing a "Next" button in the UI.
    ///
    /// This button is styled with a custom font, including family, size, and weight. When tapped, it hides the current coach mark, increments the `currentHighlight` value, and then shows the coach mark again after a brief delay. The button’s appearance is customized with a background color and corner radius. The text styling is applied using a custom button text modifier.
    ///
    /// - Returns: A `Button` view styled with custom font properties, background color, and corner radius. The button’s action updates the coach mark visibility and highlight index with a delay.
    private var nextButtonView: some View {
        
        let customNextFont = getCustomFont(customFontFamily: configuration.nextButtonStyle.fontFamily,
                                           fontSize: configuration.nextButtonStyle.fontSize,
                                           fontWeight: configuration.nextButtonStyle.fontWeight)
        
        return Button(action: {
            nextButtonAction()
        }) {
            Text(configuration.nextButtonStyle.buttonText)
                .filledButtonTextModifier(foregroundStyle: configuration.nextButtonStyle.foregroundStyle, font: customNextFont)
        }
        .background(configuration.nextButtonStyle.backgroundColor)
        .cornerRadius(10)
    }
    
    /// Creates a view representing a "Skip" button in the UI.
    ///
    /// This button is styled with a custom font, including family, size, and weight. When tapped, it hides the current coach mark, increments the `currentHighlight` value, and then shows the coach mark again after a brief delay. The button’s appearance is customized with a background color and corner radius. The text styling is applied using a custom button text modifier.
    ///
    /// - Returns: A `Button` view styled with custom font properties, background color, and corner radius. The button’s action updates the coach mark visibility and highlight index with a delay.
    private var skipButtonView: some View {
        
        let customNextFont = getCustomFont(customFontFamily: configuration.skipCoachMarkButtonStyle.fontFamily,
                                           fontSize: configuration.skipCoachMarkButtonStyle.fontSize,
                                           fontWeight: configuration.skipCoachMarkButtonStyle.fontWeight)
        
        return Button(action: {
            finishCoachMark()
        }) {
            Text(configuration.skipCoachMarkButtonStyle.buttonText)
                .filledButtonTextModifier(foregroundStyle: configuration.skipCoachMarkButtonStyle.foregroundStyle, font: customNextFont)
        }
        .background(configuration.skipCoachMarkButtonStyle.backgroundColor)
        .cornerRadius(10)
    }
    
    /// A button that signals the completion of the coach mark sequence.
    ///
    /// This view presents a "Done" button styled with the colors and text specified in `style`. When pressed, it hides the current coach mark with an animation and triggers the `onCoachMarkFinished` closure to indicate that the coach mark sequence is complete. The button is styled with a filled background and rounded corners for a finished look./// Creates a view representing a "Done" button in the UI.
    ///
    /// This button is styled with a custom font, including family, size, and weight. When tapped, it performs an animation to hide the coach mark and then triggers a completion handler. The button’s appearance is customized with a background color and corner radius. The text styling is applied using a custom button text modifier.
    ///
    /// - Returns: A `Button` view styled with custom font properties, background color, and corner radius. The button’s action includes an animation to hide the coach mark and calls a completion handler.
    private var doneButtonView: some View {
        
        let customDoneFont = getCustomFont(customFontFamily: configuration.doneButtonStyle.fontFamily,
                                           fontSize: configuration.doneButtonStyle.fontSize,
                                           fontWeight: configuration.doneButtonStyle.fontWeight)
        
        return Button(action: {
            finishCoachMark()
        }) {
            Text(configuration.doneButtonStyle.buttonText)
                .filledButtonTextModifier(foregroundStyle: configuration.doneButtonStyle.foregroundStyle, font: customDoneFont)
        }
        .background(configuration.doneButtonStyle.backgroundColor)
        .cornerRadius(10)
    }
    
    /// Handles the action for the "Next" button in the Coach Mark sequence.
    ///
    /// This function hides the current Coach Mark with an animation, increments the `currentHighlight` to move to the next item, and then shows the next Coach Mark after a brief delay.
    ///
    /// The sequence of actions includes:
    /// 1. Animating the hiding of the current Coach Mark with an ease-out effect.
    /// 2. Incrementing the `currentHighlight` index to highlight the next item.
    /// 3. Re-displaying the Coach Mark after a specified delay, allowing for a smooth transition.
    ///
    /// The delay and animation duration are hardcoded in the function.
    private func nextButtonAction() {
        withAnimation(.easeOut(duration: Constants.buttonClickedAnimationDelay)) {
            showCoachMark = false
            currentHighlight += 1
        }
        updateAfterDelay(delay: Constants.showCoachMarkViewDelay) {
            self.showCoachMark = true
        }
    }
    
    /// Handles the action for the "Back" button in the Coach Mark sequence.
    ///
    /// This function hides the current Coach Mark with an animation, decrements the `currentHighlight` to move to the previous item, and then shows the previous Coach Mark after a brief delay.
    ///
    /// The sequence of actions includes:
    /// 1. Animating the hiding of the current Coach Mark with an ease-out effect.
    /// 2. Decrementing the `currentHighlight` index to highlight the previous item.
    /// 3. Re-displaying the Coach Mark after a specified delay, allowing for a smooth transition.
    ///
    /// The delay and animation duration are hardcoded in the function.
    private func backButtonAction() {
        withAnimation(.easeOut(duration: Constants.buttonClickedAnimationDelay)) {
            showCoachMark = false
            currentHighlight -= 1
        }
        updateAfterDelay(delay: Constants.showCoachMarkViewDelay) {
            self.showCoachMark = true
        }
    }
    
    /// Completes the Coach Mark sequence and triggers the when skip coach mark  button actions trigger.
    private func finishCoachMark() {
        withAnimation(.easeInOut(duration: Constants.buttonClickedAnimationDelay)) {
            hideCoachMark = false
        }
        onCoachMarkFinished()
    }
}

// MARK: - Modifiers
extension CoachMarkView {
    
    /// Configures the style of the "Next" button in the coach mark.
    ///
    /// This function allows you to customize the appearance of the "Next" button in the coach mark view.
    /// You can modify various properties such as button text, foreground color, background color, font size, font family, and font weight.
    /// The function returns the updated `CoachMarkView` with the new button style configuration.
    ///
    /// - Parameters:
    ///   - buttonText: An optional `String` to set the text of the "Next" button. If `nil`, the default button text is retained.
    ///   - foregroundStyle: An optional `Color` to set the text color of the "Next" button. If `nil`, the default color is retained.
    ///   - backgroundColor: An optional `Color` to set the background color of the "Next" button. If `nil`, the default color is retained.
    ///   - fontSize: An optional `CGFloat` to set the font size of the "Next" button text. If `nil`, the default font size is retained.
    ///   - fontFamily: An optional `String` to set the font family of the "Next" button text. If `nil`, the default font family is retained.
    ///   - fontWeight: An optional `Font.Weight` to set the font weight of the "Next" button text. If `nil`, the default font weight is retained.
    ///
    /// - Returns: An updated `CoachMarkView` instance with the new style applied to the "Next" button.
    ///
    /// - Example:
    ///   ```swift
    ///   someCoachMarkView.nextButtonStyle(buttonText: "Proceed",
    ///                                     foregroundStyle: .white,
    ///                                     backgroundColor: .blue,
    ///                                     fontSize: 14,
    ///                                     fontWeight: .bold)
    ///   ```
    ///   In this example, the "Next" button will have the text "Proceed", a white foreground color, a blue background, a font size of 14, and bold weight.
    public func nextButtonStyle(buttonText: String? = nil,
                                foregroundStyle: Color? = nil,
                                backgroundColor: Color? = nil,
                                fontSize: CGFloat? = nil,
                                fontFamily: String? = nil,
                                fontWeight: Font.Weight? = nil) -> CoachMarkView {
        var coachMark = self
        buttonText.map { coachMark.configuration.nextButtonStyle.buttonText = $0 }
        foregroundStyle.map { coachMark.configuration.nextButtonStyle.foregroundStyle = $0 }
        backgroundColor.map { coachMark.configuration.nextButtonStyle.backgroundColor = $0 }
        fontSize.map { coachMark.configuration.nextButtonStyle.fontSize = $0 }
        fontWeight.map { coachMark.configuration.nextButtonStyle.fontWeight = $0 }
        return coachMark
    }
    
    /// Configures the style of the "Back" button in the coach mark.
    ///
    /// This function allows you to customize the appearance of the "Back" button in the coach mark view.
    /// You can modify various properties such as button text, foreground color, background color, font size, font family, and font weight.
    /// The function returns the updated `CoachMarkView` with the new button style configuration.
    ///
    /// - Parameters:
    ///   - buttonText: An optional `String` to set the text of the "Back" button. If `nil`, the default button text is retained.
    ///   - foregroundStyle: An optional `Color` to set the text color of the "Back" button. If `nil`, the default color is retained.
    ///   - backgroundColor: An optional `Color` to set the background color of the "Back" button. If `nil`, the default color is retained.
    ///   - fontSize: An optional `CGFloat` to set the font size of the "Back" button text. If `nil`, the default font size is retained.
    ///   - fontFamily: An optional `String` to set the font family of the "Back" button text. If `nil`, the default font family is retained.
    ///   - fontWeight: An optional `Font.Weight` to set the font weight of the "Back" button text. If `nil`, the default font weight is retained.
    ///
    /// - Returns: An updated `CoachMarkView` instance with the new style applied to the "Back" button.
    ///
    /// - Example:
    ///   ```swift
    ///   someCoachMarkView.backButtonStyle(buttonText: "Previous",
    ///                                     foregroundStyle: .white,
    ///                                     backgroundColor: .gray,
    ///                                     fontSize: 14,
    ///                                     fontWeight: .regular)
    ///   ```
    ///   In this example, the "Back" button will have the text "Previous", a white foreground color, a gray background, a font size of 14, and regular weight.
    public func backButtonStyle(buttonText: String? = nil,
                                foregroundStyle: Color? = nil,
                                backgroundColor: Color? = nil,
                                fontSize: CGFloat? = nil,
                                fontFamily: String? = nil,
                                fontWeight: Font.Weight? = nil) -> CoachMarkView {
        var coachMark = self
        buttonText.map { coachMark.configuration.backButtonStyle.buttonText = $0 }
        foregroundStyle.map { coachMark.configuration.backButtonStyle.foregroundStyle = $0 }
        backgroundColor.map { coachMark.configuration.backButtonStyle.backgroundColor = $0 }
        fontSize.map { coachMark.configuration.backButtonStyle.fontSize = $0 }
        fontWeight.map { coachMark.configuration.backButtonStyle.fontWeight = $0 }
        return coachMark
    }
    
    /// Configures the style of the "Done" button in the coach mark.
    ///
    /// This function allows you to customize the appearance of the "Done" button in the coach mark view.
    /// You can modify various properties such as button text, foreground color, background color, font size, font family, and font weight.
    /// The function returns the updated `CoachMarkView` with the new button style configuration.
    ///
    /// - Parameters:
    ///   - buttonText: An optional `String` to set the text of the "Done" button. If `nil`, the default button text is retained.
    ///   - foregroundStyle: An optional `Color` to set the text color of the "Done" button. If `nil`, the default color is retained.
    ///   - backgroundColor: An optional `Color` to set the background color of the "Done" button. If `nil`, the default color is retained.
    ///   - fontSize: An optional `CGFloat` to set the font size of the "Done" button text. If `nil`, the default font size is retained.
    ///   - fontFamily: An optional `String` to set the font family of the "Done" button text. If `nil`, the default font family is retained.
    ///   - fontWeight: An optional `Font.Weight` to set the font weight of the "Done" button text. If `nil`, the default font weight is retained.
    ///
    /// - Returns: An updated `CoachMarkView` instance with the new style applied to the "Done" button.
    ///
    /// - Example:
    ///   ```swift
    ///   someCoachMarkView.doneButtonStyle(buttonText: "Finish",
    ///                                     foregroundStyle: .white,
    ///                                     backgroundColor: .green,
    ///                                     fontSize: 16,
    ///                                     fontWeight: .bold)
    ///   ```
    ///   In this example, the "Done" button will have the text "Finish", a white foreground color, a green background, a font size of 16, and bold weight.
    public func doneButtonStyle(buttonText: String? = nil,
                                foregroundStyle: Color? = nil,
                                backgroundColor: Color? = nil,
                                fontSize: CGFloat? = nil,
                                fontFamily: String? = nil,
                                fontWeight: Font.Weight? = nil) -> CoachMarkView {
        var coachMark = self
        buttonText.map { coachMark.configuration.doneButtonStyle.buttonText = $0 }
        foregroundStyle.map { coachMark.configuration.doneButtonStyle.foregroundStyle = $0 }
        backgroundColor.map { coachMark.configuration.doneButtonStyle.backgroundColor = $0 }
        fontSize.map { coachMark.configuration.doneButtonStyle.fontSize = $0 }
        fontWeight.map { coachMark.configuration.doneButtonStyle.fontWeight = $0 }
        return coachMark
    }
    
    /// Configures the style of the "Skip CoachMark" button in the coach mark.
    ///
    /// This function allows you to customize the appearance of the "Skip CoachMark" button in the coach mark view.
    /// You can modify various properties such as button text, foreground color, background color, font size, font family, and font weight.
    /// The function returns the updated `CoachMarkView` with the new button style configuration.
    ///
    /// - Parameters:
    ///   - buttonText: An optional `String` to set the text of the "Skip CoachMark" button. If `nil`, the default button text is retained.
    ///   - foregroundStyle: An optional `Color` to set the text color of the "Skip CoachMark" button. If `nil`, the default color is retained.
    ///   - backgroundColor: An optional `Color` to set the background color of the "Skip CoachMark" button. If `nil`, the default color is retained.
    ///   - fontSize: An optional `CGFloat` to set the font size of the "Skip CoachMark" button text. If `nil`, the default font size is retained.
    ///   - fontFamily: An optional `String` to set the font family of the "Skip CoachMark" button text. If `nil`, the default font family is retained.
    ///   - fontWeight: An optional `Font.Weight` to set the font weight of the "Skip CoachMark" button text. If `nil`, the default font weight is retained.
    ///
    /// - Returns: An updated `CoachMarkView` instance with the new style applied to the "Skip CoachMark" button.
    ///
    /// - Example:
    ///   ```swift
    ///   someCoachMarkView.skipCoachMarkButtonStyle(buttonText: "Skip Now",
    ///                                              foregroundStyle: .black,
    ///                                              backgroundColor: .yellow,
    ///                                              fontSize: 18,
    ///                                              fontWeight: .bold)
    ///   ```
    ///   In this example, the "Skip CoachMark" button will have the text "Skip Now", a black foreground color, a yellow background, a font size of 18, and bold weight.
    public func skipCoachMarkButtonStyle(buttonText: String? = nil,
                                         foregroundStyle: Color? = nil,
                                         backgroundColor: Color? = nil,
                                         fontSize: CGFloat? = nil,
                                         fontFamily: String? = nil,
                                         fontWeight: Font.Weight? = nil) -> CoachMarkView {
        var coachMark = self
        buttonText.map { coachMark.configuration.skipCoachMarkButtonStyle.buttonText = $0 }
        foregroundStyle.map { coachMark.configuration.skipCoachMarkButtonStyle.foregroundStyle = $0 }
        backgroundColor.map { coachMark.configuration.skipCoachMarkButtonStyle.backgroundColor = $0 }
        fontSize.map { coachMark.configuration.skipCoachMarkButtonStyle.fontSize = $0 }
        fontWeight.map { coachMark.configuration.skipCoachMarkButtonStyle.fontWeight = $0 }
        return coachMark
    }
    
    /// Configures the style of the coach mark's title view.
    ///
    /// This function allows you to customize the appearance of the title in the coach mark view.
    /// You can adjust properties such as the text color, font size, font family, and font weight for the title.
    /// The function returns the updated `CoachMarkView` with the new title style configuration.
    ///
    /// - Parameters:
    ///   - foregroundStyle: An optional `Color` to set the text color of the coach mark's title. If `nil`, the default color is retained.
    ///   - fontSize: An optional `CGFloat` to set the font size of the coach mark's title text. If `nil`, the default font size is retained.
    ///   - fontFamily: An optional `String` to set the font family of the coach mark's title text. If `nil`, the default font family is retained.
    ///   - fontWeight: An optional `Font.Weight` to set the font weight of the coach mark's title text. If `nil`, the default font weight is retained.
    ///
    /// - Returns: An updated `CoachMarkView` instance with the new style applied to the title view.
    ///
    /// - Example:
    ///   ```swift
    ///   someCoachMarkView.coachMarkTitleViewStyle(foregroundStyle: .blue,
    ///                                             fontSize: 24,
    ///                                             fontFamily: "Arial",
    ///                                             fontWeight: .bold)
    ///   ```
    ///   In this example, the title in the coach mark view will have blue text, a font size of 24, Arial font, and bold weight.
    public func coachMarkTitleViewStyle(foregroundStyle: Color? = nil,
                                        fontSize: CGFloat? = nil,
                                        fontFamily: String? = nil,
                                        fontWeight: Font.Weight? = nil) -> CoachMarkView {
        var coachMark = self
        foregroundStyle.map { coachMark.configuration.coachMarkTitleViewStyle.foregroundStyle = $0 }
        fontSize.map { coachMark.configuration.coachMarkTitleViewStyle.fontSize = $0 }
        fontFamily.map { coachMark.configuration.coachMarkTitleViewStyle.fontFamily = $0 }
        fontWeight.map { coachMark.configuration.coachMarkTitleViewStyle.fontWeight = $0 }
        return coachMark
    }
    
    /// Configures the style of the coach mark's description view.
    ///
    /// This function allows you to customize the appearance of the description text in the coach mark view.
    /// You can adjust various properties such as text color, font size, font family, and font weight for the description.
    /// The function returns the updated `CoachMarkView` with the new description style configuration.
    ///
    /// - Parameters:
    ///   - foregroundStyle: An optional `Color` to set the text color of the coach mark's description. If `nil`, the default color is retained.
    ///   - fontSize: An optional `CGFloat` to set the font size of the coach mark's description text. If `nil`, the default font size is retained.
    ///   - fontFamily: An optional `String` to set the font family of the coach mark's description text. If `nil`, the default font family is retained.
    ///   - fontWeight: An optional `Font.Weight` to set the font weight of the coach mark's description text. If `nil`, the default font weight is retained.
    ///
    /// - Returns: An updated `CoachMarkView` instance with the new style applied to the description view.
    ///
    /// - Example:
    ///   ```swift
    ///   someCoachMarkView.coachMarkDescriptionViewStyle(foregroundStyle: .gray,
    ///                                                    fontSize: 16,
    ///                                                    fontFamily: "Helvetica",
    ///                                                    fontWeight: .regular)
    ///   ```
    ///   In this example, the description in the coach mark view will have gray text, a font size of 16, Helvetica font, and regular weight.
    public func coachMarkDescriptionViewStyle(foregroundStyle: Color? = nil,
                                              fontSize: CGFloat? = nil,
                                              fontFamily: String? = nil,
                                              fontWeight: Font.Weight? = nil) -> CoachMarkView {
        var coachMark = self
        foregroundStyle.map { coachMark.configuration.coachMarkDescriptionViewStyle.foregroundStyle = $0 }
        fontSize.map { coachMark.configuration.coachMarkDescriptionViewStyle.fontSize = $0 }
        fontFamily.map { coachMark.configuration.coachMarkDescriptionViewStyle.fontFamily = $0 }
        fontWeight.map { coachMark.configuration.coachMarkDescriptionViewStyle.fontWeight = $0 }
        return coachMark
    }
    
    /// Configures the style of the coach mark's overlay.
    ///
    /// This function allows you to customize the appearance of the overlay that appears behind the coach mark.
    /// You can adjust the overlay color and its opacity to match your design requirements.
    /// The function returns the updated `CoachMarkView` with the new overlay style configuration.
    ///
    /// - Parameters:
    ///   - overlayColor: An optional `Color` to set the color of the coach mark's overlay. If `nil`, the default color is retained.
    ///   - overlayOpacity: An optional `Double` to set the opacity of the coach mark's overlay. The value should be between 0.0 (fully transparent) and 1.0 (fully opaque). If `nil`, the default opacity is retained.
    ///
    /// - Returns: An updated `CoachMarkView` instance with the new style applied to the overlay.
    ///
    /// - Example:
    ///   ```swift
    ///   someCoachMarkView.overlayStyle(overlayColor: .black, overlayOpacity: 0.5)
    ///   ```
    ///   In this example, the coach mark view will have a black overlay with 50% opacity.
    public func overlayStyle(overlayColor: Color? = nil,
                             overlayOpacity: Double? = nil) -> CoachMarkView {
        var coachMark = self
        overlayColor.map { coachMark.configuration.overlayStyle.overlayColor = $0 }
        overlayOpacity.map { coachMark.configuration.overlayStyle.overlayOpacity = $0 }
        return coachMark
    }
}
