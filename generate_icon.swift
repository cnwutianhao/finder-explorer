import Cocoa
import Foundation

/// 用代码生成 App 图标 — 蓝紫渐变 + 文件夹 + 放大镜
func generateAppIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let ctx = NSGraphicsContext.current!.cgContext

    // 圆角矩形背景
    let cornerRadius = size * 0.225
    let roundedPath = CGPath(roundedRect: rect,
                             cornerWidth: cornerRadius,
                             cornerHeight: cornerRadius,
                             transform: nil)
    ctx.addPath(roundedPath)
    ctx.clip()

    // 渐变背景：蓝紫色
    let colors = [
        CGColor(red: 0.25, green: 0.40, blue: 0.90, alpha: 1.0),
        CGColor(red: 0.55, green: 0.30, blue: 0.85, alpha: 1.0)
    ]
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                               colors: colors as CFArray,
                               locations: [0.0, 1.0])!
    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: 0, y: size),
                           end: CGPoint(x: size, y: 0),
                           options: [])

    // 文件夹图标 — 用 SF Symbol
    let symbolSize = size * 0.55
    let yOffset = size * 0.02

    // 文件夹本体
    if let folderSymbol = NSImage(systemSymbolName: "folder.fill",
                                   accessibilityDescription: nil) {
        let config = NSImage.SymbolConfiguration(pointSize: symbolSize, weight: .medium)
        if let configured = folderSymbol.withSymbolConfiguration(config) {
            let symbolRect = CGRect(x: (size - symbolSize) / 2,
                                     y: (size - symbolSize) / 2 + yOffset - symbolSize * 0.05,
                                     width: symbolSize,
                                     height: symbolSize)
            configured.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 0.95)
        }
    }

    // 放大镜覆盖层
    if let magnifier = NSImage(systemSymbolName: "magnifyingglass.circle.fill",
                                accessibilityDescription: nil) {
        let magSize = size * 0.30
        let config = NSImage.SymbolConfiguration(pointSize: magSize, weight: .bold)
        if let configured = magnifier.withSymbolConfiguration(config) {
            let magRect = CGRect(x: size * 0.09, y: size * 0.03, width: magSize, height: magSize)
            configured.draw(in: magRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
    }

    image.unlockFocus()
    return image
}

// 生成各种尺寸
let sizes: [(CGFloat, String)] = [
    (16, "icon_16x16"), (32, "icon_16x16@2x"),
    (32, "icon_32x32"), (64, "icon_32x32@2x"),
    (128, "icon_128x128"), (256, "icon_128x128@2x"),
    (256, "icon_256x256"), (512, "icon_256x256@2x"),
    (512, "icon_512x512"), (1024, "icon_512x512@2x"),
]

let outputDir = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

for (size, name) in sizes {
    let icon = generateAppIcon(size: size)
    let data = icon.tiffRepresentation!
    let rep = NSBitmapImageRep(data: data)!
    let pngData = rep.representation(using: .png, properties: [:])!
    let fileURL = outputDir.appendingPathComponent("\(name).png")
    try! pngData.write(to: fileURL)
    print("Generated \(name).png (\(Int(size))x\(Int(size)))")
}

print("Done! All icons generated.")
