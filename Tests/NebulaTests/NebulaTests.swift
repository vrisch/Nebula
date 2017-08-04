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

struct Test: Model {
    let id: String
}

class NebulaTests: XCTestCase {

    func testConvertable() {
        var state: [String: Test] = [:]
        let data: [Change<Test>] = []
        let delta = Change.delta(data, .all)
        delta.changed?.forEach { state[$0.id] = $0 }
        XCTAssertEqual(delta.isEmpty, true)
    }
    
    static var allTests = [
        ("testConvertable", testConvertable),
    ]
}
