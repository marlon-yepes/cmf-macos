// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "NothingProtocol",
    products: [
        .library(name: "NothingProtocol", targets: ["NothingProtocol"]),
    ],
    targets: [
        // The codec: pure Foundation, no app frameworks.
        .target(name: "NothingProtocol"),
        // Golden vectors + runChecks() — the single source of test cases.
        .target(name: "NothingProtocolTestKit", dependencies: ["NothingProtocol"]),
        // Local + toolchain-agnostic runner: `swift run nothing-protocol-verify`.
        .executableTarget(name: "nothing-protocol-verify", dependencies: ["NothingProtocolTestKit"]),
        // Idiomatic runner for Xcode / `swift test` on CI.
        .testTarget(name: "NothingProtocolTests", dependencies: ["NothingProtocolTestKit"]),
    ]
)
