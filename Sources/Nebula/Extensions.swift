//
//  Extensions.swift
//  Nebula-iOS
//
//  Created by Magnus Nilsson on 2017-08-28.
//  Copyright © 2017 Nebula. All rights reserved.
//

import Foundation

extension View: Sequence {
    public typealias Iterator = Array<T>.Iterator
    
    public func makeIterator() -> Iterator {
        return items.makeIterator()
    }
}

extension View: Collection {
    public typealias Index = Int
    
    public var startIndex: Int {
        return items.startIndex
    }

    public var endIndex: Int {
        return items.endIndex
    }

    public subscript (position: Int) -> Iterator.Element {
        return items[position]
    }

    public func index(after i: Int) -> Int {
        return items.index(after: i)
    }
}

extension Delta: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case let .initial(items): return "Δ:initial: \(items.count)"
        case let .list(added, removed): return "Δ:list: \(added.count) added, \(removed.count) removed"
        case let .element(added, removed, changed, moved): return "Δ:element: \(added.count) added, \(removed.count) removed, \(changed.count) changed, \(moved.count) moved"
        }
        
    }
}

extension Diff: CustomStringConvertible where T == Int {
    
    public var description: String {
        return "∑: \(added) added, \(removed) removed, \(changed) changed, \(moved) moved"
    }
}

extension Sequence {
    
    public func delta<T>(mode: Mode) -> Delta<T> where Element == Change<T> {
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
                changed.append(change.item)
                
            case (.element, .deleted):
                removed.append(change.item)
            case (.element, .inserted):
                added.append(change.item)
            case (.element, .unchanged):
                if hasMovement { moved.append(change.item) }
            case (.element, .updated):
                changed.append(change.item)
                
            case (.list, .deleted):
                removed.append(change.item)
            case (.list, .inserted):
                added.append(change.item)
            default: break
            }
            
            switch change {
            case .inserted, .deleted: hasMovement = true
            default: break
            }
        }
        switch mode {
        case .initial: return .initial(changed)
        case .list: return .list(added: added, removed: removed)
        case .element: return .element(added: added, removed: removed, changed: changed, moved: moved)
        }
    }
    
    public func count<T>(mode: Mode) -> Count where Element == Change<T> {
        switch self.delta(mode: mode) {
        case let .initial(items): return Count(added: items.count, removed: 0, changed: 0, moved: 0)
        case let .list(added, removed): return Count(added: added.count, removed: removed.count, changed: 0, moved: 0)
        case let .element(added, removed, changed, moved):
            return Count(added: added.count, removed: removed.count, changed: changed.count, moved: moved.count)
        }
    }
    
    public func needsNormalization<T>() -> Bool where Element == Change<T> {
        let count = self.count(mode: .element)
        return count.changed > 0 || count.added > 0 || count.removed > 0
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
