//
//  UIImage+Extensions.swift
//  untitled
//
//  Created by Mike Choi on 10/12/22.
//

import UIKit

extension UIImage {
    func fixOrientation() -> UIImage {
        if (imageOrientation == .up) {
            return self
        }

        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        self.draw(in: rect)

        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return normalizedImage
    }
}

extension UIColor: Identifiable {
    public var id: String {
        self.description
    }
}

extension UIImage {
    func imageResized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

extension UIImage {
    /// There are two main ways to get the color from an image, just a simple "sum up an average" or by squaring their sums. Each has their advantages, but the 'simple' option *seems* better for average color of entire image and closely mirrors CoreImage. Details: https://sighack.com/post/averaging-rgb-colors-the-right-way
    enum AverageColorAlgorithm {
        case simple
        case squareRoot
    }
    
    func isMostlyTransparent() -> Bool {
        guard let cgImage = cgImage else { return false }
        
        // First, resize the image. We do this for two reasons, 1) less pixels to deal with means faster calculation and a resized image still has the "gist" of the colors, and 2) the image we're dealing with may come in any of a variety of color formats (CMYK, ARGB, RGBA, etc.) which complicates things, and redrawing it normalizes that into a base color format we can deal with.
        // 40x40 is a good size to resize to still preserve quite a bit of detail but not have too many pixels to deal with. Aspect ratio is irrelevant for just finding average color.
        let size = CGSize(width: 40, height: 40)
        
        let width = Int(size.width)
        let height = Int(size.height)
        let totalPixels = width * height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // ARGB format
        let bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        
        // 8 bits for each color channel, we're doing ARGB so 32 bits (4 bytes) total, and thus if the image is n pixels wide, and has 4 bytes per pixel, the total bytes per row is 4n. That gives us 2^8 = 256 color variations for each RGB channel or 256 * 256 * 256 = ~16.7M color options in total. That seems like a lot, but lots of HDR movies are in 10 bit, which is (2^10)^3 = 1 billion color options!
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: bitmapInfo) else { return false }

        // Draw our resized image
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        guard let pixelBuffer = context.data else { return false }
        
        // Bind the pixel buffer's memory location to a pointer we can use/access
        let pointer = pixelBuffer.bindMemory(to: UInt32.self, capacity: width * height)

        // Keep track of total colors (note: we don't care about alpha and will always assume alpha of 1, AKA opaque)
        var totalAlpha = 0
        
        // Column of pixels in image
        for x in 0 ..< width {
            // Row of pixels in image
            for y in 0 ..< height {
                // To get the pixel location just think of the image as a grid of pixels, but stored as one long row rather than columns and rows, so for instance to map the pixel from the grid in the 15th row and 3 columns in to our "long row", we'd offset ourselves 15 times the width in pixels of the image, and then offset by the amount of columns
                let pixel = pointer[(y * width) + x]
                let a = UInt8(pixel >> 24)
                if a != 255 {
                    totalAlpha += 1
                }
            }
        }
        
        let averageTransparent = CGFloat(totalAlpha) / CGFloat(totalPixels)
        return averageTransparent > 0.8
    }
    
    private func red(for pixelData: UInt32) -> UInt8 {
        // For a quick primer on bit shifting and what we're doing here, in our ARGB color format image each pixel's colors are stored as a 32 bit integer, with 8 bits per color chanel (A, R, G, and B).
        //
        // So a pure red color would look like this in bits in our format, all red, no blue, no green, and 'who cares' alpha:
        //
        // 11111111 11111111 00000000 00000000
        //  ^alpha   ^red     ^blue    ^green
        //
        // We want to grab only the red channel in this case, we don't care about alpha, blue, or green. So we want to shift the red bits all the way to the right in order to have them in the right position (we're storing colors as 8 bits, so we need the right most 8 bits to be the red). Red is 16 points from the right, so we shift it by 16 (for the other colors, we shift less, as shown below).
        //
        // Just shifting would give us:
        //
        // 00000000 00000000 11111111 11111111
        //  ^alpha   ^red     ^blue    ^green
        //
        // The alpha got pulled over which we don't want or care about, so we need to get rid of it. We can do that with the bitwise AND operator (&) which compares bits and the only keeps a 1 if both bits being compared are 1s. So we're basically using it as a gate to only let the bits we want through. 255 (below) is the value we're using as in binary it's 11111111 (or in 32 bit, it's 00000000 00000000 00000000 11111111) and the result of the bitwise operation is then:
        //
        // 00000000 00000000 11111111 11111111
        // 00000000 00000000 00000000 11111111
        // -----------------------------------
        // 00000000 00000000 00000000 11111111
        //
        // So as you can see, it only keeps the last 8 bits and 0s out the rest, which is what we want! Woohoo! (It isn't too exciting in this scenario, but if it wasn't pure red and was instead a red of value "11010010" for instance, it would also mirror that down)
        return UInt8((pixelData >> 16) & 255)
    }

    private func green(for pixelData: UInt32) -> UInt8 {
        return UInt8((pixelData >> 8) & 255)
    }

    private func blue(for pixelData: UInt32) -> UInt8 {
        return UInt8((pixelData >> 0) & 255)
    }
}

extension UIImage {

