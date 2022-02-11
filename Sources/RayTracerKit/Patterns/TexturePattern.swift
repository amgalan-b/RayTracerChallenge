import Foundation

extension Pattern {

    static func texture(_ texture: Texture, map: TextureMap, transform: Matrix = .identity) -> Pattern {
        let pattern = TexturePattern(texture, map: map, transform: transform)
        return .texture(pattern)
    }
}

struct TexturePattern: PatternProtocol {

    let texture: Texture
    let map: TextureMap
    let transform: Matrix

    init(_ texture: Texture, map: TextureMap, transform: Matrix = .identity) {
        self.texture = texture
        self.map = map
        self.transform = transform
    }

    func color(at localPoint: Point) -> Color {
        let uv = map.map(point: localPoint)
        return texture.color(at: uv)
    }
}

extension TexturePattern: Equatable {

    static func == (lhs: TexturePattern, rhs: TexturePattern) -> Bool {
        return lhs.transform == rhs.transform
    }
}

#if TEST
import XCTest

extension PatternTests {

    func test_texturePattern() {
        let texture = CheckerTexture(.black, .white, width: 16, height: 8)
        let pattern = TexturePattern(.checker(texture), map: .spherical)

        XCTAssertEqual(pattern.color(at: Point(0.4315, 0.4670, 0.7719)), .white)
        XCTAssertEqual(pattern.color(at: Point(-0.9654, 0.2552, -0.0534)), .black)
        XCTAssertEqual(pattern.color(at: Point(0.1039, 0.7090, 0.6975)), .white)
        XCTAssertEqual(pattern.color(at: Point(-0.4986, -0.7856, -0.3663)), .black)
        XCTAssertEqual(pattern.color(at: Point(-0.0317, -0.9395, 0.3411)), .black)
        XCTAssertEqual(pattern.color(at: Point(0.4809, -0.7721, 0.4154)), .black)
        XCTAssertEqual(pattern.color(at: Point(0.0285, -0.9612, -0.2745)), .black)
        XCTAssertEqual(pattern.color(at: Point(-0.5734, -0.2162, -0.7903)), .white)
        XCTAssertEqual(pattern.color(at: Point(0.7688, -0.1470, 0.6223)), .black)
        XCTAssertEqual(pattern.color(at: Point(-0.7652, 0.2175, 0.6060)), .black)
    }
}
#endif
