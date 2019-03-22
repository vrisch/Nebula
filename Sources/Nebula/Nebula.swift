import Foundation

public enum Change<Item: Equatable> {
    case deleted(Item)
    case inserted(Item)
    case unchanged(Item)
    case updated(Item)
    
    public var item: Item {
        switch self {
        case let .deleted(item): return item
        case let .inserted(item): return item
        case let .unchanged(item): return item
        case let .updated(item): return item
        }
    }
}

public enum Mode: String {
    case initial
    case changes
}

public enum ListDelta<Item: Equatable> {
    case all([Item])
    case delta(added: [Item], removed: [Item])

    public var isEmpty: Bool {
        switch self {
        case let .all(items): return items.isEmpty
        case let .delta(added, removed): return added.isEmpty && removed.isEmpty
        }
    }
    
    public func map<AnotherItem>(_ transform: (Item) -> AnotherItem) -> ListDelta<AnotherItem> {
        switch self {
        case let .all(items): return .all(items.map(transform))
        case let .delta(added, removed): return .delta(added: added.map(transform), removed: removed.map(transform))
        }
    }
    
    public static func +(lhs: ListDelta, rhs: ListDelta) -> ListDelta {
        switch (lhs, rhs) {
        case (.all(let li), .all(let ri)): return .all(li + ri)
        case (.delta(let la, let lr), .delta(let ra, let rr)): return .delta(added: la + ra, removed: lr + rr)
        default:
            fatalError()
        }
    }
}

public enum ItemDelta<Item: Equatable> {
    case changed(Item)
    case removed(Item)
    case nothing
}

public struct Diff<T: Equatable> {
    public var added: T
    public var removed: T
    public var changed: T
    
    public init(added: T, removed: T, changed: T) {
        self.added = added
        self.removed = removed
        self.changed = changed
    }
}

public typealias Count = Diff<Int>

public final class View<T: Equatable> {
    public init(order: @escaping (T, T) -> Bool) {
        self.orderBy = order
        self.items = []
        self.indexes = Diff<[Int]>(added: [], removed: [], changed: [])
    }

    public func list(mode: Mode, section: Int = 0) -> ListDelta<IndexPath> {
        switch mode {
        case .initial: return .all(items.enumerated().map { IndexPath(item: $0.0, section: section) })
        case .changes: return .delta(added: indexes.added.map { IndexPath(item: $0, section: section) }, removed: indexes.removed.map { IndexPath(item: $0, section: section) })
        }
    }
    
    public func apply(delta: ListDelta<T>) {
        switch delta {
        case let .all(items):
            process(added: items, removed: [], changed: [])
        case let .delta(added, removed):
            process(added: added, removed: removed, changed: [])
        }
    }
    
    public func apply(delta: ItemDelta<T>) {
        switch delta {
        case let .changed(item):
            process(added: [], removed: [], changed: [item])
        case let .removed(item):
            process(added: [], removed: [item], changed: [])
        case .nothing:
            break
        }
    }

    private func process(added: [T], removed: [T], changed: [T]) {
        // Reset indexes
        indexes = Diff<[Int]>(added: [], removed: [], changed: [])

        // Deletes must be processed first, since the indexes are relative to the old content
        removed.forEach { element in
            if let index = items.firstIndex(where: { $0 == element }) {
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
            if let index = items.firstIndex(where: { $0 == element }) {
                items[index] = element
            }
        }
        
        // Sort the new updated content
        items = items.sorted(by: orderBy)

        // Find the inserted and changed indexes
        added.forEach { element in
            if let index = items.firstIndex(where: { $0 == element }) {
                indexes.added.append(index)
            }
        }
        changed.forEach { element in
            if let index = items.firstIndex(where: { $0 == element }) {
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

extension View: CustomStringConvertible {
    public var description: String {
        return "items:\(items.count), added:\(indexes.added.count), removed:\(indexes.removed.count), changed:\(indexes.changed.count)"
    }
}