    /// Crops the insets of transparency around the image.
    ///
    /// - Parameters:
    ///   - maximumAlphaChannel: The maximum alpha channel value to consider  _transparent_ and thus crop. Any alpha value
    ///         strictly greater than `maximumAlphaChannel` will be considered opaque.
    func trimmingTransparentPixels(maximumAlphaChannel: UInt8 = 0) async -> UIImage? {
        guard size.height > 1 && size.width > 1
            else { return self }

        guard let cgImage = await cgImage?.trimmingTransparentPixels(maximumAlphaChannel: maximumAlphaChannel)
            else { return nil }

        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
    
    func cropRect(maximumAlphaChannel: UInt8 = 0) async -> CGRect? {
        guard size.height > 1 && size.width > 1
            else { return nil }

        guard let rect = await cgImage?.cropRect(maximumAlphaChannel: maximumAlphaChannel)
            else { return nil }

        return CGRect(x: rect.minX / scale, y: rect.minY / scale, width: rect.width / scale, height: rect.height / scale)
    }
}

extension CGImage {

    /// Crops the insets of transparency around the image.
    ///
    /// - Parameters:
    ///   - maximumAlphaChannel: The maximum alpha channel value to consider  _transparent_ and thus crop. Any alpha value
    ///         strictly greater than `maximumAlphaChannel` will be considered opaque.
    func trimmingTransparentPixels(maximumAlphaChannel: UInt8 = 0) async -> CGImage? {
        await _CGImageTransparencyTrimmer(image: self, maximumAlphaChannel: maximumAlphaChannel)?.trim()
    }

    func cropRect(maximumAlphaChannel: UInt8 = 0) async -> CGRect? {
        await _CGImageTransparencyTrimmer(image: self, maximumAlphaChannel: maximumAlphaChannel)?.cropRect()
    }
}

private struct _CGImageTransparencyTrimmer {

    let image: CGImage
    let maximumAlphaChannel: UInt8
    let cgContext: CGContext
    let zeroByteBlock: UnsafeMutableRawPointer
    let pixelRowRange: Range<Int>
    let pixelColumnRange: Range<Int>

    init?(image: CGImage, maximumAlphaChannel: UInt8) {
        guard let cgContext = CGContext(data: nil,
                                        width: image.width,
                                        height: image.height,
                                        bitsPerComponent: 8,
                                        bytesPerRow: 0,
                                        space: CGColorSpaceCreateDeviceGray(),
                                        bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue),
            cgContext.data != nil
            else { return nil }

        cgContext.draw(image,
                       in: CGRect(origin: .zero,
                                  size: CGSize(width: image.width,
                                               height: image.height)))

        guard let zeroByteBlock = calloc(image.width, MemoryLayout<UInt8>.size)
            else { return nil }

        self.image = image
        self.maximumAlphaChannel = maximumAlphaChannel
        self.cgContext = cgContext
        self.zeroByteBlock = zeroByteBlock

        pixelRowRange = 0..<image.height
        pixelColumnRange = 0..<image.width
    }
    
    func cropRect() async -> CGRect? {
        async let topInset = firstOpaquePixelRow(in: pixelRowRange)
        async let bottomOpaqueRow = firstOpaquePixelRow(in: pixelRowRange.reversed())
        async let leftInset = firstOpaquePixelColumn(in: pixelColumnRange)
        async let rightOpaqueColumn = firstOpaquePixelColumn(in: pixelColumnRange.reversed())
        
        guard let topInset = await topInset,
              let bottomOpaqueRow = await bottomOpaqueRow,
              let leftInset = await leftInset,
              let rightOpaqueColumn = await rightOpaqueColumn else {
            return nil
        }
        
        let bottomInset = (image.height - 1) - bottomOpaqueRow
        let rightInset = (image.width - 1) - rightOpaqueColumn

        guard !(topInset == 0 && bottomInset == 0 && leftInset == 0 && rightInset == 0)
            else { return nil }

        return CGRect(origin: CGPoint(x: leftInset, y: topInset),
                      size: CGSize(width: image.width - (leftInset + rightInset),
                                   height: image.height - (topInset + bottomInset)))
    }

    func trim() async -> CGImage? {
        guard let cropRect = await cropRect() else {
            return image
        }
        
        return image.cropping(to: cropRect)
    }

    @inlinable
    func isPixelOpaque(column: Int, row: Int) -> Bool {
        // Sanity check: It is safe to get the data pointer in iOS 4.0+ and macOS 10.6+ only.
        assert(cgContext.data != nil)
        return cgContext.data!.load(fromByteOffset: (row * cgContext.bytesPerRow) + column, as: UInt8.self)
            > maximumAlphaChannel
    }

    @inlinable
    func isPixelRowTransparent(_ row: Int) -> Bool {
        assert(cgContext.data != nil)
        // `memcmp` will efficiently check if the entire pixel row has zero alpha values
        return memcmp(cgContext.data! + (row * cgContext.bytesPerRow), zeroByteBlock, image.width) == 0
            // When the entire row is NOT zeroed, we proceed to check each pixel's alpha
            // value individually until we locate the first "opaque" pixel (very ~not~ efficient).
            || !pixelColumnRange.contains(where: { isPixelOpaque(column: $0, row: row) })
    }

    @inlinable
    func firstOpaquePixelRow<T: Sequence>(in rowRange: T) async -> Int? where T.Element == Int {
        return rowRange.first(where: { !isPixelRowTransparent($0) })
    }

    @inlinable
    func firstOpaquePixelColumn<T: Sequence>(in columnRange: T) async -> Int? where T.Element == Int {
        return columnRange.first(where: { column in
            pixelRowRange.contains(where: { isPixelOpaque(column: column, row: $0) })
        })
    }
}
