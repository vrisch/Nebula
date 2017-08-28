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
        return orderedView.makeIterator()
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
        return orderedView[position]
    }
    
    public func index(after i: Index) -> Index {
        return orderedView.index(after: i)
    }
}

extension Delta: CustomStringConvertible {
    
    public var description: String {
        return "Δ:\(mode), \(changed.count) changed, \(added.count) added, \(removed.count) removed, \(moved.count) moved"
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
        return Delta<Int>(mode: mode, changed: [delta.changed.count], added: [delta.added.count], removed: [delta.removed.count], moved: [delta.moved.count])
    }
    
    public func needsNormalization<T>() -> Bool where Element == Change<T> {
        let count = self.count(mode: .element)
        return count.changed.first! > 0 || count.added.first! > 0 || count.removed.first! > 0
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
