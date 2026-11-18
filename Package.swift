// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "XYZSheetView",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "XYZSheetView", targets: ["XYZSheetView"])
    ],
    targets: [
        .target(
            name: "XYZSheetView",
            path: "XYZSheetView/Classes",
            publicHeadersPath: "."
        )
    ]
)
