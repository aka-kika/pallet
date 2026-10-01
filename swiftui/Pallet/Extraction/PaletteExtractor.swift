import CoreGraphics
import Foundation
import ImageIO
import Vision

/// The colors pulled out of a dropped image, plus a title when the image has one.
nonisolated struct ExtractionResult: Sendable {
  var colors: [String]
  var name: String?
  var kind: Kind

  enum Kind: String, Sendable {
    /// A designed palette card: swatches on a page or over a photo.
    case paletteGraphic
    /// A website or app screenshot: flat UI regions, background and text included.
    case interface
    /// Anything else: dominant, distinct colors.
    case photo
  }
}

nonisolated enum PaletteExtractorError: LocalizedError {
  case unreadableImage
  case noColors

  var errorDescription: String? {
    switch self {
    case .unreadableImage: "This image could not be read."
    case .noColors: "No visible colors found."
    }
  }
}

/// Finds the palette a person meant, not every color in the picture.
///
/// 1. Flat regions: connected areas of one color on a downscaled copy.
/// 2. Swatches are flat, rectangular regions that do not touch the image edge,
///    so page frames, photo backdrops and text strokes drop out.
/// 3. Text recognition reads printed hex codes (trusted when they match a swatch)
///    and a title, and tells us the text color for UI screenshots.
nonisolated enum PaletteExtractor {
  /// The first Vision text request loads its model, which can take many
  /// seconds. Call once at launch so the first dropped image is quick.
  static func warmUp() {
    guard let ctx = CGContext(data: nil, width: 64, height: 32, bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue),
          let image = ctx.makeImage() else { return }
    _ = TextReader.read(image)
  }

  static func extract(contentsOf url: URL) async throws -> ExtractionResult {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary)
    else { throw PaletteExtractorError.unreadableImage }
    return try await extract(from: image)
  }

  static func extract(from image: CGImage) async throws -> ExtractionResult {
    guard let bitmap = Bitmap(image, longSide: 480) else { throw PaletteExtractorError.unreadableImage }
    let regions = FlatRegions.find(in: bitmap)
    let text = TextReader.read(image)

    var swatches = consistent(regions.filter { $0.isSwatch(in: bitmap) })
    // Printed hex codes sitting on their own color mark a swatch even when the
    // swatch blends into its backdrop (a black card over a night photo).
    let anchors = text.hexAnchors(in: bitmap)
    let typical = swatches.map(\.count).sorted().dropFirst(swatches.count / 2).first ?? bitmap.area / 50
    for a in anchors where !swatches.contains(where: { $0.color.distance(to: a.color) <= 22 }) {
      swatches.append(Region(color: a.color, count: typical, box: a.box, touchesEdge: false))
    }
    let merged = mergeSwatches(swatches)
    // Lots of text off the swatches means a screenshot of an app or site that
    // happens to show some color blocks, not a palette card.
    let looseText = text.lines(offColors: merged.map(\.color), in: bitmap).count
    if (3...10).contains(merged.count) || (merged.count == 2 && anchors.count >= 2), looseText <= 7 || anchors.count >= 3 {
      var hexes = text.hexCodes
      if hexes.count < 2 {
        // Hex codes printed sideways (common on tall swatches) need a rotated pass.
        hexes += TextReader.read(image, orientation: .right).hexCodes
        hexes += TextReader.read(image, orientation: .left).hexCodes
      }
      // A printed code that matches the measured color is the designer's exact value.
      func printed(_ c: RGB) -> RGB? {
        hexes.min { c.distance(to: $0) < c.distance(to: $1) }.flatMap { c.distance(to: $0) <= 22 ? $0 : nil }
      }
      var kept = merged
      let marked = merged.filter { printed($0.color) != nil }
      if marked.count >= 3 {
        // Codes name the swatches, so an unmarked block must look like its
        // neighbors (same size and shape) to count; input fields and panels do not.
        let area = marked.map { $0.box.width * $0.box.height }.sorted()[marked.count / 2]
        let aspect = marked.map { $0.box.width / $0.box.height }.sorted()[marked.count / 2]
        kept = merged.filter { r in
          guard printed(r.color) == nil else { return true }
          let a = r.box.width * r.box.height / area, k = (r.box.width / r.box.height) / aspect
          return a > 0.6 && a < 1.6 && k > 0.7 && k < 1.4
        }
      }
      let colors = unique(kept.map { printed($0.color) ?? $0.color })
      let name = text.title(palette: colors, in: bitmap)
      return ExtractionResult(colors: colors.prefix(8).map(\.hex), name: name, kind: .paletteGraphic)
    }

    // UI fills are flat (spread well under 3 even with a faint noise or gradient);
    // skies and other smooth photo areas sit at 4 and above.
    let flatArea = regions.filter { $0.count >= bitmap.area / 500 && $0.spread < 3 }.reduce(0) { $0 + $1.count }
    if Double(flatArea) / Double(bitmap.area) > 0.5 {
      let colors = interfacePalette(regions: regions, text: text, bitmap: bitmap, image: image)
      if colors.count >= 2 {
        return ExtractionResult(colors: colors.map(\.hex), name: nil, kind: .interface)
      }
    }

    let colors = photoPalette(bitmap)
    guard !colors.isEmpty else { throw PaletteExtractorError.noColors }
    return ExtractionResult(colors: (colors.count == 1 ? colors + [colors[0].luminance > 0.5 ? RGB(17, 17, 17) : RGB(255, 255, 255)] : colors).map(\.hex), name: nil, kind: .photo)
  }

  // MARK: Palette graphics

  /// Drops stray small blobs: a swatch far smaller than the typical one only
  /// stays when it repeats a big swatch's color (the small row under Bay Bloom).
  private static func consistent(_ swatches: [Region]) -> [Region] {
    guard swatches.count >= 3 else { return swatches }
    let typical = swatches.map(\.count).sorted()[swatches.count / 2]
    let big = swatches.filter { $0.count * 4 >= typical }
    return swatches.filter { s in
      s.count * 4 >= typical || big.contains { $0.color.distance(to: s.color) < 14 }
    }
  }

  /// Collapses repeats (a big swatch and its small twin) and orders by reading position.
  private static func mergeSwatches(_ swatches: [Region]) -> [Region] {
    var kept: [Region] = []
    for s in swatches.sorted(by: { $0.count > $1.count }) where !kept.contains(where: { $0.color.distance(to: s.color) < 14 }) {
      kept.append(s)
    }
    // Rows: swatches whose vertical spans overlap by half share a row.
    let byTop = kept.sorted { $0.box.minY < $1.box.minY }
    var rows: [[Region]] = []
    for s in byTop {
      if let last = rows.last?.last,
         min(last.box.maxY, s.box.maxY) - max(last.box.minY, s.box.minY) > min(last.box.height, s.box.height) / 2 {
        rows[rows.count - 1].append(s)
      } else {
        rows.append([s])
      }
    }
    return rows.flatMap { $0.sorted { $0.box.minX < $1.box.minX } }
  }

  // MARK: Interface screenshots

  /// A design system read off a screenshot, in this order: background, surface,
  /// primary text, secondary text, then accents (buttons first). Decorative
  /// gradients and photos are left out because they are not flat.
  private static func interfacePalette(regions: [Region], text: TextReader.Result, bitmap: Bitmap, image: CGImage) -> [RGB] {
    let flat = regions.filter { $0.spread < 3 }

    // Surfaces: big flat neutral areas, grouped tightly so a panel a few steps
    // lighter than the page still counts as its own surface.
    var surfaces: [(color: RGB, weight: Int)] = []
    for r in flat.sorted(by: { $0.count > $1.count }) where r.color.chroma < 0.18 && r.count >= bitmap.area / 2000 {
      if let i = surfaces.firstIndex(where: { $0.color.distance(to: r.color) < 5 }) {
        surfaces[i].weight += r.count
      } else {
        surfaces.append((r.color, r.count))
      }
    }
    surfaces.sort { $0.weight > $1.weight }
    var colors: [RGB] = []
    func add(_ c: RGB, within limit: Int) {
      if colors.allSatisfy({ $0.distance(to: c) >= limit }) { colors.append(c) }
    }
    if let page = surfaces.first { colors.append(page.color) }
    for s in surfaces.dropFirst() where s.weight >= bitmap.area / 100 && colors.count < 3 {
      add(s.color, within: 4)
    }
    let surfaceColors = colors

    // Text: sampled at full size, where strokes are solid, not blended.
    let fine = Bitmap(image, longSide: 1600) ?? bitmap
    let samples = text.samples(in: fine)
    var inks: [(color: RGB, weight: Int)] = []
    for t in samples where t.background.chroma < 0.18 {
      if let i = inks.firstIndex(where: { $0.color.distance(to: t.ink) < 28 }) {
        inks[i].weight += t.chars
      } else {
        inks.append((t.ink, t.chars))
      }
    }
    // Primary text is the highest-contrast ink with real use (logos and one-off
    // labels are too rare to count); secondary is the most used of the rest.
    let page = colors.first ?? RGB(255, 255, 255)
    let heaviest = inks.map(\.weight).max() ?? 0
    let common = inks.filter { $0.weight * 7 >= heaviest && $0.color.chroma < 0.35 }
    if let primary = common.max(by: { abs($0.color.luminance - page.luminance) < abs($1.color.luminance - page.luminance) }) {
      add(primary.color, within: 20)
      if let secondary = common.filter({ $0.color.distance(to: primary.color) >= 28 }).max(by: { $0.weight < $1.weight }) {
        add(secondary.color, within: 20)
      }
    }

    // Accents must be flat: colored surfaces that carry text (buttons, badges)
    // first, then small flat blocks standing on the page, not inside artwork.
    let flatColored = flat.filter { $0.color.chroma >= 0.18 && $0.spread < 2.5 && $0.count >= max(12, bitmap.area / 3000) }
    var accents: [(color: RGB, weight: Int)] = []
    func addAccent(_ c: RGB, _ w: Int) {
      if let i = accents.firstIndex(where: { $0.color.distance(to: c) < 20 }) { accents[i].weight += w } else { accents.append((c, w)) }
    }
    for t in samples where t.background.chroma >= 0.18 && t.backgroundShare > 0.5
      && flatColored.contains(where: { $0.color.distance(to: t.background) < 12 }) {
      addAccent(t.background, bitmap.area)
    }
    for r in flatColored where Double(r.count) / Double(r.box.width * r.box.height) > 0.6
      && surroundedBy(surfaceColors, r.box, in: bitmap) {
      addAccent(r.color, r.count)
    }
    for a in accents.sorted(by: { $0.weight > $1.weight }) { add(a.color, within: 20) }
    return Array(colors.prefix(8))
  }

  /// True when most pixels on a ring just outside `box` are one of the surfaces:
  /// a button on the page, not a patch inside a gradient or photo.
  private static func surroundedBy(_ surfaces: [RGB], _ box: CGRect, in bitmap: Bitmap) -> Bool {
    let r = box.insetBy(dx: -2, dy: -2)
    let x0 = Int(r.minX), x1 = Int(r.maxX) - 1, y0 = Int(r.minY), y1 = Int(r.maxY) - 1
    var hits = 0, total = 0
    func check(_ x: Int, _ y: Int) {
      guard x >= 0, y >= 0, x < bitmap.width, y < bitmap.height else { return }
      total += 1
      if surfaces.contains(where: { $0.distance(to: bitmap[x, y]) < 14 }) { hits += 1 }
    }
    for x in x0...max(x0, x1) { check(x, y0); check(x, y1) }
    for y in y0...max(y0, y1) { check(x0, y); check(x1, y) }
    return total > 0 && hits * 10 >= total * 6
  }

  // MARK: Photos

  /// Popular colors with a boost for colorful ones, skipping near-duplicates.
  private static func photoPalette(_ bitmap: Bitmap) -> [RGB] {
    var bins: [Int: (sum: (Int, Int, Int), n: Int)] = [:]
    for i in stride(from: 0, to: bitmap.area, by: 1) {
      let c = bitmap[i]
      let key = (Int(c.r) / 24) << 16 | (Int(c.g) / 24) << 8 | Int(c.b) / 24
      var b = bins[key] ?? ((0, 0, 0), 0)
      b.sum.0 += Int(c.r); b.sum.1 += Int(c.g); b.sum.2 += Int(c.b); b.n += 1
      bins[key] = b
    }
    let ranked = bins.values
      .map { b -> (RGB, Double) in
        let c = RGB(b.sum.0 / b.n, b.sum.1 / b.n, b.sum.2 / b.n)
        return (c, Double(b.n) * (1 + 2 * c.chroma))
      }
      .sorted { $0.1 > $1.1 }
    var colors: [RGB] = []
    for (c, _) in ranked where colors.allSatisfy({ $0.distance(to: c) > 48 }) {
      colors.append(c)
      if colors.count == 6 { break }
    }
    return colors
  }

  private static func unique(_ colors: [RGB], within limit: Int = 10) -> [RGB] {
    var out: [RGB] = []
    for c in colors where !out.contains(where: { $0.distance(to: c) < limit }) { out.append(c) }
    return out
  }
}

