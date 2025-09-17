//
//  ButtonEventsCoordinator.swift
//  SSCoachMarksDemo
//
//  Created by Yagnik Bavishi on 12/08/24.
//

import SwiftUI
import Combine

/// A coordinator that manages button event triggers and publishes events for `next`, `back`, `done`, and `skip` actions.
final public class ButtonEventsCoordinator {

    /// A public no-argument initializer that allows external modules to create an instance of the type.
    public init() { }
    
    /// Defines the type of button events supported.
    enum EventType {
        case next, back, done, skip
    }
    
    /// A dictionary to hold `PassthroughSubject` for each `EventType`.
    /// Each subject is responsible for emitting events related to its specific button action.
    private var eventSubjects: [EventType: PassthroughSubject<Void, Never>] = [
        .next: PassthroughSubject(),
        .back: PassthroughSubject(),
        .done: PassthroughSubject(),
        .skip: PassthroughSubject()
    ]
    
    /// Returns a publisher for a specific button event type.
    /// - Parameter eventType: The type of button event for which the publisher is needed.
    /// - Returns: An `AnyPublisher` that emits a `Void` event whenever the specified button event is triggered.
    func publisher(for eventType: EventType) -> AnyPublisher<Void, Never> {
        eventSubjects[eventType]?.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
    }
    
    /// Triggers an event for a specific button type.
    /// - Parameter eventType: The type of button event to trigger (`next`, `back`, `done`, `skip`).
    func buttonEventTriggerType(eventType: EventType) {
        eventSubjects[eventType]?.send(())
    }
}
