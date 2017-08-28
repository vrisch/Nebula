//
//  UIKitExtensions.swift
//  Nebula-iOS
//
//  Created by Magnus Nilsson on 2017-08-28.
//  Copyright © 2017 Nebula. All rights reserved.
//

import Foundation
import UIKit

public extension UICollectionView {
    
    public func apply(delta: Delta<Int>) {
        guard !delta.isEmpty else { return }
        
        switch delta.mode {
        case .initial: reloadData()
        case .list, .element:
            performBatchUpdates({
                insertItems(at: delta.added.map { IndexPath(item: $0, section: 0) })
                reloadItems(at: delta.changed.map { IndexPath(item: $0, section: 0) })
                deleteItems(at: delta.removed.map { IndexPath(item: $0, section: 0) })
            }, completion: nil)
        }
    }
}
