import Foundation

extension Light {

    public static func areaLight(
        origin: Tuple,
        width: Double,
        height: Double,
        density: Int,
        intensity: Color,
        transform: Matrix = .identity
    ) -> Light {
        let areaLight = _AreaLight(
            origin: origin,
            fullUvec: transform * .vector(width, 0, 0),
            usteps: density,
            fullVvec: transform * .vector(0, height, 0),
            vsteps: density,
            intensity: intensity
        )

        return Light(light: areaLight)
    }
}

private struct _AreaLight: _Light {

    let origin: Tuple
    let uvector: Tuple
    let usteps: Int
    let vvector: Tuple
    let vsteps: Int
    let sampleCount: Int
    let intensity: Color
    let samples: [Tuple]

    init(origin: Tuple, fullUvec: Tuple, usteps: Int, fullVvec: Tuple, vsteps: Int, intensity: Color) {
        self.origin = origin
        self.uvector = fullUvec / Double(usteps)
        self.usteps = usteps
        self.vvector = fullVvec / Double(vsteps)
        self.vsteps = vsteps
        self.sampleCount = usteps * vsteps
        self.intensity = intensity
        self.samples = Self._samples(origin: origin, uvector: uvector, usteps: usteps, vvector: vvector, vsteps: vsteps)
    }

    func shadowIntensity(at point: Tuple, isShadowed: (Tuple, Tuple) -> Bool) -> Double {
        var total = 0.0

        for v in 0 ..< vsteps {
            for u in 0 ..< usteps {
                let sample = _randomSampleInCell(u: u, v: v)
                guard !isShadowed(point, sample) else {
                    continue
                }

                total += 1.0
            }
        }

        return 1.0 - total / Double(sampleCount)
    }

    fileprivate func _randomSampleInCell(u: Int, v: Int, staticRandom: Double? = nil) -> Tuple {
        let u = Double(u) + (staticRandom ?? .random(in: 0 ... 1))
        let v = Double(v) + (staticRandom ?? .random(in: 0 ... 1))

        let uOffset = uvector * u
        let vOffset = vvector * v

        return origin + uOffset + vOffset
    }
}

extension _AreaLight {

    fileprivate static func _samples(
        origin: Tuple,
        uvector: Tuple,
        usteps: Int,
        vvector: Tuple,
        vsteps: Int
    ) -> [Tuple] {
        var samples = [Tuple]()
        for v in 0 ..< vsteps {
            for u in 0 ..< usteps {
                let u = Double(u) + 0.5
                let v = Double(v) + 0.5

                let uOffset = uvector * u
                let vOffset = vvector * v

                samples.append(origin + uOffset + vOffset)
            }
        }

        return samples
    }
}

#if TEST
import XCTest

extension LightTests {

    func test_areaLight() {
        let light = _AreaLight(
            origin: .point(0, 0, 0),
            fullUvec: .vector(2, 0, 0),
            usteps: 4,
            fullVvec: .vector(0, 0, 1),
            vsteps: 2,
            intensity: .white
        )

        XCTAssertEqual(light.origin, .point(0, 0, 0))
        XCTAssertEqual(light.uvector, .vector(0.5, 0, 0))
        XCTAssertEqual(light.usteps, 4)
        XCTAssertEqual(light.vvector, .vector(0, 0, 0.5))
        XCTAssertEqual(light.vsteps, 2)
        XCTAssertEqual(light.sampleCount, 8)
    }

    func test_areaLight_point() {
        let light = _AreaLight(
            origin: .point(0, 0, 0),
            fullUvec: .vector(2, 0, 0),
            usteps: 4,
            fullVvec: .vector(0, 0, 1),
            vsteps: 2,
            intensity: .white
        )

        XCTAssertEqual(light._randomSampleInCell(u: 0, v: 0, staticRandom: 0.5), .point(0.25, 0, 0.25))
        XCTAssertEqual(light._randomSampleInCell(u: 1, v: 0, staticRandom: 0.5), .point(0.75, 0, 0.25))
        XCTAssertEqual(light._randomSampleInCell(u: 0, v: 1, staticRandom: 0.5), .point(0.25, 0, 0.75))
        XCTAssertEqual(light._randomSampleInCell(u: 2, v: 0, staticRandom: 0.5), .point(1.25, 0, 0.25))
        XCTAssertEqual(light._randomSampleInCell(u: 3, v: 1, staticRandom: 0.5), .point(1.75, 0, 0.75))
    }

    func test_areaLight_intensity() {
        let light = _AreaLight(
            origin: .point(-0.5, -0.5, -5),
            fullUvec: .vector(1, 0, 0),
            usteps: 2,
            fullVvec: .vector(0, 1, 0),
            vsteps: 2,
            intensity: .white
        )

        let c1 = light.shadowIntensity(at: .point(0, 0, 2)) { _, _ in true }
        let c2 = light.shadowIntensity(at: .point(0, 0, 2)) { _, _ in false }

        XCTAssertEqual(c1, 1)
        XCTAssertEqual(c2, 0)
    }
}
#endif
