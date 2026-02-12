// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RecipeApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "RecipeApp",
            targets: ["RecipeApp"]
        ),
    ],
    targets: [
        .target(
            name: "RecipeApp",
            exclude: ["RecipeApp.swift"]
        ),
        .testTarget(
            name: "RecipeAppTests",
            dependencies: ["RecipeApp"]
        ),
    ]
)
