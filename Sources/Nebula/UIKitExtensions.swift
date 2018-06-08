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
    
    public func apply(delta: Delta<Int>) {
        switch delta.mode {
        case .initial:
            reloadData()
        case .list, .element:
            guard !delta.isEmpty else { return }
            performBatchUpdates({
                insertItems(at: delta.added.map { IndexPath(item: $0, section: 0) })
                reloadItems(at: delta.changed.map { IndexPath(item: $0, section: 0) })
                deleteItems(at: delta.removed.map { IndexPath(item: $0, section: 0) })
            }) { [collectionViewLayout] _ in
                collectionViewLayout.invalidateLayout()
            }
        }
    }
}
#endif
