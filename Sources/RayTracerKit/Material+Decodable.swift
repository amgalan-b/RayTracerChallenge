import Foundation

extension Material: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)

        self.init(
            color: try container.decodeIfPresent(Color.self, forKey: .color) ?? .white,
            ambient: try container.decodeIfPresent(Double.self, forKey: .ambient) ?? 0.1,
            diffuse: try container.decodeIfPresent(Double.self, forKey: .diffuse) ?? 0.9,
            specular: try container.decodeIfPresent(Double.self, forKey: .specular) ?? 0.9,
            shininess: try container.decodeIfPresent(Double.self, forKey: .shininess) ?? 200,
            reflective: try container.decodeIfPresent(Double.self, forKey: .reflective) ?? 0,
            transparency: try container.decodeIfPresent(Double.self, forKey: .transparency) ?? 0,
            refractiveIndex: try container.decodeIfPresent(Double.self, forKey: .refractiveIndex) ?? 1,
            pattern: nil
        )
    }

    private enum _CodingKeys: String, CodingKey {

        case color
        case ambient
        case diffuse
        case specular
        case shininess
        case reflective
        case transparency
        case refractiveIndex = "refractive_index"
    }
}

#if TEST
import XCTest
import Yams

extension MaterialTests {

    func test_decode() {
        let data = """
        color: [0.373, 0.404, 0.550]
        diffuse: 0.2
        ambient: 0.0
        specular: 1.0
        shininess: 200
        reflective: 0.7
        transparency: 0.7
        refractive_index: 1.5
        """

        let decoder = YAMLDecoder()
        let material = try! decoder.decode(Material.self, from: data)
        let expected = Material.default(
            color: .rgb(0.373, 0.404, 0.550),
            ambient: 0,
            diffuse: 0.2,
            specular: 1,
            shininess: 200,
            reflective: 0.7,
            transparency: 0.7,
            refractiveIndex: 1.5
        )

        XCTAssertEqual(material, expected)
    }
}
#endif
