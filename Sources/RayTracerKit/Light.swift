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

protocol _Light {

    var intensity: Color { get }
    var samples: [Point] { get }

    func shadowIntensity(at point: Point, isShadowed: (_ point: Point, _ lightPosition: Point) -> Bool) -> Double
}

#if TEST
import XCTest

final class LightTests: XCTestCase {
}
#endif
