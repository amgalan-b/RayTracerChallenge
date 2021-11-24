import Foundation

struct Light {

    let position: Tuple
    let intensity: Color

    private init(position: Tuple, intensity: Color) {
        self.position = position
        self.intensity = intensity
    }
}

extension Light {

    static func pointLight(at position: Tuple, intensity: Color) -> Light {
        return Light(position: position, intensity: intensity)
    }
}

#if TEST
import XCTest

final class LightTests: XCTestCase {
}
#endif
