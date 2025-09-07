//
//  StepsViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 05.09.25.
//
import UIKit
import Foundation
import SnapKit

final class StepsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        let l = UILabel(); l.text = "Шаги"; l.textColor = .label
        view.addSubview(l)
        l.snp.makeConstraints { $0.center.equalToSuperview() }
    }
}
