import Foundation

extension Light {

    public static func pointLight(at position: Point, intensity: Color) -> Light {
        return .pointLight(PointLight(at: position, intensity: intensity))
    }
}

struct PointLight: Equatable {

    let position: Point
    let intensity: Color

    init(at position: Point, intensity: Color) {
        self.position = position
        self.intensity = intensity
    }

    func shadowIntensity(at point: Point, isShadowed: (Point, Point) -> Bool) -> Double {
        if isShadowed(point, position) {
            return 1.0
        }

        return 0.0
    }
}

extension PointLight: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        self.init(
            at: try container.decode(Point.self, forKey: .position),
            intensity: try container.decode(Color.self, forKey: .intensity)
        )
    }

    private enum _CodingKeys: String, CodingKey {

        case position = "at"
        case intensity
    }
}

#if TEST
import XCTest
import Yams

extension LightTests {

    func test_pointLight_decode() {
        let content = """
        at: [-10, 10, -10]
        intensity: [1, 1, 1]
        """

        let decoder = YAMLDecoder()
        let light = try! decoder.decode(PointLight.self, from: content)

        XCTAssertEqual(light, PointLight(at: Point(-10, 10, -10), intensity: .white))
    }
}
#endif
