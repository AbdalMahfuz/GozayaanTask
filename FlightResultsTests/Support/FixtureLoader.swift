import Foundation

enum FixtureLoader {
    static func data(named name: String, file: StaticString = #filePath, line: UInt = #line) -> Data {
        guard let url = Bundle(for: FixtureLoaderAnchor.self).url(forResource: name, withExtension: "json") else {
            fatalError("Missing fixture \(name).json", file: file, line: line)
        }
        return try! Data(contentsOf: url)
    }
}

private final class FixtureLoaderAnchor {}
