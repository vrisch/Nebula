//
//  Nebula.swift
//  Nebula
//
//  Created by Vrisch on 2017-06-30.
//  Copyright © 2017 Nebula. All rights reserved.
//

import Foundation

public protocol Model: Equatable {}

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

public enum Mode: String {
    case initial
    case element
    case list
}

public struct Delta<T> {
    public let mode: Mode
    public var changed: [T]
    public var added: [T]
    public var removed: [T]
    public var moved: [T]
    
    public var isEmpty: Bool { return changed.isEmpty && added.isEmpty && removed.isEmpty && moved.isEmpty }

    public init(mode: Mode = .initial, changed: [T] = [], added: [T] = [], removed: [T] = [], moved: [T] = []) {
        self.mode = mode
        self.changed = changed
        self.added = added
        self.removed = removed
        self.moved = moved
    }

    public init(mode: Mode, delta: Delta<T>) {
        self.mode = mode
        self.changed = delta.changed
        self.added = delta.added
        self.removed = delta.removed
        self.moved = delta.moved
    }
}

public struct Count {
    public let mode: Mode
    public var changed: Int
    public var added: Int
    public var removed: Int
    public var moved: Int
    
    public init(mode: Mode = .initial, changed: Int = 0, added: Int = 0, removed: Int = 0, moved: Int = 0) {
        self.mode = mode
        self.changed = changed
        self.added = added
        self.removed = removed
        self.moved = moved
    }
}

public struct View<T: Model> {
    public var indexes = Delta<Int>()

    public init(by areInIncreasingOrder: @escaping (T, T) -> Bool) {
        self.areInIncreasingOrder = areInIncreasingOrder
        self.orderedView = []
    }

    public func indexes(mode: Mode) -> Delta<Int> {
        return Delta<Int>(mode: mode, delta: indexes)
    }

    public mutating func apply(delta: Delta<T>) {
        indexes = Delta(mode: delta.mode)

        guard delta.mode != .initial else {
            orderedView = delta.changed
            orderedView = orderedView.sorted(by: areInIncreasingOrder)
            return
        }

        // Deletes must be processed first, since the indexes are relative to the old content
        delta.removed.forEach { element in
            if let index = orderedView.index(where: { $0 == element }) {
                indexes.removed.append(index)
            }
        }

        // Sort removed indexes
        indexes.removed = indexes.removed.sorted(by: <)

        // Now that the removed indexes are recorded, we can go ahead and delete the elements (in reverse order)
        indexes.removed.reversed().forEach { orderedView.remove(at: $0) }
        
        // Now process inserts and changes without recording indexes
        delta.added.forEach { element in
            orderedView.append(element)
        }
        delta.changed.forEach { element in
            if let index = orderedView.index(where: { $0 == element }) {
                orderedView[index] = element
            }
        }

        // Sort the new updated content
        orderedView = orderedView.sorted(by: areInIncreasingOrder)

        // Find the inserted and changed indexes
        delta.added.forEach { element in
            if let index = orderedView.index(where: { $0 == element }) {
                indexes.added.append(index)
            }
        }
        delta.changed.forEach { element in
            if let index = orderedView.index(where: { $0 == element }) {
                indexes.changed.append(index)
            }
        }
        
        // Sort added and changed indexes
        indexes.added = indexes.added.sorted(by: <)
        indexes.changed = indexes.changed.sorted(by: <)
    }

    internal var orderedView: [T]
    private let areInIncreasingOrder: (T, T) -> Bool
}
