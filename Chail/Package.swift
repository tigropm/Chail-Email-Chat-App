// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Chail",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "Chail", targets: ["Chail"])
    ],
    dependencies: [
        // MailCore2 via SPM-Wrapper (offizieller Fork mit SPM-Support)
        // Aktivieren sobald das Xcode-Projekt aufgesetzt ist:
        // .package(url: "https://github.com/readdle/mailcore2-feedparser", from: "0.6.0"),
    ],
    targets: [
        .target(
            name: "Chail",
            path: ".",
            exclude: ["Package.swift"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
