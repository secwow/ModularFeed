import Foundation
import FeedFramework
import ModularFeediOS
import UIKit

extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach({ target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach({ (selector) in
                (target as NSObject).perform(Selector(selector))
            })
        })
    }
}

extension UIButton {
    func simulateTap() {
        allTargets.forEach({ target in
            actions(forTarget: target, forControlEvent: .touchUpInside)?.forEach({ (selector) in
                (target as NSObject).perform(Selector(selector))
            })
        })
    }
}
