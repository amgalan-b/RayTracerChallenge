import Foundation

extension Texture {

    static func checker(_ color1: Color, _ color2: Color, width: Int, height: Int) -> Texture {
        let texture = CheckerTexture(color1, color2, width: width, height: height)
        return .checker(texture)
    }
}

struct CheckerTexture: TextureProtocol, Equatable {

    private let _color1: Color
    private let _color2: Color
    private let _width: Int
    private let _height: Int

    init(_ color1: Color, _ color2: Color, width: Int, height: Int) {
        _color1 = color1
        _color2 = color2
        _width = width
        _height = height
    }

    func color(at point: Point2D) -> Color {
        let u2 = (point.u * Double(_width)).floor()
        let v2 = (point.v * Double(_height)).floor()

        if (u2 + v2).truncatingRemainder(dividingBy: 2).isAlmostEqual(to: 0) {
            return _color1
        } else {
            return _color2
        }
    }
}

extension CheckerTexture: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        let colors = try container.decode([Color].self, forKey: .colors)
        self.init(
            colors[0],
            colors[1],
            width: try container.decode(Int.self, forKey: .width),
            height: try container.decode(Int.self, forKey: .height)
        )
    }

    private enum _CodingKeys: String, CodingKey {

        case width
        case height
        case colors
    }
}

#if TEST
import XCTest
import Yams

final class UVPatternTests: XCTestCase {

    func test_pattern() {
        let texture = CheckerTexture(.black, .white, width: 2, height: 2)

        XCTAssertEqual(texture.color(at: Point2D(0, 0)), .black)
        XCTAssertEqual(texture.color(at: Point2D(0.5, 0)), .white)
        XCTAssertEqual(texture.color(at: Point2D(0, 0.5)), .white)
        XCTAssertEqual(texture.color(at: Point2D(0.5, 0.5)), .black)
        XCTAssertEqual(texture.color(at: Point2D(1, 1)), .black)
    }

    func test_checker_decode() throws {
        let content = """
        type: checkers
        width: 20
        height: 10
        colors:
          - [0, 0.5, 0]
          - [1, 1, 1]
        """

        let decoder = YAMLDecoder()
        let texture = try decoder.decode(CheckerTexture.self, from: content)
        let expected = CheckerTexture(.rgb(0, 0.5, 0), .rgb(1, 1, 1), width: 20, height: 10)

        XCTAssertEqual(texture, expected)
    }
}
#endif
