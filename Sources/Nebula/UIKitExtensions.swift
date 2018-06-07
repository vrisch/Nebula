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
        guard !delta.isEmpty else { return }
        
        switch delta.mode {
        case .initial:
            print("NEBULA: Reloading data")
            reloadData()
        case .list, .element:
            print("NEBULA: Batch updating")
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
