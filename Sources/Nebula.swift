//
//  Nebula.swift
//  Nebula
//
//  Created by Vrisch on 2017-06-30.
//  Copyright © 2017 Nebula. All rights reserved.
//

import Foundation

public enum Change<T> {
    case deleted(T)
    case inserted(T)
    case unchanged(T)
    case updated(T)
    
    public var value: T {
        switch self {
        case let .deleted(value): return value
        case let .inserted(value): return value
        case let .unchanged(value): return value
        case let .updated(value): return value
        }
    }
    
    public static func deletions<S: Sequence>(_ changes: S) -> [T] where S.Element == Change<T> {
        var result: [T] = []
        changes.forEach { change in
            if case let .deleted(value) = change {
                result.append(value)
            }
        }
        return result
    }
    
    public static func insertions<S: Sequence>(_ changes: S) -> [T] where S.Element == Change<T> {
        var result: [T] = []
        changes.forEach { change in
            if case let .inserted(value) = change {
                result.append(value)
            }
        }
        return result
    }
    
    public static func normalized<S: Sequence>(_ changes: S) -> [Change] where S.Element == Change<T> {
        var result: [Change] = []
        changes.forEach { change in
            switch change {
            case .deleted:
                break
            case let .inserted(value):
                result.append(.unchanged(value))
            case let .unchanged(value):
                result.append(.unchanged(value))
            case let .updated(value):
                result.append(.unchanged(value))
            }
        }
        return result
    }
}