// MARK: - Color

nonisolated struct RGB: Equatable, Sendable {
  var r: UInt8, g: UInt8, b: UInt8

  init(_ r: Int, _ g: Int, _ b: Int) {
    self.r = UInt8(clamping: r); self.g = UInt8(clamping: g); self.b = UInt8(clamping: b)
  }

  init?(hex: String) {
    let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    guard s.count == 6, let v = Int(s, radix: 16) else { return nil }
    self.init(v >> 16 & 255, v >> 8 & 255, v & 255)
  }

  var hex: String { String(format: "#%02X%02X%02X", r, g, b) }

  /// Largest per-channel difference: simple and strict enough for flat colors.
  func distance(to o: RGB) -> Int {
    max(abs(Int(r) - Int(o.r)), abs(Int(g) - Int(o.g)), abs(Int(b) - Int(o.b)))
  }

  var chroma: Double {
    Double(max(r, g, b) - min(r, g, b)) / 255
  }

  var luminance: Double {
    (0.2126 * Double(r) + 0.7152 * Double(g) + 0.0722 * Double(b)) / 255
  }
}

// MARK: - Bitmap

/// An sRGB, 8-bit copy of the image scaled so its long side is at most `longSide`.
nonisolated struct Bitmap {
  let width: Int, height: Int
  private let pixels: [UInt8]

  var area: Int { width * height }

  init?(_ image: CGImage, longSide: Int) {
    let scale = min(1, Double(longSide) / Double(max(image.width, image.height)))
    let width = max(1, Int((Double(image.width) * scale).rounded()))
    let height = max(1, Int((Double(image.height) * scale).rounded()))
    var data = [UInt8](repeating: 0, count: width * height * 4)
    let drawn = data.withUnsafeMutableBytes { buffer -> Bool in
      guard let ctx = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
      // Transparent areas read as white, like the image would on a page.
      ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
      ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
      ctx.interpolationQuality = .high
      ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
      return true
    }
    guard drawn else { return nil }
    self.width = width
    self.height = height
    pixels = data
  }

  subscript(i: Int) -> RGB {
    RGB(Int(pixels[i * 4]), Int(pixels[i * 4 + 1]), Int(pixels[i * 4 + 2]))
  }

  subscript(x: Int, y: Int) -> RGB { self[y * width + x] }
}

