import Foundation

public struct Light {

    private let _light: _Light

    init(light: _Light) {
        _light = light
    }

    var intensity: Color {
        return _light.intensity
    }

    var samples: [Point] {
        return _light.samples
    }

    func shadowIntensity(at point: Point, isShadowed: (_ point: Point, _ lightPosition: Point) -> Bool) -> Double {
        return _light.shadowIntensity(at: point, isShadowed: isShadowed)
    }
}

extension Light: Equatable {

    public static func == (lhs: Light, rhs: Light) -> Bool {
        return lhs.intensity == rhs.intensity && lhs.samples == rhs.samples
    }
}

extension Light: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        self = Light.pointLight(
            at: try container.decode(Point.self, forKey: .position),
            intensity: try container.decode(Color.self, forKey: .intensity)
        )
    }

    private enum _CodingKeys: String, CodingKey {

        case position = "at"
        case intensity
    }
}

protocol _Light {

    var intensity: Color { get }
    var samples: [Point] { get }

    func shadowIntensity(at point: Point, isShadowed: (_ point: Point, _ lightPosition: Point) -> Bool) -> Double
}

#if TEST
import XCTest
import Yams

final class LightTests: XCTestCase {

    func test_decode() {
        let content = """
        add: light
        at: [-10, 10, -10]
        intensity: [1, 1, 1]
        """

        let decoder = YAMLDecoder()
        let light = try! decoder.decode(Light.self, from: content)

        XCTAssertEqual(light, .pointLight(at: Point(-10, 10, -10), intensity: .white))
    }
}
#endif
