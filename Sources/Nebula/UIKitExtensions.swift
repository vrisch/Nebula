//
//  UIKitExtensions.swift
//  Nebula-iOS
//
//  Created by Magnus Nilsson on 2017-08-28.
//  Copyright © 2017 Nebula. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class ViewDataSource<T: Equatable, Cell: UICollectionViewCell>: NSObject, UICollectionViewDataSource {
    public init(view: View<T>, reuseIdentifier: String, configure: @escaping (T, Cell) -> Void) {
        self.view = view
        self.reuseIdentifier = reuseIdentifier
        self.configure = configure
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return view.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        if let cell = cell as? Cell {
            configure(view[indexPath.item], cell)
        }
        return cell
    }
    
    private let view: View<T>
    private let reuseIdentifier: String
    private let configure: (T, Cell) -> Void
}

public extension UICollectionView {

    public func apply(delta: Delta<Int>) {
        switch delta {
        case .initial:
            reloadData()
        case let .list(added, removed):
            guard !delta.isEmpty else { return }
            performBatchUpdates({
                insertItems(at: added.map { IndexPath(item: $0, section: 0) })
                deleteItems(at: removed.map { IndexPath(item: $0, section: 0) })
            }) { [collectionViewLayout] _ in
                collectionViewLayout.invalidateLayout()
            }
        case let .element(added, removed, changed, _):
            guard !delta.isEmpty else { return }
            performBatchUpdates({
                insertItems(at: added.map { IndexPath(item: $0, section: 0) })
                reloadItems(at: changed.map { IndexPath(item: $0, section: 0) })
                deleteItems(at: removed.map { IndexPath(item: $0, section: 0) })
            }) { [collectionViewLayout] _ in
                collectionViewLayout.invalidateLayout()
            }
        }
    }
}
#endif
