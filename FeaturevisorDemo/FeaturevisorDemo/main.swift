//
//  main.swift
//  FeaturevisorDemo
//
//  Created by Marcin Polak on 11/08/2023.
//

import Foundation
import FeaturevisorSDK
import FeaturevisorTypes

print("Hello, Featurevisor!")

let instanceOptions = InstanceOptions(
        datafileUrl: "https://your-datafile.json",
        logger: createLogger())

let featurevisor = createInstance(options: instanceOptions)
