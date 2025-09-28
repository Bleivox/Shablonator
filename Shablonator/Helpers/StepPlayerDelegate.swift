//
//  StepPlayerDelegate.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//

import UIKit
import SnapKit


protocol StepPlayerDelegate: AnyObject {
    func stepPlayerDidFinish(_ player: StepPlayerViewController, state: StepState)
    func stepPlayerDidCancel(_ player: StepPlayerViewController)
}
