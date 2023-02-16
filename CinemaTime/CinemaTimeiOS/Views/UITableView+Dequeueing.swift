//  Created by Marcell Magyar on 07.12.22.

import UIKit

extension UITableView {
    func register<T: UITableViewCell>(_ cell: T.Type) {
        register(T.self, forCellReuseIdentifier: String(describing: T.self))
    }
    
    func dequeueReusableCell<T: UITableViewCell>() -> T {
        dequeueReusableCell(withIdentifier: String(describing: T.self)) as! T
    }
}
