//
//  UITableViewExtensions.swift
//  RescueLink
//
//  Created by Dario Talarico on 6/16/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import UIKit

class UITableViewCellWithButton: UITableViewCell {
    @IBOutlet weak var button: UIButton!
}

extension UITableView {
    func dequeueReusableButtonCell(withIdentifier: String, indexPath: IndexPath) -> UITableViewCellWithButton? {
        let cell: UITableViewCellWithButton? =
                self.dequeueReusableCustomCell(withIdentifier: withIdentifier)
        cell?.button.setTheme()
        cell?.button.addTargetClosure { [weak self] _ in
            if let this = self {
                this.delegate?.tableView?(this, didSelectRowAt: indexPath)
            }
        }
        return cell
    }

    func dequeueReusableCustomCell<A: UITableViewCell>(withIdentifier: String) -> A? {
        return self.dequeueReusableCell(withIdentifier: withIdentifier) as? A
    }
}
