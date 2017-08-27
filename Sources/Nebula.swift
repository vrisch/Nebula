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

public enum Mode {
    case initial
    case element
    case list
}

public struct Delta<T> {
    public let mode: Mode
    public var changed: T
    public var added: T
    public var removed: T
    public var moved: T

    public init(mode: Mode, changed: T, added: T, removed: T, moved: T) {
        self.mode = mode
        self.changed = changed
        self.added = added
        self.removed = removed
        self.moved = moved
    }
}

public struct View<T: Model> {
    public var indexes: Delta<[Int]> = Delta(mode: .initial, changed: [], added: [], removed: [], moved: [])

    public init(by areInIncreasingOrder: @escaping (T, T) -> Bool) {
        self.areInIncreasingOrder = areInIncreasingOrder
        self.orderedView = []
    }
    
    public mutating func process(delta: Delta<[T]>) {
        indexes = Delta(mode: delta.mode, changed: [], added: [], removed: [], moved: [])
        
        guard delta.mode != .initial else {
            orderedView = delta.changed.map { .unchanged($0) }
            orderedView = orderedView.sorted(by: { (lhs, rhs) in
                return areInIncreasingOrder(lhs.value, rhs.value)
            })
            return
        }
        
        // Deletes must be processed first, since the indexes are relative to the old content
        delta.removed.forEach { element in
            if let index = orderedView.index(where: { $0.value == element }) {
                indexes.removed.append(index)
            }
        }
        
        // Now that the removed indexes are recorded, we can go ahead and delete the elements (in reverse order)
        indexes.removed.reversed().forEach { orderedView.remove(at: $0) }
        
        // Now process inserts and changes without recording indexes
        delta.added.forEach { element in
            orderedView.append(.inserted(element))
        }
        delta.changed.forEach { element in
            if let index = orderedView.index(where: { $0.value == element }) {
                orderedView[index] = .updated(element)
            }
        }
        
        // Sort the new updated content
        orderedView = orderedView.sorted(by: { (lhs, rhs) in
            return areInIncreasingOrder(lhs.value, rhs.value)
        })
        
        // Find the inserted and changed indexes
        delta.added.forEach { element in
            if let index = orderedView.index(where: { $0.value == element }) {
                indexes.added.append(index)
            }
        }
        delta.changed.forEach { element in
            if let index = orderedView.index(where: { $0.value == element }) {
                indexes.changed.append(index)
            }
        }
    }

    private var orderedView: [Change<T>]
    private let areInIncreasingOrder: (T, T) -> Bool
}

extension View: Sequence {
    public typealias Iterator = ViewIterator<T>

    public struct ViewIterator<T: Model>: IteratorProtocol {
        public typealias Element = T
        
        init(_ iterator: IndexingIterator<[Change<T>]>) {
            self.iterator = iterator
        }
        
        public mutating func next() -> T? {
            return iterator.next()?.value
        }
        private var iterator: IndexingIterator<[Change<T>]>
    }

    public func makeIterator() -> Iterator {
        return ViewIterator(orderedView.makeIterator())
    }
}

extension View: Collection {
    public typealias Index = Int
    
    public var startIndex: Index {
        return orderedView.startIndex
    }
    
    public var endIndex: Index {
        return orderedView.endIndex
    }
    
    public subscript (position: Index) -> Iterator.Element {
        return orderedView[position].value
    }

    public func index(after i: Index) -> Index {
        return orderedView.index(after: i)
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
            case (.initial, .deleted):
                break
            case (.initial, _):
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
        return Delta(mode: mode, changed: changed, added: added, removed: removed, moved: moved)
    }

    public func count<T>(mode: Mode) -> Delta<Int> where Element == Change<T> {
        let delta = self.delta(mode: mode)
        return Delta<Int>(mode: mode, changed: delta.changed.count, added: delta.added.count, removed: delta.removed.count, moved: delta.moved.count)
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
