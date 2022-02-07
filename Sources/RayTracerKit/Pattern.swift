import Foundation

public struct Pattern {

    private let _pattern: _Pattern

    init(pattern: _Pattern) {
        _pattern = pattern
    }

    func color(at worldPoint: Point, objectTransform: Matrix = .identity) -> Color {
        let objectPoint = objectTransform.inversed() * worldPoint
        let patternPoint = _pattern.transform.inversed() * objectPoint

        return _pattern.color(at: patternPoint)
    }
}

extension Pattern: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        let type = try container.decode(String.self, forKey: .typed)
        let colors = try container.decode([Color].self, forKey: .colors)
        let transform = try container.decodeIfPresent([Matrix].self, forKey: .transform)?
            .reversed()
            .reduce1(*)!

        switch type {
        case "stripes":
            self = .stripe(colors[0], colors[1], transform ?? .identity)
        case "checkers":
            self = .checker(colors[0], colors[1], transform ?? .identity)
        default:
            fatalError()
        }
    }

    private enum _CodingKeys: String, CodingKey {

        case typed
        case colors
        case transform
    }
}

protocol _Pattern {

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
        typed: stripes
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
}

extension Pattern: Equatable {

    public static func == (lhs: Pattern, rhs: Pattern) -> Bool {
        return lhs._pattern.transform == rhs._pattern.transform
    }
}
#endif
