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
        let indexes = view.indexes(mode: .initial)
        
        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(view[0], "Apple")
        XCTAssertEqual(view[1], "Banana")
        XCTAssertEqual(view[2], "Strawberry")
        if case let .initial(items) = indexes {
            XCTAssertEqual(items.count, 3)
            XCTAssertEqual(items, [0, 1, 2])
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
        let indexes = view.indexes(mode: .list)
        
        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(view.count, 4)
        XCTAssertEqual(Array(view), ["Apple", "Banana", "Cherry", "Strawberry"])
        
        if case let .list(added, removed) = indexes {
            XCTAssertEqual(added, [2])
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
        let indexes = view.indexes(mode: .element)
        
        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Apple", "Banana", "Cherry"])
        
        if case let .element(added, removed, changed, moved) = indexes {
            XCTAssertEqual(changed, [0])
            XCTAssertEqual(added, [2])
            XCTAssertEqual(removed, [2])
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
        let indexes = view.indexes(mode: .element)
        
        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Apple", "Banana", "Cherry", "Pineapple"])
        
        if case let .element(added, removed, changed, moved) = indexes {
            XCTAssertEqual(changed, [1, 2])
            XCTAssertEqual(added, [3])
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
        let indexes = view.indexes(mode: .list)
        
        XCTAssertEqual(view.isEmpty, false)
        XCTAssertEqual(Array(view), ["Banana"])
        
        if case let .list(added, removed) = indexes {
            XCTAssertEqual(added, [])
            XCTAssertEqual(removed, [0, 2, 3, 4])
        } else {
            XCTFail()
        }
    }
    
    func testView6() {
        let view = View<String>(order: <)
        let delta1: Delta<String> = .initial(["Banana", "Apple", "Agave", "Strawberry"])
        view.apply(delta: delta1)
        
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "TEST")
        let dataSource = ViewDataSource(view: view, reuseIdentifier: "TEST")
        collectionView.dataSource = dataSource
        collectionView.apply(delta: view.indexes(mode: .initial))
        
        XCTAssertEqual(dataSource.numberOfSections(in: collectionView), 1)
        XCTAssertEqual(dataSource.collectionView(collectionView, numberOfItemsInSection: 0), 4)
        
        let delta2: Delta<String> = .element(added: [], removed: [], changed: ["Apple"], moved: [])
        view.apply(delta: delta2)
        
        XCTAssertEqual(dataSource.numberOfSections(in: collectionView), 1)
        XCTAssertEqual(dataSource.collectionView(collectionView, numberOfItemsInSection: 0), 4)
        
        if case let .element(added, removed, changed, moved) = view.indexes(mode: .element) {
            XCTAssertEqual(added.count, 0)
            XCTAssertEqual(removed.count, 0)
            XCTAssertEqual(changed.count, 1)
            XCTAssertEqual(moved.count, 0)
            collectionView.apply(delta: .element(added: added, removed: removed, changed: changed, moved: moved))
        } else {
            XCTFail()
        }
    }
    /*
    func testView7() {
        let view = View<String>(order: <)
        let delta1: Delta<String> = .initial(["Banana", "Apple", "Agave", "Strawberry"])
        view.apply(delta: delta1)
        
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "TEST")
        let dataSource = ViewDataSource(view: view, reuseIdentifier: "TEST")
        collectionView.dataSource = dataSource
        collectionView.apply(delta: view.indexes(mode: .initial))
        
        XCTAssertEqual(dataSource.numberOfSections(in: collectionView), 1)
        XCTAssertEqual(dataSource.collectionView(collectionView, numberOfItemsInSection: 0), 4)
        
        let delta2: Delta<String> = .list(added: ["Cherry"], removed: [])
        view.apply(delta: delta2)
        
        if case let .list(added, removed) = view.indexes(mode: .list) {
            XCTAssertEqual(added.count, 1)
            XCTAssertEqual(removed.count, 0)
            collectionView.apply(delta: .list(added: added, removed: removed))
        } else {
            XCTFail()
        }
        
        XCTAssertEqual(dataSource.numberOfSections(in: collectionView), 1)
        XCTAssertEqual(dataSource.collectionView(collectionView, numberOfItemsInSection: 0), 5)
    }

     func testView9() {
     let view = View<String>(order: <)
     let delta1: Delta<String> = .initial(["Banana", "Apple", "Agave", "Strawberry"])
     view.apply(delta: delta1)
     
     let layout = UICollectionViewFlowLayout()
     let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
     collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "TEST")
     let dataSource = ViewDataSource(view: view, reuseIdentifier: "TEST")
     collectionView.dataSource = dataSource
     collectionView.apply(delta: view.indexes(mode: .initial))
     
     XCTAssertEqual(dataSource.numberOfSections(in: collectionView), 1)
     XCTAssertEqual(dataSource.collectionView(collectionView, numberOfItemsInSection: 0), 4)
     
     let delta2: Delta<String> = .list(added: [], removed: ["Apple"])
     view.apply(delta: delta2)
     XCTAssertEqual(view.rangeOf(group: 0).count - 1, 3)
     
     XCTAssertEqual(dataSource.numberOfSections(in: collectionView), 1)
     XCTAssertEqual(dataSource.collectionView(collectionView, numberOfItemsInSection: 0), 3)
     
     if case let .list(added, removed) = view.indexes(mode: .list) {
     XCTAssertEqual(added.count, 0)
     XCTAssertEqual(removed.count, 1)
     collectionView.apply(delta: .list(added: added, removed: removed))
     } else {
     XCTFail()
     }
     }
     
     func testView10() {
     let view = View<String>(order: <, group: String.group)
     let delta1: Delta<String> = .initial(["Banana", "Apple", "Agave", "Strawberry"])
     view.apply(delta: delta1)
     
     let layout = UICollectionViewFlowLayout()
     let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
     collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "TEST")
     let dataSource = ViewDataSource(view: view, reuseIdentifier: "TEST")
     collectionView.dataSource = dataSource
     collectionView.reloadData()
     
     XCTAssertEqual(dataSource.numberOfSections(in: collectionView), 3)
     XCTAssertEqual(dataSource.collectionView(collectionView, numberOfItemsInSection: 0), 2)
     XCTAssertEqual(dataSource.collectionView(collectionView, numberOfItemsInSection: 1), 1)
     XCTAssertEqual(dataSource.collectionView(collectionView, numberOfItemsInSection: 2), 1)
     
     let delta2: Delta<String> = .list(added: [], removed: ["Apple"])
     view.apply(delta: delta2)
     XCTAssertEqual(view.rangeOf(group: 0).count - 1, 1)
     
     XCTAssertEqual(dataSource.numberOfSections(in: collectionView), 3)
     XCTAssertEqual(dataSource.collectionView(collectionView, numberOfItemsInSection: 0), 1)
     XCTAssertEqual(dataSource.collectionView(collectionView, numberOfItemsInSection: 1), 1)
     XCTAssertEqual(dataSource.collectionView(collectionView, numberOfItemsInSection: 2), 1)
     
     if case let .list(added, removed) = view.indexes(mode: .list) {
     XCTAssertEqual(added.count, 0)
     XCTAssertEqual(removed.count, 1)
     collectionView.apply(delta: .list(added: added, removed: removed))
     } else {
     XCTFail()
     }
     }
     */
}
