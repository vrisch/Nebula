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
    
    public init(changed: T, added: T, removed: T, moved: T) {
        self.changed = changed
        self.added = added
        self.removed = removed
        self.moved = moved
    }
}

public extension Delta where T: Collection {
    
    public var isEmpty: Bool { return changed.isEmpty && added.isEmpty && removed.isEmpty && moved.isEmpty }
}

extension Sequence {

    public func delta<T>(mode: Mode) -> Delta<[T]> where Element == Change<T> {
        var changed: [T] = []
        var added: [T] = []
        var removed: [T] = []
        var moved: [T] = []
        var hasMovement = false
        forEach { change in
            switch (mode, change) {
            case (.all, .deleted):
                break
            case (.all, _):
                changed.append(change.value)

            case (.element, .deleted):
                removed.append(change.value)
            case (.element, .inserted):
                added.append(change.value)
            case (.element, .unchanged):
                if hasMovement { moved.append(change.value) }
            case (.element, .updated):
                changed.append(change.value)

            case (.list, .deleted):
                removed.append(change.value)
            case (.list, .inserted):
                added.append(change.value)
            default: break
            }

            switch change {
            case .inserted, .deleted: hasMovement = true
            default: break
            }
        }
        return Delta(changed: changed, added: added, removed: removed, moved: moved)
    }

    public func count<T>(mode: Mode) -> Delta<Int> where Element == Change<T> {
        let delta = self.delta(mode: mode)
        return Delta<Int>(changed: delta.changed.count, added: delta.added.count, removed: delta.removed.count, moved: delta.moved.count)
    }

    public func needsNormalization<T>() -> Bool where Element == Change<T> {
        let delta = count(mode: .element)
        return delta.changed > 0 || delta.added > 0 || delta.removed > 0
    }

    public func normalized<T>() -> [Change<T>] where Element == Change<T> {
        var result: [Change<T>] = []
        forEach { change in
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
