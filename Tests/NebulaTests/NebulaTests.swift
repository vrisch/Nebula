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
        if case let .initial(items) = delta {
            items.forEach { state[$0.id] = $0 }
            XCTAssertEqual(delta.isEmpty, true)
        } else {
            XCTFail()
        }
    }
    
    func testView1() {
        let view = View<String>(order: <)
        let delta: Delta<String> = .initial(["Banana", "Apple", "Strawberry"])
        
        view.apply(delta: delta)
        let changes = view.changes(mode: .initial, section: 0)
        
        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(view[0], "Apple")
        XCTAssertEqual(view[1], "Banana")
        XCTAssertEqual(view[2], "Strawberry")
        if case let .initial(items) = changes {
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
        let delta1: Delta<String> = .initial(["Banana", "Apple", "Strawberry"])
        
        view.apply(delta: delta1)
        
        let delta2: Delta<String> = .list(added: ["Cherry"], removed: [])
        
        view.apply(delta: delta2)
        let changes = view.changes(mode: .list, section: 1)
        
        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(view.count, 4)
        XCTAssertEqual(Array(view), ["Apple", "Banana", "Cherry", "Strawberry"])
        
        if case let .list(added, removed) = changes {
            XCTAssertEqual(added, [
                IndexPath(item: 2, section: 1)
            ])
            XCTAssertEqual(removed, [])
        } else {
            XCTFail()
        }
    }

    func testView3() {
        let view = View<String>(order: <)
        let delta1: Delta<String> = .initial(["Banana", "Apple", "Strawberry"])
        
        view.apply(delta: delta1)
        
        let delta2: Delta<String> = .element(added: ["Cherry"], removed: ["Strawberry"], changed: ["Apple"], moved: [])
        
        view.apply(delta: delta2)
        let changes = view.changes(mode: .element, section: 2)
        
        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Apple", "Banana", "Cherry"])
        
        if case let .element(added, removed, changed, moved) = changes {
            XCTAssertEqual(changed, [
                IndexPath(item: 0, section: 2)
            ])
            XCTAssertEqual(added, [
                IndexPath(item: 2, section: 2)
            ])
            XCTAssertEqual(removed, [
                IndexPath(item: 2, section: 2)
            ])
            XCTAssertEqual(moved, [])
        } else {
            XCTFail()
        }
    }

    func testView4() {
        let view = View<String>(order: <)
        let delta1: Delta<String> = .initial(["Banana", "Apple", "Strawberry"])
        
        view.apply(delta: delta1)
        
        let delta2: Delta<String> = .element(added: ["Cherry"], removed: ["Strawberry"], changed: ["Apple"], moved: [])
        
        view.apply(delta: delta2)
        
        let delta3: Delta<String> = .element(added: ["Pineapple"], removed: [], changed: ["Cherry", "Banana"], moved: [])
        
        view.apply(delta: delta3)
        let changes = view.changes(mode: .element, section: 0)
        
        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Apple", "Banana", "Cherry", "Pineapple"])
        
        if case let .element(added, removed, changed, moved) = changes {
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
        let view = View<String>(order: <)
        let delta1: Delta<String> = .initial(["Pineapple", "Cherry", "Banana", "Apple", "Strawberry"])
        
        view.apply(delta: delta1)
        
        let delta2: Delta<String> = .list(added: [], removed: ["Cherry", "Strawberry", "Pineapple", "Apple"])
        
        view.apply(delta: delta2)
        let changes = view.changes(mode: .list, section: 0)
        
        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Banana"])
        
        if case let .list(added, removed) = changes {
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
        let view1 = View<String>(order: <)
        let view2 = View<String>(order: <)
        let delta1: Delta<String> = .initial(["Banana", "Apple", "Strawberry"])
        let delta2: Delta<String> = .initial(["Cherry", "Pineapple"])

        view1.apply(delta: delta1)
        view2.apply(delta: delta2)
        let changes1 = view1.changes(mode: .initial, section: 0)
        let changes2 = view2.changes(mode: .initial, section: 1)

        let changes: Delta<IndexPath> = changes1 + changes2

        if case let .initial(items) = changes {
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
}
