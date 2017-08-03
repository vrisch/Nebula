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

    public struct Delta<T> {
        public var changed: T
        public var added: T
        public var removed: T
        public var moved: T
    }

    /*
     * If mode = .all every value is added to the "changed" list regardless of changes status
     * If mode = .element then inserted and updated are added to the "changed" list, no values are added to "added" and "removed"
     * If mode = .list then inserted are added to the "added" list and deleted to the "removed" list, no values are added to "changed"
     */
    public static func delta<S: Sequence>(_ changes: S, _ mode: Mode) -> Delta<[T]> where S.Element == Change<T> {
        var result: Delta<[T]> = Delta<[T]>(changed: [], added: [], removed: [], moved: [])
        var hasMovement = false
        changes.forEach { change in
            switch (mode, change) {
            case (.all, _):
                result.changed.append(change.value)

            case (.element, .deleted):
                result.removed.append(change.value)
            case (.element, .inserted):
                result.added.append(change.value)
            case (.element, .unchanged):
                if hasMovement { result.moved.append(change.value) }
            case (.element, .updated):
                result.changed.append(change.value)

            case (.list, .deleted):
                result.removed.append(change.value)
            case (.list, .inserted):
                result.added.append(change.value)
            default: break
            }
            switch change {
            case .inserted, .deleted: hasMovement = true
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

    public static func count<S: Sequence>(_ changes: S) -> Delta<Int> where S.Element == Change<T> {
        var result: Delta<Int> = Delta<Int>(changed: 0, added: 0, removed: 0, moved: 0)
        var hasMovement = false
        for change in changes {
            switch change {
            case .deleted: result.removed += 1
            case .inserted: result.added += 1
            case .unchanged: if hasMovement { result.moved += 1 }
            case .updated: result.changed += 1
            }
            switch change {
            case .inserted, .deleted: hasMovement = true
            default: break
            }
        }
        return result
    }

    public static func hasChanges<S: Sequence>(_ changes: S) -> Bool where S.Element == Change<T> {
        let delta = count(changes)
        return delta.changed > 0 || delta.added > 0 || delta.removed > 0
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

