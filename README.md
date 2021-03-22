# CLI for sending newsletters

This is a CLI tool I created for personal use. I published it on Github for fun, because I am a fan of a few tools and practices used in this tool.

Of interest:

- [RSParser](https://github.com/apple/swift-argument-parser) a supporting lib of [NetNewsWire](https://netnewswire.com/) to parse RSS feeds.
- [Swift Argument Parser](https://github.com/apple/swift-argument-parser)
- Calling out to the network with URLSession and keep the active as long as needed, but not any longer by using a RunLoop, DispatchGroups and proper exit calls.
- Securely storing secrets in the [Keychain](Sources/SwiftKeyChainStore.swift).
- Storing other config items in user [defaults](Sources/Newsletter%2BDefaults.swift).

## What this tools actually helps me with

It fetched a bit of HTML from the internet, which happens to be output exactly the way it needs to be for the newsletter. The page content is then pushed to my [Sendy](https://sendy.co/) install on a specific list which "happens" to contain the subscribers for [Swift Weekly Brief](https://swiftweeklybrief.com/).

Easy mode newsletter sending. 🤩

