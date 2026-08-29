// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "FakeSecureCardDisplay",
  platforms: [.iOS(.v14)],
  products: [
    .library(name: "FakeSecureCardDisplay", targets: ["FakeSecureCardDisplay"])
  ],
  targets: [
    .target(name: "FakeSecureCardDisplay")
  ]
)
