//
//  CampaignPublisher.swift
//  Swift Weekly Brief
//
//  Created by Jeroen Leenarts on 03/03/2021.
//

import Foundation
import RSParser

protocol URLQueryParameterStringConvertible {
    var queryParameters: String {get}
}

enum CampaignPublisherError: Error {
    case noItem
    case noNewsletterContent
    case missingData
    case missingPublishResult
}

struct CampaignCreateBody: URLQueryParameterStringConvertible {
    
    let api_key: String?
    let from_name = "Swift Weekly Brief"
    let from_email = "hello@swiftweeklybrief.com"
    let reply_to = "hello@swiftweeklybrief.com"
    let title: String
    let subject: String
    let html_text: String
    let brand_id = "5"
    let query_string: String
    let send_campaign = "1"
    let forReal: Bool
    let secret: String?
    let productionListId: String?
    let testListId: String?
    
    private var dictionary: [String: String] {
        var result = [
            "from_name": from_name,
            "from_email": from_email,
            "reply_to": reply_to,
            "title": forReal ? title : "Test: \(title)",
            "subject": subject,
            "html_text": html_text,
            "brand_id": brand_id,
            "query_string": query_string,
            "send_campaign": send_campaign,
            "for_real": (forReal ? "1": "0")
        ]
        
        if let secret = secret {
            result["secret"] = secret
        }
        
        if let api_key = api_key {
            result["api_key"] = api_key
        }
        if forReal {
            if let productionListId = productionListId {
                result["list_ids"] = productionListId
            }
        } else {
            if let testListId = testListId {
                result["list_ids"] = testListId
            }
        }
        
        return result
    }

    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in dictionary {
            let part = String(format: "%@=%@",
                              String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!,
                String(describing: value).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)
            parts.append(part as String)
        }
        return parts.joined(separator: "&")
    }
}

class CampaignPublisher {
            
    func publish(sendyApi: String?, apiCampaignUrl: URL, item: ParsedItem?, newsletterContent: String?, forReal: Bool, secret: String?, productionListId: String?, testListId: String?, completion: @escaping (Result<String, Error>) -> Void) {
        guard let item = item else {
            completion(.failure(CampaignPublisherError.noItem))
            return
        }
        guard let newsletterContent = newsletterContent else {
            completion(.failure(CampaignPublisherError.noNewsletterContent))
            return
        }
        let createBody = prepareContent(sendyApi: sendyApi, item: item, newsletterContent: newsletterContent, forReal: forReal, secret: secret, productionListId: productionListId, testListId: testListId)
        var request = URLRequest(url: apiCampaignUrl)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = createBody.queryParameters.data(using: .utf8, allowLossyConversion: true)
//        return

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data, let apiResult = String(data: data, encoding: .utf8) {
                completion(.success(apiResult))
            } else {
                completion(.failure(CampaignPublisherError.missingPublishResult))
            }
            
            
        }
        task.resume()
    }
    
    private func prepareContent(sendyApi: String?, item: ParsedItem, newsletterContent: String, forReal: Bool, secret: String?, productionListId: String?, testListId: String?) -> CampaignCreateBody {
        guard let title = item.title else {
            fatalError("Missing data")
        }
        
        var campaignString = title.replacingOccurrences(of: " ", with: "_")
        campaignString = campaignString.replacingOccurrences(of: "#", with: "")
        let queryString = "utm_source=Swift_Weekly_Brief&utm_medium=email&utm_campaign=\(campaignString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? "")"
        
        return CampaignCreateBody(api_key: sendyApi, title: title, subject: "Swift Weekly Brief: \(title)", html_text: newsletterContent, query_string: queryString, forReal: forReal, secret: secret, productionListId: productionListId, testListId: testListId)
    }
}
