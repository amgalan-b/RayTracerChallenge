import Foundation

extension Light {

    public static func areaLight(
        corner: Tuple,
        fullUvec: Tuple,
        usteps: Int,
        fullVvec: Tuple,
        vsteps: Int,
        intensity: Color
    ) -> Light {
        let areaLight = _AreaLight(
            corner: corner,
            fullUvec: fullUvec,
            usteps: usteps,
            fullVvec: fullVvec,
            vsteps: vsteps,
            intensity: intensity
        )

        return Light(light: areaLight)
    }
}

private struct _AreaLight: _Light {

    let corner: Tuple
    let uvec: Tuple
    let usteps: Int
    let vvec: Tuple
    let vsteps: Int
    let samples: Int
    let centerPosition: Tuple
    let intensity: Color

    init(corner: Tuple, fullUvec: Tuple, usteps: Int, fullVvec: Tuple, vsteps: Int, intensity: Color) {
        self.corner = corner
        self.uvec = fullUvec / Double(usteps)
        self.usteps = usteps
        self.vvec = fullVvec / Double(vsteps)
        self.vsteps = vsteps
        self.samples = usteps * vsteps
        self.intensity = intensity
        self.centerPosition = corner + uvec * (Double(usteps) / 2) + vvec * (Double(vsteps) / 2)
    }

    var position: Tuple {
        return centerPosition
    }

    func intensity(at point: Tuple, isShadowed: (Tuple, Tuple) -> Bool) -> Double {
        var total = 0.0

        for v in 0 ..< vsteps {
            for u in 0 ..< usteps {
                let center = _cellCenter(u: u, v: v)
                guard !isShadowed(point, center) else {
                    continue
                }

                total += 1.0
            }
        }

        return total / Double(samples)
    }

    fileprivate func _cellCenter(u: Int, v: Int) -> Tuple {
        let uOffset = uvec * Double(u) + uvec * 0.5
        let vOffset = vvec * Double(v) + vvec * 0.5

        return corner + uOffset + vOffset
    }
}

#if TEST
import XCTest

extension LightTests {

    func test_areaLight() {
        let light = _AreaLight(
            corner: .point(0, 0, 0),
            fullUvec: .vector(2, 0, 0),
            usteps: 4,
            fullVvec: .vector(0, 0, 1),
            vsteps: 2,
            intensity: .white
        )

        XCTAssertEqual(light.corner, .point(0, 0, 0))
        XCTAssertEqual(light.uvec, .vector(0.5, 0, 0))
        XCTAssertEqual(light.usteps, 4)
        XCTAssertEqual(light.vvec, .vector(0, 0, 0.5))
        XCTAssertEqual(light.vsteps, 2)
        XCTAssertEqual(light.samples, 8)
        XCTAssertEqual(light.centerPosition, .point(1, 0, 0.5))
    }

    func test_areaLight_point() {
        let light = _AreaLight(
            corner: .point(0, 0, 0),
            fullUvec: .vector(2, 0, 0),
            usteps: 4,
            fullVvec: .vector(0, 0, 1),
            vsteps: 2,
            intensity: .white
        )

        XCTAssertEqual(light._cellCenter(u: 0, v: 0), .point(0.25, 0, 0.25))
        XCTAssertEqual(light._cellCenter(u: 1, v: 0), .point(0.75, 0, 0.25))
        XCTAssertEqual(light._cellCenter(u: 0, v: 1), .point(0.25, 0, 0.75))
        XCTAssertEqual(light._cellCenter(u: 2, v: 0), .point(1.25, 0, 0.25))
        XCTAssertEqual(light._cellCenter(u: 3, v: 1), .point(1.75, 0, 0.75))
    }

    func test_areaLight_intensity() {
        let light = _AreaLight(
            corner: .point(-0.5, -0.5, -5),
            fullUvec: .vector(1, 0, 0),
            usteps: 2,
            fullVvec: .vector(0, 1, 0),
            vsteps: 2,
            intensity: .white
        )

        XCTAssertEqual(light.intensity(at: .point(0, 0, 2), isShadowed: { _, _ in true }), 0)
        XCTAssertEqual(light.intensity(at: .point(0, 0, 2), isShadowed: { _, _ in false }), 1)
    }
}
#endif
