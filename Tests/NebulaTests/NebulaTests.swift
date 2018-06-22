//
//  NebulaTests.swift
//  Nebula
//
//  Created by Vrisch on {TODAY}.
//  Copyright © 2017 Nebula. All rights reserved.
//

import Foundation
import XCTest
import Nebula

struct Test: Equatable {
    let id: String
}

extension String {
    static func group(_ lhs: String) -> Int {
        switch lhs.first  {
        case "A": return 0
        case "B": return 1
        default: return 2
        }
    }
}

class NebulaTests: XCTestCase {

    func testConvertable() {
        var state: [String: Test] = [:]
        let data: [Change<Test>] = []
        let delta = data.delta(mode: .initial)
        if case let .initial(items) = delta {
            items.forEach { state[$0.id] = $0 }
            XCTAssertEqual(delta.isEmpty, true)
        } else {
            XCTFail()
        }
    }

    func testView1() {
        var view = View<String>(order: <, group: { _ in 0 })
        let delta: Delta<String> = .initial(["Banana", "Apple", "Strawberry"])

        view.apply(delta: delta)
        let indexes = view.indexes(mode: .initial)

        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(view[IndexPath(item: 0, section: 0)], "Apple")
        XCTAssertEqual(view[IndexPath(item: 1, section: 0)], "Banana")
        XCTAssertEqual(view[IndexPath(item: 2, section: 0)], "Strawberry")
        if case let .initial(items) = indexes {
            XCTAssertEqual(items.count, 3)
            XCTAssertEqual(items, [
                IndexPath(item: 0, section: 0),
                IndexPath(item: 1, section: 0),
                IndexPath(item: 2, section: 0)
                ])
        } else {
            XCTFail()
        }
    }

    func testView2() {
        var view = View<String>(order: <, group: { _ in 0 })
        let delta1: Delta<String> = .initial(["Banana", "Apple", "Strawberry"])

        view.apply(delta: delta1)
        
        let delta2: Delta<String> = .list(added: ["Cherry"], removed: [])

        view.apply(delta: delta2)
        let indexes = view.indexes(mode: .list)

        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Apple", "Banana", "Cherry", "Strawberry"])

        if case let .list(added, removed) = indexes {
            XCTAssertEqual(added, [
                IndexPath(item: 2, section: 0)
                ])
            XCTAssertEqual(removed, [])
        } else {
            XCTFail()
        }
    }

    func testView3() {
        var view = View<String>(order: <, group: { _ in 0 })
        let delta1: Delta<String> = .initial(["Banana", "Apple", "Strawberry"])

        view.apply(delta: delta1)

        let delta2: Delta<String> = .element(added: ["Cherry"], removed: ["Strawberry"], changed: ["Apple"], moved: [])

        view.apply(delta: delta2)
        let indexes = view.indexes(mode: .element)

        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Apple", "Banana", "Cherry"])
        
        if case let .element(added, removed, changed, moved) = indexes {
            XCTAssertEqual(changed, [
                IndexPath(item: 0, section: 0)
                ])
            XCTAssertEqual(added, [
                IndexPath(item: 2, section: 0)
                ])
            XCTAssertEqual(removed, [
                IndexPath(item: 2, section: 0)
                ])
            XCTAssertEqual(moved, [])
        } else {
            XCTFail()
        }
    }

    func testView4() {
        var view = View<String>(order: <, group: { _ in 0 })
        let delta1: Delta<String> = .initial(["Banana", "Apple", "Strawberry"])
        
        view.apply(delta: delta1)
        
        let delta2: Delta<String> = .element(added: ["Cherry"], removed: ["Strawberry"], changed: ["Apple"], moved: [])

        view.apply(delta: delta2)
        
        let delta3: Delta<String> = .element(added: ["Pineapple"], removed: [], changed: ["Cherry", "Banana"], moved: [])
        
        view.apply(delta: delta3)
        let indexes = view.indexes(mode: .element)

        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Apple", "Banana", "Cherry", "Pineapple"])

        if case let .element(added, removed, changed, moved) = indexes {
            XCTAssertEqual(changed, [
                IndexPath(item: 1, section: 0),
                IndexPath(item: 2, section: 0)
                ])
            XCTAssertEqual(added, [
                IndexPath(item: 3, section: 0)
                ])
            XCTAssertEqual(removed, [])
            XCTAssertEqual(moved, [])
        } else {
            XCTFail()
        }
    }

    func testView5() {
        var view = View<String>(order: <, group: { _ in 0 })
        let delta1: Delta<String> = .initial(["Pineapple", "Cherry", "Banana", "Apple", "Strawberry"])

        view.apply(delta: delta1)
        
        let delta2: Delta<String> = .list(added: [], removed: ["Cherry", "Strawberry", "Pineapple", "Apple"])

        view.apply(delta: delta2)
        let indexes = view.indexes(mode: .list)

        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Banana"])
        
        if case let .list(added, removed) = indexes {
            XCTAssertEqual(added, [])
            XCTAssertEqual(removed, [
                IndexPath(item: 0, section: 0),
                IndexPath(item: 2, section: 0),
                IndexPath(item: 3, section: 0),
                IndexPath(item: 4, section: 0)
                ])
        } else {
            XCTFail()
        }
    }

    func testView6() {
        var view = View<String>(order: <, group: String.group)
        let delta: Delta<String> = .initial(["Banana", "Apple", "Strawberry", "Cherry"])

        view.apply(delta: delta)
        let indexes = view.indexes(mode: .initial)
        
        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(view[IndexPath(item: 0, section: 0)], "Apple")
        XCTAssertEqual(view[IndexPath(item: 0, section: 1)], "Banana")
        XCTAssertEqual(view[IndexPath(item: 0, section: 2)], "Cherry")
        XCTAssertEqual(view[IndexPath(item: 1, section: 2)], "Strawberry")
        XCTAssertEqual(view.numberOfGroups, 3)
        XCTAssertEqual(view.rangeOf(group: 0), 0...1)
        XCTAssertEqual(view.rangeOf(group: 1), 1...2)
        XCTAssertEqual(view.rangeOf(group: 2), 2...4)
        if case let .initial(items) = indexes {
            XCTAssertEqual(items.count, 4)
            XCTAssertEqual(items, [
                IndexPath(item: 0, section: 0),
                IndexPath(item: 0, section: 1),
                IndexPath(item: 0, section: 2),
                IndexPath(item: 1, section: 2)
                ])
        } else {
            XCTFail()
        }
    }

    static var allTests = [
        ("testConvertable", testConvertable),
        ("testView1", testView1),
        ("testView2", testView2),
        ("testView3", testView3),
        ("testView4", testView4),
        ("testView5", testView5),
        ("testView6", testView6),
    ]
}
