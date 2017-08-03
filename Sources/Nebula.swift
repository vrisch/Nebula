//
//  Nebula.swift
//  Nebula
//
//  Created by Vrisch on 2017-06-30.
//  Copyright © 2017 Nebula. All rights reserved.
//

import Foundation

public enum Change<T> {
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
    
    public static func changes<S: Sequence>(_ changes: S, _ mode: Mode) -> [T] where S.Element == Change<T> {
        var result: [T] = []
        changes.forEach { change in
            switch change {
            case let .inserted(value):
                if mode == .all || mode == .element || mode == .list { result.append(value) }
            case let .deleted(value):
                if mode == .all || mode == .list { result.append(value) }
            case let .unchanged(value):
                if mode == .all { result.append(value) }
            case let .updated(value):
                if mode == .element { result.append(value) }
            }
        }
        return result
    }

    public static func deletions<S: Sequence>(_ changes: S) -> [T] where S.Element == Change<T> {
        var result: [T] = []
        changes.forEach { change in
            if case let .deleted(value) = change {
                result.append(value)
            }
        }
        return result
    }
    
    public static func insertions<S: Sequence>(_ changes: S) -> [T] where S.Element == Change<T> {
        var result: [T] = []
        changes.forEach { change in
            if case let .inserted(value) = change {
                result.append(value)
            }
        }
        return result
    }

    public static func count<S: Sequence>(_ changes: S) -> (deleted: Int, inserted: Int, unchanged: Int, updated: Int) where S.Element == Change<T> {
        var result: (deleted: Int, inserted: Int, unchanged: Int, updated: Int) = (deleted: 0, inserted: 0, unchanged: 0, updated: 0)
        for change in changes {
            switch change {
            case .deleted: result.0 += 1
            case .inserted: result.1 += 1
            case .unchanged: result.2 += 1
            case .updated: result.3 += 1
            }
        }
        return result
    }

    public static func hasChanges<S: Sequence>(_ changes: S) -> Bool where S.Element == Change<T> {
        let (deleted, inserted, _, updated) = count(changes)
        return deleted > 0 || inserted > 0 || updated > 0
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
