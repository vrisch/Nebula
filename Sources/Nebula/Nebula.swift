//
//  Nebula.swift
//  Nebula
//
//  Created by Vrisch on 2017-06-30.
//  Copyright © 2017 Nebula. All rights reserved.
//

import Foundation

public enum Change<T: Equatable> {
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

public enum Delta<T: Equatable> {
    case initial([T])
    case list(added: [T], removed: [T])
    case element(added: [T], removed: [T], changed: [T], moved: [T])
    
    public var isEmpty: Bool {
        switch self {
        case let .initial(items): return items.isEmpty
        case let .list(added, removed): return added.isEmpty && removed.isEmpty
        case let .element(added, removed, changed, moved): return added.isEmpty && removed.isEmpty && changed.isEmpty && moved.isEmpty
        }
    }
    
    public static func +(lhs: Delta, rhs: Delta) -> Delta {
        switch (lhs, rhs) {
        case (.initial(let li), .initial(let ri)): return .initial(li + ri)
        case (.list(let la, let lr), .list(let ra, let rr)): return .list(added: la + ra, removed: lr + rr)
        case (.element(let la, let lr, let lc, let lm), .element(let ra, let rr, let rc, let rm)): return .element(added: la + ra, removed: lr + rr, changed: lc + rc, moved: lm + rm)
        default:
            fatalError()
        }
    }
}

public struct Diff<T: Equatable> {
    public var added: T
    public var removed: T
    public var changed: T
    public var moved: T
    
    public init(added: T, removed: T, changed: T, moved: T) {
        self.added = added
        self.removed = removed
        self.changed = changed
        self.moved = moved
    }
}

public typealias Count = Diff<Int>

public final class View<T: Equatable> {
    public init(order: @escaping (T, T) -> Bool) {
        self.orderBy = order
        self.items = []
        self.indexes = Diff<[Int]>(added: [], removed: [], changed: [], moved: [])
    }

    public func changes(mode: Mode, section: Int = 0) -> Delta<IndexPath> {
        switch mode {
        case .initial: return .initial(items.enumerated().map { IndexPath(item: $0.0, section: section) })
        case .list: return .list(added: indexes.added.map { IndexPath(item: $0, section: section) }, removed: indexes.removed.map { IndexPath(item: $0, section: section) })
        case .element: return .element(added: indexes.added.map { IndexPath(item: $0, section: section) }, removed: indexes.removed.map { IndexPath(item: $0, section: section) }, changed: indexes.changed.map { IndexPath(item: $0, section: section) }, moved: indexes.moved.map { IndexPath(item: $0, section: section) })
        }
    }
    
    public func apply(delta: Delta<T>) {
        indexes = Diff<[Int]>(added: [], removed: [], changed: [], moved: [])
        
        switch delta {
        case let .initial(items):
            process(added: items, removed: [], changed: [], moved: [])
        case let .list(added, removed):
            process(added: added, removed: removed, changed: [], moved: [])
        case let .element(added, removed, changed, moved):
            process(added: added, removed: removed, changed: changed, moved: moved)
        }
    }


    private func process(added: [T], removed: [T], changed: [T], moved: [T]) {
        // Deletes must be processed first, since the indexes are relative to the old content
        removed.forEach { element in
            if let index = items.index(where: { $0 == element }) {
                indexes.removed.append(index)
            }
        }

        // Sort removed indexes
        indexes.removed = indexes.removed.sorted(by: <)
        
        // Now that the removed indexes are recorded, we can go ahead and delete the elements (in reverse order)
        indexes.removed.reversed().forEach { items.remove(at: $0) }

        // Now process inserts and changes without recording indexes
        added.forEach { element in
            items.append(element)
        }
        changed.forEach { element in
            if let index = items.index(where: { $0 == element }) {
                items[index] = element
            }
        }
        
        // Sort the new updated content
        items = items.sorted(by: orderBy)

        // Find the inserted and changed indexes
        added.forEach { element in
            if let index = items.index(where: { $0 == element }) {
                indexes.added.append(index)
            }
        }
        changed.forEach { element in
            if let index = items.index(where: { $0 == element }) {
                indexes.changed.append(index)
            }
        }
        
        // Sort added and changed indexes
        indexes.added = indexes.added.sorted(by: <)
        indexes.changed = indexes.changed.sorted(by: <)
    }

    internal var items: [T]
    private var indexes: Diff<[Int]>
    private let orderBy: (T, T) -> Bool
}
