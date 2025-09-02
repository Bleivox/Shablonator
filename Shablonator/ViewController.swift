//
//  ViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 14.06.25.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Shablonator"
        
        let label = UILabel()
               label.text = "Hello"
               label.translatesAutoresizingMaskIntoConstraints = false

               view.addSubview(label)
               NSLayoutConstraint.activate([
                   label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                   label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
               ])
    }


}

