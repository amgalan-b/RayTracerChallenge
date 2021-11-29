import Foundation

public struct Light {

    private let _light: _Light

    init(light: _Light) {
        _light = light
    }

    var position: Tuple {
        return _light.position
    }

    var intensity: Color {
        return _light.intensity
    }

    func intensity(at point: Tuple, isShadowed: (_ point: Tuple, _ lightPosition: Tuple) -> Bool) -> Double {
        return _light.intensity(at: point, isShadowed: isShadowed)
    }
}

protocol _Light {

    var position: Tuple { get }
    var intensity: Color { get }

    func intensity(at point: Tuple, isShadowed: (_ point: Tuple, _ lightPosition: Tuple) -> Bool) -> Double
}

#if TEST
import XCTest

final class LightTests: XCTestCase {
}
#endif
