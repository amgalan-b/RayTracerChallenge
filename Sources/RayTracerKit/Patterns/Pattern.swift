import Foundation

enum Pattern {

    case checker(CheckerPattern)
    case gradient(GradientPattern)
    case stripe(StripePattern)
    case texture(TexturePattern)

    func color(at worldPoint: Point, objectTransform: Matrix = .identity) -> Color {
        let objectPoint = objectTransform.inversed() * worldPoint
        let patternPoint = _pattern.transform.inversed() * objectPoint

        return _pattern.color(at: patternPoint)
    }

    private var _pattern: PatternProtocol {
        switch self {
        case let .checker(pattern):
            return pattern
        case let .gradient(pattern):
            return pattern
        case let .stripe(pattern):
            return pattern
        case let .texture(pattern):
            return pattern
        }
    }
}

extension Pattern: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let colors = try container.decodeIfPresent([Color].self, forKey: .colors) ?? []
        let transform = try container.decodeIfPresent([Matrix].self, forKey: .transform)?
            .reversed()
            .reduce1(*) ?? .identity

        switch type {
        case "stripes":
            self = .stripe(colors[0], colors[1], transform)
        case "checkers":
            self = .checker(colors[0], colors[1], transform)
        case "map":
            let mapping = try TextureMap(from: decoder)
            self = .texture(map: mapping, transform: transform)
        default:
            fatalError()
        }
    }

    private enum _CodingKeys: String, CodingKey {

        case type
        case colors
        case transform
    }
}

protocol PatternProtocol {

    var transform: Matrix { get }

    func color(at localPoint: Point) -> Color
}

#if TEST
import XCTest
import Yams

final class PatternTests: XCTestCase {

    func test_objectTransformation() {
        let pattern = Pattern.stripe(.white, .black)
        XCTAssertEqual(pattern.color(at: Point(1.5, 0, 0), objectTransform: .scaling(2, 2, 2)), .white)
    }

    func test_patternTransformation() {
        let pattern = Pattern.stripe(.white, .black, .scaling(2, 2, 2))
        XCTAssertEqual(pattern.color(at: Point(1.5, 0, 0)), .white)
    }

    func test_objectAndPatternTransformation() {
        let pattern = Pattern.stripe(.white, .black, .translation(0.5, 0, 0))
        XCTAssertEqual(pattern.color(at: Point(2.5, 0, 0), objectTransform: .scaling(2, 2, 2)), .white)
    }

    func test_decode_stripe() throws {
        let content = """
        type: stripes
        colors:
          - [0.45, 0.45, 0.45]
          - [0.55, 0.55, 0.55]
        transform:
          - [scale, 0.25, 0.25, 0.25]
          - [rotate-y, 1.5708]
        """

        let decoder = YAMLDecoder()
        let pattern = try decoder.decode(Pattern.self, from: content)

        let expected = Pattern.stripe(
            .rgb(0.45, 0.45, 0.45),
            .rgb(0.55, 0.55, 0.55),
            .rotationY(1.5708) * .scaling(0.25, 0.25, 0.25)
        )

        XCTAssertEqual(pattern, expected)
    }

    func test_decode_texture() throws {
        let content = """
        type: map
        mapping: spherical
        uv_pattern:
          type: checkers
          width: 20
          height: 10
          colors:
            - [0, 0.5, 0]
            - [1, 1, 1]
        """

        let decoder = YAMLDecoder()
        let pattern = try decoder.decode(Pattern.self, from: content)
        let expected = Pattern.texture(map: .spherical(.checker(.rgb(0, 0.5, 0), .rgb(1, 1, 1), width: 20, height: 10)))

        XCTAssertEqual(pattern, expected)
    }

    func test_decode_textureCubic() throws {
        let content = """
        type: map
        mapping: cube
        left:
          type: align_check
          colors:
            main: [1, 0, 0] # red
            ul: [1, 1, 0]   # yellow
            ur: [1, 0, 1]   # purple
            bl: [0, 1, 0]   # green
            br: [1, 1, 1]   # white
        front:
          type: align_check
          colors:
            main: [1, 0, 0] # red
            ul: [1, 1, 0]   # yellow
            ur: [1, 0, 1]   # purple
            bl: [0, 1, 0]   # green
            br: [1, 1, 1]   # white
        right:
          type: align_check
          colors:
            main: [1, 0, 0] # red
            ul: [1, 1, 0]   # yellow
            ur: [1, 0, 1]   # purple
            bl: [0, 1, 0]   # green
            br: [1, 1, 1]   # white
        back:
          type: align_check
          colors:
            main: [1, 0, 0] # red
            ul: [1, 1, 0]   # yellow
            ur: [1, 0, 1]   # purple
            bl: [0, 1, 0]   # green
            br: [1, 1, 1]   # white
        up:
          type: align_check
          colors:
            main: [1, 0, 0] # red
            ul: [1, 1, 0]   # yellow
            ur: [1, 0, 1]   # purple
            bl: [0, 1, 0]   # green
            br: [1, 1, 1]   # white
        down:
          type: align_check
          colors:
            main: [1, 0, 0] # red
            ul: [1, 1, 0]   # yellow
            ur: [1, 0, 1]   # purple
            bl: [0, 1, 0]   # green
            br: [1, 1, 1]   # white
        """

        let decoder = YAMLDecoder()
        let pattern = try decoder.decode(Pattern.self, from: content)
        let texture = Texture.alignChecker(.rgb(1, 0, 0), .rgb(1, 1, 0), .rgb(1, 0, 1), .rgb(0, 1, 0), .rgb(1, 1, 1))
        let expected = Pattern.texture(map: .cubic(texture, texture, texture, texture, texture, texture))

        XCTAssertEqual(pattern, expected)
    }
}

extension Pattern: Equatable {
}
#endif
