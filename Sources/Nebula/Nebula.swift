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

public struct View<T: Equatable> {
    public init(order: @escaping (T, T) -> Bool, group: @escaping (T) -> Int = { _ in 0 }) {
        self.orderBy = order
        self.groupBy = group
        self.groups = []
        self.items = []
        self.indexes = Diff<[IndexPath]>(added: [], removed: [], changed: [], moved: [])
    }
    
    public func indexes(mode: Mode) -> Delta<IndexPath> {
        switch mode {
        case .initial: return .initial(items.enumerated().map { indexPathFor($0.0) })
        case .list: return .list(added: indexes.added, removed: indexes.removed)
        case .element: return .element(added: indexes.added, removed: indexes.removed, changed: indexes.changed, moved: indexes.moved)
        }
    }
    
    public mutating func apply(delta: Delta<T>) {
        indexes = Diff<[IndexPath]>(added: [], removed: [], changed: [], moved: [])
        
        switch delta {
        case let .initial(items):
            process(added: items, removed: [], changed: [], moved: [])
        case let .list(added, removed):
            process(added: added, removed: removed, changed: [], moved: [])
        case let .element(added, removed, changed, moved):
            process(added: added, removed: removed, changed: changed, moved: moved)
        }
    }
    
    private mutating func process(added: [T], removed: [T], changed: [T], moved: [T]) {
        // Deletes must be processed first, since the indexes are relative to the old content
        removed.forEach { element in
            if let index = items.index(where: { $0 == element }) {
                indexes.removed.append(indexPathFor(index))
            }
        }

        // Sort removed indexes
        indexes.removed = indexes.removed.sorted(by: <)
        
        // Now that the removed indexes are recorded, we can go ahead and delete the elements (in reverse order)
        indexes.removed.reversed().forEach { items.remove(at: indexFor($0) ) }

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
        
        // Group items
        groups.removeAll()
        if let first = items.first {
            var startIndex = 0
            var currentIndex = 0
            var currentGroup = groupBy(first)
            items.forEach { item in
                let group = groupBy(item)
                if currentGroup != group {
                    groups.append(startIndex...currentIndex)
                    startIndex = currentIndex
                    currentGroup = group
                }
                currentIndex += 1
            }
            groups.append(startIndex...currentIndex)
        } else {
            groups.append(0...0)
        }

        // Find the inserted and changed indexes
        added.forEach { element in
            if let index = items.index(where: { $0 == element }) {
                indexes.added.append(indexPathFor(index))
            }
        }
        changed.forEach { element in
            if let index = items.index(where: { $0 == element }) {
                indexes.changed.append(indexPathFor(index))
            }
        }
        
        // Sort added and changed indexes
        indexes.added = indexes.added.sorted(by: <)
        indexes.changed = indexes.changed.sorted(by: <)
    }

    public var numberOfGroups: Int { return groups.count }
    
    public func rangeOf(group at: Int) -> ClosedRange<Int> { return groups[at] }
    
    internal func indexPathFor(_ index: Int) -> IndexPath {
        var item = index
        var section = 0
        for range in groups {
            if range.lowerBound + item >= range.upperBound {
                item -= (range.upperBound - range.lowerBound)
                section += 1
            } else {
                return IndexPath(item: item, section: section)
            }
        }
        return IndexPath(item: item, section: section)
    }

    internal func indexFor(_ indexPath: IndexPath) -> Int {
        let range = rangeOf(group: indexPath.section)
        return range.lowerBound + indexPath.item
    }

    internal var items: [T]
    internal var groups: [ClosedRange<Int>]
    private var indexes: Diff<[IndexPath]>
    private let orderBy: (T, T) -> Bool
    private let groupBy: (T) -> Int
}
