# CLI for sending newsletters

This is a CLI tool I created for personal use. I published it on Github for fun, because I am a fan of a few tools and practices used in this tool.

Please note, the project structure is defined using [Tuist](https://tuist.io). Please install that tool first and run `tuist generate` to generate the Xcode project structure.
Of interest:

- [RSParser](https://github.com/apple/swift-argument-parser) a supporting lib of [NetNewsWire](https://netnewswire.com/) to parse RSS feeds.
- [Swift Argument Parser](https://github.com/apple/swift-argument-parser)
- Calling out to the network with URLSession and keep the active as long as needed, but not any longer by using a RunLoop, DispatchGroups and proper exit calls.
- Securely storing secrets in the [Keychain](Sources/SwiftKeyChainStore.swift).
- Storing other config items in user [defaults](Sources/Newsletter%2BDefaults.swift).

## What this tools actually helps me with

It fetched a bit of HTML from the internet, which happens to be output exactly the way it needs to be for the newsletter. The page content is then pushed to my [Sendy](https://sendy.co/) install on a specific list which "happens" to contain the subscribers for [Swift Weekly Brief](https://swiftweeklybrief.com/).

Easy mode newsletter sending. 🤩

## The tool can be used in two ways.

- Direct to Sendy. This requires these options to be set with the `config` command.
  - `sendyApi`
  - `rssFeed`
  - `contentUrl`
  - `apiCampaignUrl`
  - `productionListId`
  - `testListId`

- Through an undisclosed bounce page I created that just adds the `sendyApi, `productionListId` and `testListId`. This requires these options to the config command:
  - `rssFeed`
  - `contentUrl`
  - `apiCampaignUrl`
  - `secret`