// MARK: - Flat regions

nonisolated struct Region {
  var color: RGB
  var count: Int
  var box: CGRect
  var touchesEdge: Bool
  /// Mean distance of its pixels from its color: near 0 for UI fills, higher
  /// for smooth photo areas like a sky gradient.
  var spread: Double = 0

  /// Big, rectangular, clear of the image edge, and not a thin line.
  func isSwatch(in bitmap: Bitmap) -> Bool {
    let fill = Double(count) / Double(box.width * box.height)
    let short = min(box.width, box.height)
    return !touchesEdge
      && count >= bitmap.area / 250
      && fill > 0.72
      && short >= Double(max(bitmap.width, bitmap.height)) / 48
  }
}

nonisolated enum FlatRegions {
  /// Connected components on color. A pixel joins when it is close to both the
  /// region's running mean and the neighbor it came from, so smooth gradients
  /// and soft shadows do not leak into flat areas.
  static func find(in bitmap: Bitmap) -> [Region] {
    let w = bitmap.width, h = bitmap.height
    var label = [Int32](repeating: -1, count: w * h)
    var regions: [Region] = []
    var queue = [Int](); queue.reserveCapacity(w * h)
    var members = [Int](); members.reserveCapacity(w * h)
    let minKeep = max(16, bitmap.area / 4000)

    for start in 0..<(w * h) where label[start] < 0 {
      let id = Int32(regions.count)
      queue.removeAll(keepingCapacity: true)
      members.removeAll(keepingCapacity: true)
      queue.append(start); label[start] = id
      var sum = (0, 0, 0)
      var head = 0
      while head < queue.count {
        let p = queue[head]; head += 1
        members.append(p)
        let c = bitmap[p]
        sum.0 += Int(c.r); sum.1 += Int(c.g); sum.2 += Int(c.b)
        let n = members.count
        let mean = RGB(sum.0 / n, sum.1 / n, sum.2 / n)
        let x = p % w, y = p / w
        for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)] where nx >= 0 && ny >= 0 && nx < w && ny < h {
          let q = ny * w + nx
          guard label[q] < 0 else { continue }
          let qc = bitmap[q]
          if qc.distance(to: c) <= 8 && qc.distance(to: mean) <= 14 {
            label[q] = id
            queue.append(q)
          }
        }
      }
      guard members.count >= minKeep else {
        // Too small to matter: keep the label so it is not revisited, but no region.
        regions.append(Region(color: RGB(0, 0, 0), count: 0, box: .zero, touchesEdge: true))
        continue
      }
      var minX = w, minY = h, maxX = 0, maxY = 0
      for p in members {
        let x = p % w, y = p / w
        minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
      }
      let edge = minX == 0 || minY == 0 || maxX == w - 1 || maxY == h - 1
      let color = interiorMedian(members, label: label, id: id, bitmap: bitmap)
      let spread = Double(members.reduce(0) { $0 + bitmap[$1].distance(to: color) }) / Double(members.count)
      regions.append(Region(color: color,
                            count: members.count,
                            box: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1),
                            touchesEdge: edge,
                            spread: spread))
    }
    return regions.filter { $0.count > 0 }
  }

  /// Median of pixels whose four neighbors are in the same region: skips the
  /// anti-aliased rim, where a swatch blends into its shadow or backdrop.
  private static func interiorMedian(_ members: [Int], label: [Int32], id: Int32, bitmap: Bitmap) -> RGB {
    let w = bitmap.width, h = bitmap.height
    var rs: [UInt8] = [], gs: [UInt8] = [], bs: [UInt8] = []
    for p in members {
      let x = p % w, y = p / w
      guard x > 0, y > 0, x < w - 1, y < h - 1,
            label[p - 1] == id, label[p + 1] == id, label[p - w] == id, label[p + w] == id else { continue }
      let c = bitmap[p]
      rs.append(c.r); gs.append(c.g); bs.append(c.b)
    }
    if rs.isEmpty { for p in members { let c = bitmap[p]; rs.append(c.r); gs.append(c.g); bs.append(c.b) } }
    func median(_ v: [UInt8]) -> Int { Int(v.sorted()[v.count / 2]) }
    return RGB(median(rs), median(gs), median(bs))
  }
}

