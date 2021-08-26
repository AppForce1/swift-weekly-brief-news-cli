import ProjectDescription
import ProjectDescriptionHelpers

let launchArguments = [
    "current": true,
    "load": false,
    "show": false,
    "send": false,
    "--prod": false
]

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
                               dependencies: [.target(name: "CommandLineToolKit")],
                               launchArguments: launchArguments),
                        Target(name: "CommandLineToolKit",
                               platform: .macOS,
                               product: .staticLibrary,
                               bundleId: "net.appforce1.swiftweeklybrief.cli.kit",
                               infoPlist: .default,
                               sources: ["KitSources/**"],
                               dependencies: [.package(product: "ArgumentParser"), .package(product: "RSParser")])
])
