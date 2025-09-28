//
//  HeaderCell.swift
//  Shablonator
//
//  Created by Никита Долгов on 19.09.25.
//

import UIKit

final class HeaderCell: UITableViewCell {
    static let reuse = "HeaderCell"
    private let toggle = UISwitch()
    var switchAction: ((Bool)->Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        accessoryView = toggle
        toggle.addAction(UIAction { [weak self] _ in
            self?.switchAction?(self?.toggle.isOn ?? false)
        }, for: .valueChanged)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(isOn: Bool) {
        toggle.isOn = isOn
        selectionStyle = .default
    }
}
