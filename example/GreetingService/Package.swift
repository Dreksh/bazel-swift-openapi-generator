// swift-tools-version: 5.9
import PackageDescription


let package = Package(
    name: "GreetingService",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", exact: "1.0.0-alpha.1"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", exact: "1.0.0-alpha.1"),
        .package(url: "https://github.com/swift-server/swift-openapi-vapor", exact: "1.0.0-alpha.1"),
        .package(url: "https://github.com/vapor/vapor", from: "4.84.0"),
    ],
    targets: [
        .executableTarget(
            name: "GreetingService",
            dependencies: [
                .product(
                    name: "OpenAPIRuntime",
                    package: "swift-openapi-runtime"
                ),
                .product(
                    name: "OpenAPIVapor",
                    package: "swift-openapi-vapor"
                ),
                .product(
                    name: "Vapor",
                    package: "vapor"
                ),
            ],
            path: "Sources",
            plugins: [
                .plugin(
                    name: "OpenAPIGenerator",
                    package: "swift-openapi-generator"
                )
            ]
        )
    ]
)
