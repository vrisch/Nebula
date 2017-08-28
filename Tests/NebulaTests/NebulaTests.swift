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

extension String: Model {}

struct Test: Model, Equatable {
    let id: String

    static func ==(lhs: Test, rhs: Test) -> Bool {
        return lhs.id == rhs.id
    }
}

class NebulaTests: XCTestCase {

    func testConvertable() {
        var state: [String: Test] = [:]
        let data: [Change<Test>] = []
        let delta = data.delta(mode: .initial)
        delta.changed.forEach { state[$0.id] = $0 }
        XCTAssertEqual(delta.isEmpty, true)
    }
    
    func testView1() {
        var view = View<String>(by: <)
        let delta = Delta<String>(mode: .initial, changed: ["Banana", "Apple", "Strawberry"], added: [], removed: [], moved: [])

        view.apply(delta: delta)

        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(view[0], "Apple")
        XCTAssertEqual(view[1], "Banana")
        XCTAssertEqual(view[2], "Strawberry")
        XCTAssertEqual(view.indexes.mode, .initial)
        XCTAssertEqual(view.indexes.changed, [])
        XCTAssertEqual(view.indexes.added, [])
        XCTAssertEqual(view.indexes.removed, [])
        XCTAssertEqual(view.indexes.moved, [])
    }
    
    func testView2() {
        var view = View<String>(by: <)
        let delta1 = Delta<String>(mode: .initial, changed: ["Banana", "Apple", "Strawberry"], added: [], removed: [], moved: [])
        
        view.apply(delta: delta1)
        
        let delta2 = Delta<String>(mode: .list, changed: [], added: ["Cherry"], removed: [], moved: [])
        
        view.apply(delta: delta2)
        
        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Apple", "Banana", "Cherry", "Strawberry"])
        XCTAssertEqual(view.indexes.mode, .list)
        XCTAssertEqual(view.indexes.changed, [])
        XCTAssertEqual(view.indexes.added, [2])
        XCTAssertEqual(view.indexes.removed, [])
        XCTAssertEqual(view.indexes.moved, [])
    }
    
    func testView3() {
        var view = View<String>(by: <)
        let delta1 = Delta<String>(mode: .initial, changed: ["Banana", "Apple", "Strawberry"], added: [], removed: [], moved: [])
        
        view.apply(delta: delta1)
        
        let delta2 = Delta<String>(mode: .list, changed: ["Apple"], added: ["Cherry"], removed: ["Strawberry"], moved: [])

        view.apply(delta: delta2)
        
        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Apple", "Banana", "Cherry"])
        XCTAssertEqual(view.indexes.mode, .list)
        XCTAssertEqual(view.indexes.changed, [0])
        XCTAssertEqual(view.indexes.added, [2])
        XCTAssertEqual(view.indexes.removed, [2])
        XCTAssertEqual(view.indexes.moved, [])
    }
    
    func testView4() {
        var view = View<String>(by: <)
        let delta1 = Delta<String>(mode: .initial, changed: ["Banana", "Apple", "Strawberry"], added: [], removed: [], moved: [])
        
        view.apply(delta: delta1)
        
        let delta2 = Delta<String>(mode: .list, changed: ["Apple"], added: ["Cherry"], removed: ["Strawberry"], moved: [])
        
        view.apply(delta: delta2)
        
        let delta3 = Delta<String>(mode: .list, changed: ["Cherry", "Banana"], added: ["Pineapple"], removed: [], moved: [])
        
        view.apply(delta: delta3)

        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Apple", "Banana", "Cherry", "Pineapple"])
        XCTAssertEqual(view.indexes.mode, .list)
        XCTAssertEqual(view.indexes.changed, [1, 2])
        XCTAssertEqual(view.indexes.added, [3])
        XCTAssertEqual(view.indexes.removed, [])
        XCTAssertEqual(view.indexes.moved, [])
    }
    
    func testView5() {
        var view = View<String>(by: <)
        let delta1 = Delta<String>(mode: .initial, changed: ["Pineapple", "Cherry", "Banana", "Apple", "Strawberry"], added: [], removed: [], moved: [])
        
        view.apply(delta: delta1)
        
        let delta2 = Delta<String>(mode: .list, removed: ["Cherry", "Strawberry", "Pineapple", "Apple"])
        
        view.apply(delta: delta2)
        
        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Banana"])
        XCTAssertEqual(view.indexes.mode, .list)
        XCTAssertEqual(view.indexes.changed, [])
        XCTAssertEqual(view.indexes.added, [])
        XCTAssertEqual(view.indexes.removed, [0, 2, 3, 4])
        XCTAssertEqual(view.indexes.moved, [])
    }

    static var allTests = [
        ("testConvertable", testConvertable),
    ]
}
