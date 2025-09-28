//
//  TemplateSearchDelegate.swift
//  Shablonator
//
//  Created by Никита Долгов on 15.09.25.
//


protocol TemplateSearchDelegate: AnyObject {
    func templateSearch(_ manager: TemplateSearchManager, didUpdateResults results: [TemplateModel])
    func templateSearchDidShowNoResults(_ manager: TemplateSearchManager)
}
