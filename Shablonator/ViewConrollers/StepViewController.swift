//
//  StepViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 09.09.25.
//

import Foundation
import UIKit
import SnapKit

class StepViewController: UIViewController {
    

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Шаг"
        view.backgroundColor = .clear

        let l = UILabel()
        l.text = title
        l.textColor = .label
        view.addSubview(l)
        l.snp.makeConstraints { $0.center.equalToSuperview() }

    }
}
