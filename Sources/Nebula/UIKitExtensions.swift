//
//  UIKitExtensions.swift
//  Nebula-iOS
//
//  Created by Magnus Nilsson on 2017-08-28.
//  Copyright © 2017 Nebula. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public extension UICollectionView {

    public func apply(delta: Delta<IndexPath>) {
        switch delta {
        case .initial:
            reloadData()
        case let .list(added, removed):
            guard !delta.isEmpty else { return }
            performBatchUpdates({
                insertItems(at: added.map { $0 })
                deleteItems(at: removed.map { $0 })
            }) { [collectionViewLayout] _ in
                collectionViewLayout.invalidateLayout()
            }
        case let .element(added, removed, changed, _):
            guard !delta.isEmpty else { return }
            performBatchUpdates({
                insertItems(at: added.map { $0 })
                reloadItems(at: changed.map { $0 })
                deleteItems(at: removed.map { $0 })
            }) { [collectionViewLayout] _ in
                collectionViewLayout.invalidateLayout()
            }
        }
    }
}
#endif
