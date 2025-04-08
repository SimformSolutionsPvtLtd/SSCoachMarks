//
//  SSCoachMarkManager.swift
//  CoachworkDemo
//
//  Created by Yagnik Bavishi on 08/08/24.
//

import Foundation

//MARK: - SSCoachMarkManager
/// Manages the configuration and behaviour of CoachMark components.
/// This class provides direct access to the configuration and facilitates the setup and customisation of CoachMark views.
final public class SSCoachMarkManager {
    
    /// The configuration used to style and control the behaviour of the CoachMark.
    public var configuration = SSCoachMarkConfiguration()
    
    /// A public no-argument initializer that allows external modules to create an instance of the type.
    public init() { }
}
