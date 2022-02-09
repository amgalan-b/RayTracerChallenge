import Foundation

enum Light {

    case pointLight(PointLight)
    case areaLight(AreaLight)

    var intensity: Color {
        switch self {
        case let .pointLight(pointLight):
            return pointLight.intensity
        case let .areaLight(areaLight):
            return areaLight.intensity
        }
    }

    var samples: [Point] {
        switch self {
        case let .pointLight(pointLight):
            return [pointLight.position]
        case let .areaLight(areaLight):
            return areaLight.samples
        }
    }

    func shadowIntensity(at point: Point, isShadowed: (_ point: Point, _ lightPosition: Point) -> Bool) -> Double {
        switch self {
        case let .pointLight(pointLight):
            return pointLight.shadowIntensity(at: point, isShadowed: isShadowed)
        case let .areaLight(areaLight):
            return areaLight.shadowIntensity(at: point, isShadowed: isShadowed)
        }
    }
}

extension Light: Decodable {

    init(from decoder: Decoder) throws {
        if let pointLight = try? PointLight(from: decoder) {
            self = .pointLight(pointLight)
        } else if let areaLight = try? AreaLight(from: decoder) {
            self = .areaLight(areaLight)
        } else {
            fatalError()
        }
    }
}

#if TEST
import XCTest
import Yams

final class LightTests: XCTestCase {
}

extension Light: Equatable {
}
#endif
