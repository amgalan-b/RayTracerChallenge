import Foundation

extension Light {

    static func areaLight(
        origin: Point,
        width: Double,
        height: Double,
        density: Int,
        intensity: Color,
        transform: Matrix = .identity
    ) -> Light {
        let areaLight = AreaLight(
            origin: origin,
            fullUvec: transform * Vector(width, 0, 0),
            usteps: density,
            fullVvec: transform * Vector(0, height, 0),
            vsteps: density,
            intensity: intensity
        )

        return .areaLight(areaLight)
    }
}

struct AreaLight: Equatable {

    let origin: Point
    let uvector: Vector
    let usteps: Int
    let vvector: Vector
    let vsteps: Int
    let sampleCount: Int
    let intensity: Color
    let samples: [Point]

    init(origin: Point, fullUvec: Vector, usteps: Int, fullVvec: Vector, vsteps: Int, intensity: Color) {
        self.origin = origin
        self.uvector = fullUvec / Double(usteps)
        self.usteps = usteps
        self.vvector = fullVvec / Double(vsteps)
        self.vsteps = vsteps
        self.sampleCount = usteps * vsteps
        self.intensity = intensity
        self.samples = Self._samples(origin: origin, uvector: uvector, usteps: usteps, vvector: vvector, vsteps: vsteps)
    }

    func shadowIntensity(at point: Point, isShadowed: (Point, Point) -> Bool) -> Double {
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

    fileprivate func _randomSampleInCell(u: Int, v: Int, staticRandom: Double? = nil) -> Point {
        let u = Double(u) + (staticRandom ?? .random(in: 0 ... 1))
        let v = Double(v) + (staticRandom ?? .random(in: 0 ... 1))

        let uOffset = uvector * u
        let vOffset = vvector * v

        return origin + uOffset + vOffset
    }

    fileprivate static func _samples(
        origin: Point,
        uvector: Vector,
        usteps: Int,
        vvector: Vector,
        vsteps: Int
    ) -> [Point] {
        var samples = [Point]()
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

extension AreaLight: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        self.init(
            origin: try container.decode(Point.self, forKey: .corner),
            fullUvec: try container.decode(Vector.self, forKey: .uvec),
            usteps: try container.decode(Int.self, forKey: .usteps),
            fullVvec: try container.decode(Vector.self, forKey: .vvec),
            vsteps: try container.decode(Int.self, forKey: .vsteps),
            intensity: try container.decode(Color.self, forKey: .intensity)
        )
    }

    private enum _CodingKeys: String, CodingKey {

        case corner
        case uvec
        case vvec
        case usteps
        case vsteps
        case intensity
    }
}

#if TEST
import XCTest
import Yams

extension LightTests {

    func test_areaLight() {
        let light = AreaLight(
            origin: Point(0, 0, 0),
            fullUvec: Vector(2, 0, 0),
            usteps: 4,
            fullVvec: Vector(0, 0, 1),
            vsteps: 2,
            intensity: .white
        )

        XCTAssertEqual(light.origin, Point(0, 0, 0))
        XCTAssertEqual(light.uvector, Vector(0.5, 0, 0))
        XCTAssertEqual(light.usteps, 4)
        XCTAssertEqual(light.vvector, Vector(0, 0, 0.5))
        XCTAssertEqual(light.vsteps, 2)
        XCTAssertEqual(light.sampleCount, 8)
    }

    func test_areaLight_point() {
        let light = AreaLight(
            origin: Point(0, 0, 0),
            fullUvec: Vector(2, 0, 0),
            usteps: 4,
            fullVvec: Vector(0, 0, 1),
            vsteps: 2,
            intensity: .white
        )

        XCTAssertEqual(light._randomSampleInCell(u: 0, v: 0, staticRandom: 0.5), Point(0.25, 0, 0.25))
        XCTAssertEqual(light._randomSampleInCell(u: 1, v: 0, staticRandom: 0.5), Point(0.75, 0, 0.25))
        XCTAssertEqual(light._randomSampleInCell(u: 0, v: 1, staticRandom: 0.5), Point(0.25, 0, 0.75))
        XCTAssertEqual(light._randomSampleInCell(u: 2, v: 0, staticRandom: 0.5), Point(1.25, 0, 0.25))
        XCTAssertEqual(light._randomSampleInCell(u: 3, v: 1, staticRandom: 0.5), Point(1.75, 0, 0.75))
    }

    func test_areaLight_intensity() {
        let light = AreaLight(
            origin: Point(-0.5, -0.5, -5),
            fullUvec: Vector(1, 0, 0),
            usteps: 2,
            fullVvec: Vector(0, 1, 0),
            vsteps: 2,
            intensity: .white
        )

        let c1 = light.shadowIntensity(at: Point(0, 0, 2)) { _, _ in true }
        let c2 = light.shadowIntensity(at: Point(0, 0, 2)) { _, _ in false }

        XCTAssertEqual(c1, 1)
        XCTAssertEqual(c2, 0)
    }

    func test_areaLight_decode() throws {
        let content = """
        corner: [-1, 2, 4]
        uvec: [2, 0, 0]
        vvec: [0, 2, 0]
        usteps: 10
        vsteps: 10
        jitter: true
        intensity: [1.5, 1.5, 1.5]
        """

        let decoder = YAMLDecoder()
        let light = try decoder.decode(Light.self, from: content)
        let expected = AreaLight(
            origin: Point(-1, 2, 4),
            fullUvec: Vector(2, 0, 0),
            usteps: 10,
            fullVvec: Vector(0, 2, 0),
            vsteps: 10,
            intensity: .rgb(1.5, 1.5, 1.5)
        )

        XCTAssertEqual(light, .areaLight(expected))
    }
}
#endif