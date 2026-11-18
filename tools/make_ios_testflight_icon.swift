import AppKit
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 3 else {
    fputs("usage: make_ios_testflight_icon.swift INPUT OUTPUT\n", stderr)
    exit(2)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
guard
    let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
    let ship = CGImageSourceCreateImageAtIndex(source, 0, nil)
else {
    fputs("cannot load input image\n", stderr)
    exit(3)
}

let side = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: side,
    height: side,
    bitsPerComponent: 8,
    bytesPerRow: side * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    fputs("cannot create graphics context\n", stderr)
    exit(4)
}

let colors = [
    CGColor(red: 0.005, green: 0.012, blue: 0.055, alpha: 1.0),
    CGColor(red: 0.018, green: 0.105, blue: 0.245, alpha: 1.0),
    CGColor(red: 0.002, green: 0.010, blue: 0.040, alpha: 1.0)
] as CFArray
let locations: [CGFloat] = [0.0, 0.54, 1.0]
let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations)!
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 512, y: 0),
    end: CGPoint(x: 512, y: 1024),
    options: []
)

context.setFillColor(CGColor(red: 0.0, green: 0.55, blue: 1.0, alpha: 0.16))
context.fillEllipse(in: CGRect(x: 122, y: 104, width: 780, height: 780))
context.draw(ship, in: CGRect(x: 92, y: 84, width: 840, height: 840))

guard let result = context.makeImage() else {
    fputs("cannot render image\n", stderr)
    exit(5)
}
guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
) else {
    fputs("cannot create output image\n", stderr)
    exit(6)
}
CGImageDestinationAddImage(destination, result, nil)
guard CGImageDestinationFinalize(destination) else {
    fputs("cannot encode png\n", stderr)
    exit(7)
}
