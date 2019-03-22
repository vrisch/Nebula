#if canImport(UIKit)
import UIKit

public extension UICollectionView {

    func apply(delta: ListDelta<IndexPath>) {
        switch delta {
        case .all:
            reloadData()
        case let .delta(added, removed):
            guard !delta.isEmpty else { return }
            performBatchUpdates({
                insertItems(at: added.map { $0 })
                deleteItems(at: removed.map { $0 })
            }) { [collectionViewLayout] _ in
                collectionViewLayout.invalidateLayout()
            }
        }
    }
}
#endif
