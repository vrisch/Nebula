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

extension ListDelta: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case let .all(items): return "all: \(items.count)"
        case let .delta(added, removed): return "Δ: \(added.count) added, \(removed.count) removed"
        }
        
    }
}

extension Diff: CustomStringConvertible where T == Int {

    public var description: String {
        return "∑: \(added) added, \(removed) removed, \(changed) changed"
    }
}

extension Sequence {
    
    public func delta<T>(mode: Mode) -> ListDelta<T> where Element == Change<T> {
        var changed: [T] = []
        var added: [T] = []
        var removed: [T] = []
        forEach { change in
            switch (mode, change) {
            case (.initial, .deleted):
                break
            case (.initial, _):
                changed.append(change.item)
                
            case (.changes, .deleted):
                removed.append(change.item)
            case (.changes, .inserted):
                added.append(change.item)
            default: break
            }
        }
        switch mode {
        case .initial: return .all(changed)
        case .changes: return .delta(added: added, removed: removed)
        }
    }
    
    public func delta<T>(where predicate: (T) -> Bool, mode: Mode) -> ItemDelta<T> where Element == Change<T> {
        guard let change = first(where: { predicate($0.item) }) else { return .nothing }
        guard case .changes = mode else { return .changed(change.item) }
        switch change {
        case let .deleted(item): return .removed(item)
        case let .inserted(item): return .changed(item)
        case let .updated(item): return .changed(item)
        case .unchanged: return .nothing
        }
    }
    
    public func count<T>(mode: Mode) -> Count where Element == Change<T> {
        var added = 0
        var removed = 0
        var changed = 0
        forEach { change in
            switch change {
            case .deleted: removed += 1
            case .inserted: added += 1
            case .updated: changed += 1
            case .unchanged: break
            }
        }
        switch mode {
        case .initial: return Count(added: added + removed + changed, removed: 0, changed: 0)
        case .changes: return Count(added: added, removed: removed, changed: changed)
        }
    }

    public func needsNormalization<T>() -> Bool where Element == Change<T> {
        let count = self.count(mode: .changes)
        return count.added > 0 || count.removed > 0 || count.changed > 0
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
