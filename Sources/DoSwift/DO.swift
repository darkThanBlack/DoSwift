//
//  DO.swift
//  DoSwift
//

import Foundation

/// Static name space of DoSwift.
///
/// Every public type lives under `DO` so call sites read `DO.Core`, `DO.MenuGroup`,
/// `DO.OverlayWindow`. The name is deliberately short and does not collide with the
/// module name — a type sharing its module's name makes `Module.Type` ambiguous.
public enum DO {}
