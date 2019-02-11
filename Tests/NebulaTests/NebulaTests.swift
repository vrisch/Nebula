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

class NebulaTests: XCTestCase {
    
    func testConvertable() {
        var state: [String: Test] = [:]
        let data: [Change<Test>] = []
        let delta = data.delta(mode: .initial)
        if case let .all(items) = delta {
            items.forEach { state[$0.id] = $0 }
            XCTAssertEqual(delta.isEmpty, true)
        } else {
            XCTFail()
        }
    }

    func testView1() {
        let view = View<String>(order: <)

        let delta: ListDelta<String> = .all(["Banana", "Apple", "Strawberry"])
        view.apply(delta: delta)

        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(view[0], "Apple")
        XCTAssertEqual(view[1], "Banana")
        XCTAssertEqual(view[2], "Strawberry")

        let changes = view.list(mode: .initial, section: 0)
        if case let .all(items) = changes {
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
        let view = View<String>(order: <)

        let delta1: ListDelta<String> = .all(["Banana", "Apple", "Strawberry"])
        view.apply(delta: delta1)
        
        let delta2: ListDelta<String> = .delta(added: ["Cherry"], removed: [])
        view.apply(delta: delta2)

        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(view.count, 4)
        XCTAssertEqual(Array(view), ["Apple", "Banana", "Cherry", "Strawberry"])

        let changes = view.list(mode: .changes)
        if case let .delta(added, removed) = changes {
            XCTAssertEqual(added, [
                IndexPath(item: 2, section: 0)
            ])
            XCTAssertEqual(removed, [])
        } else {
            XCTFail()
        }
    }

    func testView3() {
        let view = View<String>(order: <)

        let delta1: ListDelta<String> = .all(["Banana", "Apple", "Strawberry"])
        view.apply(delta: delta1)

        let delta2: ItemDelta<String> = .changed("Apple")
        let delta3: ListDelta<String> = .delta(added: ["Cherry"], removed: ["Strawberry"])

        view.apply(delta: delta2)
        view.apply(delta: delta3)

        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Apple", "Banana", "Cherry"])

        let changes = view.list(mode: .changes)
        if case let .delta(added, removed) = changes {
            XCTAssertEqual(added, [
                IndexPath(item: 2, section: 0)
            ])
            XCTAssertEqual(removed, [
                IndexPath(item: 2, section: 0)
            ])
        } else {
            XCTFail()
        }
    }

    func testView4() {
        let view = View<String>(order: <)

        let delta1: ListDelta<String> = .all(["Banana", "Apple", "Strawberry"])
        view.apply(delta: delta1)

        let delta2: ListDelta<String> = .delta(added: ["Cherry"], removed: ["Strawberry"])
        view.apply(delta: delta2)

        let delta3: ListDelta<String> = .delta(added: ["Pineapple"], removed: [])
        view.apply(delta: delta3)

        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Apple", "Banana", "Cherry", "Pineapple"])

        let changes = view.list(mode: .changes)
        if case let .delta(added, removed) = changes {
            XCTAssertEqual(added, [
                IndexPath(item: 3, section: 0)
            ])
            XCTAssertEqual(removed, [])
        } else {
            XCTFail()
        }
    }

    func testView5() {
        let view = View<String>(order: <)

        let delta1: ListDelta<String> = .all(["Pineapple", "Cherry", "Banana", "Apple", "Strawberry"])
        view.apply(delta: delta1)
        
        let delta2: ListDelta<String> = .delta(added: [], removed: ["Cherry", "Strawberry", "Pineapple", "Apple"])
        view.apply(delta: delta2)

        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Banana"])

        let changes = view.list(mode: .changes, section: 1)
        if case let .delta(added, removed) = changes {
            XCTAssertEqual(added, [])
            XCTAssertEqual(removed, [
                IndexPath(item: 0, section: 1),
                IndexPath(item: 2, section: 1),
                IndexPath(item: 3, section: 1),
                IndexPath(item: 4, section: 1)
            ])
        } else {
            XCTFail()
        }
    }

    func testView6() {
        let view1 = View<String>(order: <)
        let view2 = View<String>(order: <)
        let delta1: ListDelta<String> = .all(["Banana", "Apple", "Strawberry"])
        let delta2: ListDelta<String> = .all(["Cherry", "Pineapple"])

        view1.apply(delta: delta1)
        view2.apply(delta: delta2)
        let changes1 = view1.list(mode: .initial, section: 0)
        let changes2 = view2.list(mode: .initial, section: 1)

        let changes: ListDelta<IndexPath> = changes1 + changes2

        if case let .all(items) = changes {
            XCTAssertEqual(items.count, 5)
            XCTAssertEqual(items, [
                IndexPath(item: 0, section: 0),
                IndexPath(item: 1, section: 0),
                IndexPath(item: 2, section: 0),
                IndexPath(item: 0, section: 1),
                IndexPath(item: 1, section: 1),
                ])
        } else {
            XCTFail()
        }
    }

    func testView7() {
        let view = View<String>(order: <)
        
        let delta1: ListDelta<String> = .all(["Banana", "Apple", "Strawberry"])
        view.apply(delta: delta1)

        let delta2: ListDelta<String> = .delta(added: ["Cherry"], removed: [])
        view.apply(delta: delta2)

        let delta3: ListDelta<String> = .delta(added: [], removed: [])
        view.apply(delta: delta3)

        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(view.count, 4)
        XCTAssertEqual(Array(view), ["Apple", "Banana", "Cherry", "Strawberry"])
        
        let changes = view.list(mode: .changes)
        if case let .delta(added, removed) = changes {
            XCTAssertEqual(added, [])
            XCTAssertEqual(removed, [])
        } else {
            XCTFail()
        }
    }
}
