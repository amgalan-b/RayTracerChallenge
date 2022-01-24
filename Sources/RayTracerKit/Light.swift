import Foundation

public struct Light {

    private let _light: _Light

    init(light: _Light) {
        _light = light
    }

    var intensity: Color {
        return _light.intensity
    }

    var samples: [Tuple] {
        return _light.samples
    }

    func shadowIntensity(at point: Tuple, isShadowed: (_ point: Tuple, _ lightPosition: Tuple) -> Bool) -> Double {
        return _light.shadowIntensity(at: point, isShadowed: isShadowed)
    }
}

protocol _Light {

    var intensity: Color { get }
    var samples: [Tuple] { get }

    func shadowIntensity(at point: Tuple, isShadowed: (_ point: Tuple, _ lightPosition: Tuple) -> Bool) -> Double
}

#if TEST
import XCTest

final class LightTests: XCTestCase {
}
#endif
