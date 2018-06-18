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
        switch delta.mode {
        case .initial:
            reloadData()
        case .list, .element:
            guard !delta.isEmpty else { return }
            performBatchUpdates({
                insertItems(at: delta.added.map { $0 })
                reloadItems(at: delta.changed.map { $0 })
                deleteItems(at: delta.removed.map { $0 })
            }) { [collectionViewLayout] _ in
                collectionViewLayout.invalidateLayout()
            }
        }
    }
}
#endif
