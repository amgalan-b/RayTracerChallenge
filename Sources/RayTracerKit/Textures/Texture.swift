import Foundation

enum Texture: Equatable {

    case checker(CheckerTexture)
    case alignChecker(AlignCheckerTexture)
    case image(ImageTexture)

    private var _texture: TextureProtocol {
        switch self {
        case let .checker(texture):
            return texture
        case let .alignChecker(texture):
            return texture
        case let .image(texture):
            return texture
        }
    }

    func color(at point: Point2D) -> Color {
        return _texture.color(at: point)
    }
}

extension Texture: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "checkers":
            let texture = try CheckerTexture(from: decoder)
            self = .checker(texture)
        case "align_check":
            let texture = try AlignCheckerTexture(from: decoder)
            self = .alignChecker(texture)
        case "image":
            let texture = try ImageTexture(from: decoder)
            self = .image(texture)
        default:
            fatalError()
        }
    }

    private enum _CodingKeys: String, CodingKey {

        case type
    }
}

protocol TextureProtocol {

    func color(at point: Point2D) -> Color
}

#if TEST
import XCTest
import Yams

final class TextureTests: XCTestCase {

    func test_decode() throws {
        let content = """
        type: checkers
        width: 20
        height: 10
        colors:
          - [0, 0.5, 0]
          - [1, 1, 1]
        """

        let decoder = YAMLDecoder()
        let texture = try decoder.decode(Texture.self, from: content)
        let expected = Texture.checker(.rgb(0, 0.5, 0), .rgb(1, 1, 1), width: 20, height: 10)

        XCTAssertEqual(texture, expected)
    }
}
#endif
