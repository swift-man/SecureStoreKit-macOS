// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "SecureStoreKit",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "SecureStoreKit", targets: ["SecureStoreKit"]),
    .library(name: "SecureStoreTesting", targets: ["SecureStoreTesting"]),
  ],
  targets: [
    .target(
      name: "SecureStoreKit",
      linkerSettings: [
        .linkedFramework("Security"),
        .linkedFramework("LocalAuthentication"),
      ]
    ),
    .target(
      name: "SecureStoreTesting",
      dependencies: ["SecureStoreKit"]
    ),
    .testTarget(
      name: "SecureStoreKitTests",
      dependencies: ["SecureStoreKit", "SecureStoreTesting"]
    ),
  ]
)
