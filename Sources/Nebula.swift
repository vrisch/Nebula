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
    
    public enum Mode {
        case all
        case element
        case list
    }
    
    /*
     * If mode = .all every value is added to the "changes" list regardless of changes status
     * If mode = .element then inserted and updated are added to the "changed" list, no values are added to "added" and "deleted"
     * If mode = .list then inserted are added to the "added" list, updated to the "changed" list and deleted to the "deleted" list
     */
    public static func changes<S: Sequence>(_ changes: S, _ mode: Mode) -> (changed: [T], added: [T], deleted: [T]) where S.Element == Change<T> {
        var result: (changed: [T], added: [T], deleted: [T]) = (changed: [], added: [], deleted: [])
        changes.forEach { change in
            switch (mode, change) {
            case (.all, _):
                result.0.append(change.value)
            case (.element, .inserted), (.element, .updated):
                result.0.append(change.value)
            case (.list, .deleted):
                result.2.append(change.value)
            case (.list, .inserted):
                result.1.append(change.value)
            case (.list, .updated):
                result.0.append(change.value)
            default: break
            }
        }
        return result
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

    public static func count<S: Sequence>(_ changes: S) -> (deleted: Int, inserted: Int, unchanged: Int, updated: Int) where S.Element == Change<T> {
        var result: (deleted: Int, inserted: Int, unchanged: Int, updated: Int) = (deleted: 0, inserted: 0, unchanged: 0, updated: 0)
        for change in changes {
            switch change {
            case .deleted: result.0 += 1
            case .inserted: result.1 += 1
            case .unchanged: result.2 += 1
            case .updated: result.3 += 1
            }
        }
        return result
    }

    public static func hasChanges<S: Sequence>(_ changes: S) -> Bool where S.Element == Change<T> {
        let (deleted, inserted, _, updated) = count(changes)
        return deleted > 0 || inserted > 0 || updated > 0
    }

    public static func normalized<S: Sequence>(_ changes: S) -> [Change] where S.Element == Change<T> {
        var result: [Change] = []
        changes.forEach { change in
            switch change {
            case .deleted: break
            case let .inserted(value): result.append(.unchanged(value))
            case let .unchanged(value): result.append(.unchanged(value))
            case let .updated(value): result.append(.unchanged(value))
            }
        }
        return result
    }
}
