import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(name: "SwiftWeeklyBriefNewsCli",
                      packages: [.package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "0.4.0")),
                                 .package(url: "https://github.com/Ranchero-Software/RSParser", .upToNextMajor(from: "2.0.0"))],
                      targets: [
                        Target(name: "CommandLineTool",
                               platform: .macOS,
                               product: .commandLineTool,
                               bundleId: "net.appforce1.swiftweeklybrief.cli",
                               infoPlist: .default,
                               sources: ["Sources/**"],
                               dependencies: [.package(product: "ArgumentParser"), .package(product: "RSParser")])
])