// MARK: - Text

nonisolated enum TextReader {
  struct Line {
    var text: String
    /// Normalized Vision box, origin bottom-left.
    var box: CGRect
  }

  struct Result {
    var lines: [Line] = []

    /// Printed hex codes, with common OCR slips (O for 0, I or l for 1) fixed.
    var hexCodes: [RGB] {
      lines.flatMap { line -> [RGB] in
        let fixed = line.text.uppercased().map { ch -> Character in
          switch ch { case "O": "0"; case "I", "L", "|": "1"; default: ch }
        }
        let s = String(fixed)
        return s.matches(of: /#\s?([0-9A-F]{6})\b/).compactMap { RGB(hex: String($0.1)) }
      }
    }

    /// Printed hex codes whose text sits on that same color, with the text box in pixels.
    func hexAnchors(in bitmap: Bitmap) -> [(color: RGB, box: CGRect)] {
      lines.compactMap { line in
        guard let printed = Result(lines: [line]).hexCodes.first else { return nil }
        let box = pixelRect(line.box, bitmap)
        return background(of: box, in: bitmap).distance(to: printed) <= 22 ? (printed, box) : nil
      }
    }

    /// Lines whose surface is not one of the given colors.
    func lines(offColors colors: [RGB], in bitmap: Bitmap) -> [Line] {
      lines.filter { line in
        let bg = background(of: pixelRect(line.box, bitmap), in: bitmap)
        return !colors.contains { $0.distance(to: bg) < 16 }
      }
    }

    /// The largest line that is not on a swatch and reads like a name, title-cased.
    func title(palette: [RGB], in bitmap: Bitmap) -> String? {
      let boilerplate = /(?i)(@|palette|swipe|save it|hex|\.(com|top|io|net|org|co)\b|www|follow|http)/
      let outside = lines(offColors: palette, in: bitmap)
      let candidates = outside.filter { line in
        let t = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let letters = t.filter(\.isLetter).count
        return t.count >= 3 && t.count <= 40 && letters * 10 >= t.count * 7 && t.firstMatch(of: boilerplate) == nil
      }
      guard let best = candidates.max(by: { $0.box.height < $1.box.height }) else { return nil }
      // Only a clearly large line counts as a title, not a caption.
      let median = outside.map(\.box.height).sorted()[outside.count / 2]
      guard best.box.height >= median * 1.4 || outside.count <= 2 else { return nil }
      return best.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        .split(separator: " ").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }

    /// Most common color around and inside a text box: the surface the text sits on.
    private func background(of box: CGRect, in bitmap: Bitmap) -> RGB {
      let pad = max(2, box.height * 0.3)
      let r = box.insetBy(dx: -pad, dy: -pad)
      let x0 = max(0, Int(r.minX)), x1 = min(bitmap.width - 1, Int(r.maxX))
      let y0 = max(0, Int(r.minY)), y1 = min(bitmap.height - 1, Int(r.maxY))
      guard x1 >= x0, y1 >= y0 else { return RGB(0, 0, 0) }
      var bins: [Int: (sum: (Int, Int, Int), n: Int)] = [:]
      for y in y0...y1 {
        for x in x0...x1 {
          let c = bitmap[x, y]
          let key = (Int(c.r) / 12) << 16 | (Int(c.g) / 12) << 8 | Int(c.b) / 12
          var b = bins[key] ?? ((0, 0, 0), 0)
          b.sum.0 += Int(c.r); b.sum.1 += Int(c.g); b.sum.2 += Int(c.b); b.n += 1
          bins[key] = b
        }
      }
      let top = bins.values.max { $0.n < $1.n }!
      return RGB(top.sum.0 / top.n, top.sum.1 / top.n, top.sum.2 / top.n)
    }

    /// Per text line: the surface it sits on, how much of the box that surface
    /// fills, and the ink (the median of the pixels farthest from the surface).
    func samples(in bitmap: Bitmap) -> [(ink: RGB, background: RGB, backgroundShare: Double, chars: Int)] {
      lines.compactMap { line in
        let r = pixelRect(line.box, bitmap).integral
        let x0 = max(0, Int(r.minX)), x1 = min(bitmap.width - 1, Int(r.maxX))
        let y0 = max(0, Int(r.minY)), y1 = min(bitmap.height - 1, Int(r.maxY))
        guard x1 > x0 + 2, y1 > y0 + 2 else { return nil }
        let bg = background(of: r, in: bitmap)
        var pixels: [(RGB, Int)] = []
        var near = 0, best = 0
        for y in y0...y1 {
          for x in x0...x1 {
            let c = bitmap[x, y], d = c.distance(to: bg)
            if d < 12 { near += 1 }
            best = max(best, d)
            pixels.append((c, d))
          }
        }
        guard best > 50 else { return nil }
        let core = pixels.filter { $0.1 * 4 >= best * 3 }.map(\.0)
        func median(_ v: [UInt8]) -> Int { Int(v.sorted()[v.count / 2]) }
        let ink = RGB(median(core.map(\.r)), median(core.map(\.g)), median(core.map(\.b)))
        let chars = line.text.filter { !$0.isWhitespace }.count
        return (ink, bg, Double(near) / Double(pixels.count), chars)
      }
    }

    private func pixelRect(_ box: CGRect, _ bitmap: Bitmap) -> CGRect {
      let w = Double(bitmap.width), h = Double(bitmap.height)
      return CGRect(x: box.minX * w, y: (1 - box.maxY) * h, width: box.width * w, height: box.height * h)
    }
  }

  static func read(_ image: CGImage, orientation: CGImagePropertyOrientation = .up) -> Result {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    let handler = VNImageRequestHandler(cgImage: image, orientation: orientation)
    guard (try? handler.perform([request])) != nil else { return Result() }
    let lines = (request.results ?? []).compactMap { obs -> Line? in
      guard let top = obs.topCandidates(1).first else { return nil }
      return Line(text: top.string, box: obs.boundingBox)
    }
    return Result(lines: lines)
  }
}
