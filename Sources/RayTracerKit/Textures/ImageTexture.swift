import Babbage
import Foundation

struct ImageTexture: Equatable, TextureProtocol {

    private let _canvas: Canvas

    init(canvas: Canvas) {
        _canvas = canvas
    }

    func color(at point: Point2D) -> Color {
        let raw_x = point.u * Double(_canvas.width - 1)
        let raw_y = (1 - point.v) * Double(_canvas.height - 1)

        let x = Int(raw_x.rounded())
        let y = Int(raw_y.rounded())

        return _canvas[x, y]
    }
}

extension ImageTexture: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        let fileName = try container.decode(String.self, forKey: .file)

        let url = URL(fileURLWithPath: fileName, isDirectory: false, relativeTo: Globals.readDirectoryURL)
        let resources = try url.resourceValues(forKeys: [.fileSizeKey])
        let formatter = ByteCountFormatter()
        let formatted = formatter.string(from: Measurement(value: Double(resources.fileSize!), unit: .bytes))

        print("Loading texture: \(fileName) (\(formatted))", to: &standardError)
        let content = try String(contentsOf: url)
        let canvas = Canvas(ppm: content)!

        self.init(canvas: canvas)
    }

    private enum _CodingKeys: String, CodingKey {

        case file
    }
}

#if TEST
import XCTest

extension TextureTests {

    func test_imageTexture() {
        let content = """
        P3
        10 10
        10
        0 0 0  1 1 1  2 2 2  3 3 3  4 4 4  5 5 5  6 6 6  7 7 7  8 8 8  9 9 9
        1 1 1  2 2 2  3 3 3  4 4 4  5 5 5  6 6 6  7 7 7  8 8 8  9 9 9  0 0 0
        2 2 2  3 3 3  4 4 4  5 5 5  6 6 6  7 7 7  8 8 8  9 9 9  0 0 0  1 1 1
        3 3 3  4 4 4  5 5 5  6 6 6  7 7 7  8 8 8  9 9 9  0 0 0  1 1 1  2 2 2
        4 4 4  5 5 5  6 6 6  7 7 7  8 8 8  9 9 9  0 0 0  1 1 1  2 2 2  3 3 3
        5 5 5  6 6 6  7 7 7  8 8 8  9 9 9  0 0 0  1 1 1  2 2 2  3 3 3  4 4 4
        6 6 6  7 7 7  8 8 8  9 9 9  0 0 0  1 1 1  2 2 2  3 3 3  4 4 4  5 5 5
        7 7 7  8 8 8  9 9 9  0 0 0  1 1 1  2 2 2  3 3 3  4 4 4  5 5 5  6 6 6
        8 8 8  9 9 9  0 0 0  1 1 1  2 2 2  3 3 3  4 4 4  5 5 5  6 6 6  7 7 7
        9 9 9  0 0 0  1 1 1  2 2 2  3 3 3  4 4 4  5 5 5  6 6 6  7 7 7  8 8 8
        """
        let canvas = Canvas(ppm: content)!
        let texture = ImageTexture(canvas: canvas)

        XCTAssertEqual(texture.color(at: Point2D(0, 0)), .rgb(0.9, 0.9, 0.9))
        XCTAssertEqual(texture.color(at: Point2D(0.3, 0)), .rgb(0.2, 0.2, 0.2))
        XCTAssertEqual(texture.color(at: Point2D(0.6, 0.3)), .rgb(0.1, 0.1, 0.1))
        XCTAssertEqual(texture.color(at: Point2D(1, 1)), .rgb(0.9, 0.9, 0.9))
    }
}
#endif
