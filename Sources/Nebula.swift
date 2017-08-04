//
//  Nebula.swift
//  Nebula
//
//  Created by Vrisch on 2017-06-30.
//  Copyright © 2017 Nebula. All rights reserved.
//

import Foundation

public protocol Model {}

public enum Change<T: Model> {
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

    public static func count<S: Sequence>(_ changes: S) -> Delta<Int> where S.Element == Change<T> {
        let delta = self.delta(changes, .element)
        return Delta<Int>(changed: delta.changed.count, added: delta.added.count, removed: delta.removed.count, moved: delta.moved.count)
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

extension Change.Delta where T == [Model] {
    public var isEmpty: Bool { return changed.isEmpty && added.isEmpty && removed.isEmpty && moved.isEmpty }
}

