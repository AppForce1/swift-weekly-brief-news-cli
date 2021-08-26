//
//  Newsletter+Defaults.swift
//  Swift Weekly Brief
//
//  Created by Jeroen Leenarts on 22/03/2021.
//

import Foundation

enum DefaultsError: Error {
    case defaultsSuiteMissing
    case malformedUrl
    case missingValue
}

extension UserDefaults {
    private enum DefaultsKey: String {
        case rssFeed
        case contentUrl
        case apiCampaignUrl
    }
    
    var rssFeed: String? {
        get {
            string(forKey: DefaultsKey.rssFeed.rawValue)
        }
        set {
            set(newValue, forKey: DefaultsKey.rssFeed.rawValue)
        }
    }
    
    var contentUrl: String? {
        get {
            string(forKey: DefaultsKey.contentUrl.rawValue)
        }
        set {
            set(newValue, forKey: DefaultsKey.contentUrl.rawValue)
        }
    }
    
    var apiCampaignUrl: String? {
        get {
            string(forKey: DefaultsKey.apiCampaignUrl.rawValue)
        }
        set {
            set(newValue, forKey: DefaultsKey.apiCampaignUrl.rawValue)
        }
    }    
}
