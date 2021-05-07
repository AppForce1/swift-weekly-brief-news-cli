import ArgumentParser
import RSParser

let standardOutput: FileHandle = .standardOutput

let keychain = SwiftKeyChainStore(service: "net.appforce1.swiftweeklybrief")

struct Newsletter: ParsableCommand {
    static let configuration = CommandConfiguration(
            abstract: "A Swift command-line tool to manage a newsletter",
        subcommands: [Current.self, Config.self])
}

struct Config: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Configure.")
    
    @Option(help: "The Sendy API key.")
    var sendyApi: String?
    
    @Option(help: "The URL of the rss feed to filter from.")
    var rssFeed: String
    
    @Option(help: "The URL of the pre-rendered newsletter content.")
    var contentUrl: String
    
    @Option(help: "The create URL of the sendy instance.")
    var apiCampaignUrl: String
    
    @Option(help: "Production list ID. Only required when using a Sendy API Key.")
    var productionListId: String?

    @Option(help: "Test list ID. Only required when using a Sendy API Key.")
    var testListId: String?
    
    @Option(help: "Secret for when using the in-between script. When used, sendyApi, productionListId and testListId are NOT used.")
    var secret: String

    
    func run() throws {
        guard let defaults = UserDefaults(suiteName: "net.appforce1.sendy.cli") else {
            Config.exit(withError: DefaultsError.defaultsSuiteMissing)
        }

        try keychain.setSecret(secret)

        if let sendyApi = sendyApi {
            try keychain.setSendyApi(sendyApi)
        }
        
        if let productionListId = productionListId{
            try keychain.setProductionListId(productionListId)
        }
        
        if let testListId = testListId {
            try keychain.setTestListId(testListId)
        }
        
        defaults.rssFeed = rssFeed
        defaults.contentUrl = contentUrl
        defaults.apiCampaignUrl = apiCampaignUrl
        
        print("Config stored.")
        Config.exit()
    }
}

struct Current: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Do things with the current latest newsletter", subcommands: [Show.self, Send.self, Load.self])
}

struct Show: ParsableCommand {
    public static let configuration = CommandConfiguration(abstract: "Show unique ID of current content that would be sent with the \"send\" command")
    
    func run() throws {
        guard let defaults = UserDefaults(suiteName: "net.appforce1.sendy.cli") else {
            Config.exit(withError: DefaultsError.defaultsSuiteMissing)
        }

        guard let rssFeed = defaults.rssFeed, let rssUrl = URL(string: rssFeed) else {
            Show.exit(withError: DefaultsError.malformedUrl)
        }
        let loader = NewsletterLoader()
        loader.loadRss(rssUrl: rssUrl) { result in
            switch result {
            case .success(let item):
                print(item.uniqueID)
                Show.exit()
            case .failure(let error):
                print(error.localizedDescription)
            }
        }

    }
}

struct Load: ParsableCommand {
    public static let configuration = CommandConfiguration(abstract: "Load current content that would be sent with the \"send\" command")
    
    func run() throws {
        guard let defaults = UserDefaults(suiteName: "net.appforce1.sendy.cli") else {
            Config.exit(withError: DefaultsError.defaultsSuiteMissing)
        }

        guard let contentUrlString = defaults.contentUrl, let contentUrl = URL(string: contentUrlString) else {
            Show.exit(withError: DefaultsError.malformedUrl)
        }
        let loader = NewsletterLoader()
        loader.loadNewsletterContent(contentUrl: contentUrl) { result in
            switch result {
            case .success(let item):
                if let data = item.data(using: .utf8) {
                    standardOutput.write(data)
                }
                Load.exit()
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

struct Send: ParsableCommand {

    public static let configuration = CommandConfiguration(abstract: "Send a newsletter")
    
    @Flag(help: "Pass to perform a production run.")
    var prod: Bool = false

    func run() throws {
        guard let defaults = UserDefaults(suiteName: "net.appforce1.sendy.cli") else {
            Config.exit(withError: DefaultsError.defaultsSuiteMissing)
        }

        guard let rssFeed = defaults.rssFeed, let rssUrl = URL(string: rssFeed) else {
            Show.exit(withError: DefaultsError.malformedUrl)
        }
        
        guard let contentUrlString = defaults.contentUrl, let contentUrl = URL(string: contentUrlString) else {
            Show.exit(withError: DefaultsError.malformedUrl)
        }
        
        let sendyApi = try keychain.sendyApi()
        
        guard let apiCampaignUrlString = defaults.apiCampaignUrl, let apiCampaignUrl = URL(string: apiCampaignUrlString) else {
            Show.exit(withError: DefaultsError.malformedUrl)
        }
        
        
        let productionListId = try keychain.productionListId()
        
        let testListId = try keychain.testListId()
        
        let secret = try keychain.secret()

        var newsletterContent: String? = nil
        var loadedItem: ParsedItem?
        
        let group = DispatchGroup()
        
        let loader = NewsletterLoader()
        group.enter()
        loader.loadNewsletterContent(contentUrl: contentUrl) { result in
            switch result {
            case .success(let content):
                newsletterContent = content
            case .failure(let error):
                Send.exit(withError: error)
            }
            group.leave()
        }
        
        group.enter()
        loader.loadRss(rssUrl: rssUrl) { result in
            switch result {
            case .success(let item):
                loadedItem = item
            case .failure(let error):
                Send.exit(withError: error)
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            CampaignPublisher().publish(sendyApi: sendyApi, apiCampaignUrl: apiCampaignUrl, item: loadedItem, newsletterContent: newsletterContent, forReal: prod, secret: secret, productionListId: productionListId, testListId: testListId) { result in
                switch result {
                case .success(let result):
                    print(result)
                    Send.exit()
                case .failure(let error):
                    Send.exit(withError: error)
                }
            }
        }
    }
}

Newsletter.main()
RunLoop.current.run()
