//
//  RSSLoader.swift
//  Sendy Helper
//
//  Created by Jeroen Leenarts on 03/03/2021.
//

import Foundation
import RSParser

enum NewsletterLoaderError: Error {
    case missingData
    case missingResponse
    case parseFailed
    case noItems
    case templateContentConversion
}

class NewsletterLoader {
    func loadNewsletterContent(contentUrl: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: contentUrl) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NewsletterLoaderError.missingData))
                return
            }
            guard let _ = response else {
                completion(.failure(NewsletterLoaderError.missingResponse))
                return
            }
            guard let newsLetterContent = String(data: data, encoding: .utf8) else {
                completion(.failure(NewsletterLoaderError.templateContentConversion))
                return
            }
            
            completion(.success(newsLetterContent))
        }
        task.resume()
    }
    func loadRss(rssUrl: URL, completion: @escaping (Result<ParsedItem, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: rssUrl) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NewsletterLoaderError.missingData))
                return
            }
            guard let _ = response else {
                completion(.failure(NewsletterLoaderError.missingResponse))
                return
            }
            let parserData = ParserData(url: rssUrl.absoluteString, data: data)
            
            let parsedFeed: ParsedFeed?
            do {
                parsedFeed = try FeedParser.parse(parserData)
            } catch {
                parsedFeed = nil
                completion(.failure(error))
            }
            guard let items = parsedFeed?.items else {
                completion(.failure(NewsletterLoaderError.noItems))
                return
            }
            
            let sorted = items.sorted { lhs, rhs -> Bool in
                guard let lhsDate = lhs.datePublished else { return false }
                guard let rhsDate = rhs.datePublished else { return true }
                return lhsDate < rhsDate
            }
            
            if let lastItem = sorted.last {
                completion(.success(lastItem))
            } else {
                completion(.failure(NewsletterLoaderError.parseFailed))
            }
        }
        task.resume()
    }
}
