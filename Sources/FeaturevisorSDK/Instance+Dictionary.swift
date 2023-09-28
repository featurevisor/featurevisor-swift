//
//  Instance+Dictionary.swift
//  
//
//  Created by Patryk Piwowarczyk on 28/09/2023.
//

import Foundation

extension FeaturevisorInstance {

    func toDictionary(_ evaluation: Evaluation) -> [String: Any] {

        var dictionary = [String: Any]()
        let mirror = Mirror(reflecting: self)

        for child in mirror.children {
            if let key = child.label {
                dictionary[key] = child.value
            }
        }
        return dictionary
    }
}
