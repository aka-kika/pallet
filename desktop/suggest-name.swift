import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@main
struct SuggestName {
  static func main() async {
    let colors = CommandLine.arguments.dropFirst().joined(separator: ", ")
    guard !colors.isEmpty else { exit(1) }
#if canImport(FoundationModels)
    do {
      let session = LanguageModelSession()
      let response = try await session.respond(to: "Name this color palette in 2 to 4 words. Title case. No quotes. No punctuation besides spaces and an ampersand. Colors: \(colors)")
      let name = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !name.isEmpty else { exit(1) }
      print(name)
    } catch {
      exit(1)
    }
#else
    exit(1)
#endif
  }
}
