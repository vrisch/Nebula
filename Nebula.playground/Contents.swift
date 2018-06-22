import Nebula
import PlaygroundSupport
import UIKit

let frame = CGRect(x: 0, y: 0, width: 300, height: 600)
let layout = UICollectionViewFlowLayout()
layout.itemSize = CGSize(width: 300, height: 10)
layout.minimumLineSpacing = 0
layout.minimumInteritemSpacing = 0
let liveView = UICollectionView(frame: frame, collectionViewLayout: layout)
liveView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
liveView.backgroundColor = .white
PlaygroundPage.current.liveView = liveView

extension CIColor: Comparable {

    static func group(_ color: CIColor) -> Int {
        switch color.red {
        case 0.8...: return 0
        default: return 1
        }
    }

    public static func < (lhs: CIColor, rhs: CIColor) -> Bool {
        let lg = group(lhs)
        let rg = group(rhs)
        guard lg == rg else { return lg < rg }
        return lhs.red < rhs.red && lhs.green < rhs.green && lhs.blue < rhs.blue
    }
    
    static func random() -> CIColor {
        return CIColor(red: CGFloat.random(in: 0.0...1.0), green: CGFloat.random(in: 0.0...1.0), blue: CGFloat.random(in: 0.0...1.0))
    }
}

extension Delta where T == CIColor {
    static func random(mode: Mode, existing values: View<CIColor>) -> Delta {
        var changed: [T] = []
        var added: [T] = []
        var removed: [T] = []
        for _ in 0..<10 {
            switch Int.random(in: 0..<100) {
            case 0..<60:
                added.append(CIColor.random())
            case 60..<80:
                if let existing = values.randomElement() {
                    removed.append(existing)
                }
            default:
                if let existing = values.randomElement() {
                    changed.append(existing)
                }
            }
        }
        switch mode {
        case .initial: return .initial(added)
        case .list: return .list(added: added, removed: removed)
        case .element: return .element(added: added, removed: removed, changed: changed, moved: [])
        }
    }
}

var view = View<CIColor>(order: <, group: CIColor.group)

class DataSource: NSObject, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        print("checking number of groups")
        return view.numberOfGroups
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("checking range of group \(section)")
        let count = view.rangeOf(group: section).count - 1
        print("numberOfItemsInSection is \(count)")
        return count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        print("cell check groups \(indexPath.section < view.numberOfGroups)")
        print("cell for \(indexPath)")
        cell.contentView.backgroundColor = UIColor(ciColor: view[indexPath])
        return cell
    }
}
let dataSource = DataSource()
liveView.dataSource = dataSource

let delta: Delta<CIColor> = .initial([.random(), .random(), .random()])
view.apply(delta: delta)
liveView.apply(delta: view.indexes(mode: .initial))

let timerSource = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
timerSource.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(100))
timerSource.setEventHandler {
    view.apply(delta: Delta.random(mode: .list, existing: view))
    liveView.apply(delta: view.indexes(mode: .list))
}
timerSource.resume()



