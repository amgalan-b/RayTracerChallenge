import Foundation

public struct Material {

    var color: Color
    var ambient: Double
    var diffuse: Double
    var specular: Double
    var shininess: Double

    init(color: Color, ambient: Double, diffuse: Double, specular: Double, shininess: Double) {
        self.color = color
        self.ambient = ambient
        self.diffuse = diffuse
        self.specular = specular
        self.shininess = shininess
    }

    func lighting(
        at position: Tuple,
        light: Light,
        eyeVector: Tuple,
        normal normalVector: Tuple,
        intensity: Double = 1.0
    ) -> Color {
        let effectiveColor = color * light.intensity
        let ambientColor = effectiveColor * ambient

        guard intensity > 0 else {
            return ambientColor
        }

        let lightVector = (light.position - position).normalized()
        let lightDotNormal = lightVector.dotProduct(with: normalVector)

        guard lightDotNormal >= 0 else {
            return ambientColor
        }

        let diffuseColor = effectiveColor * diffuse * lightDotNormal * intensity
        let reflectionVector = -lightVector.reflected(on: normalVector)
        let reflectionDotEye = reflectionVector.dotProduct(with: eyeVector)

        guard reflectionDotEye > 0 else {
            return ambientColor + diffuseColor
        }

        let factor = reflectionDotEye.pow(shininess)
        let specularColor = light.intensity * specular * factor * intensity

        return ambientColor + diffuseColor + specularColor
    }
}

extension Material: Equatable {
}

extension Material {

    public static let `default` = Material(color: .white, ambient: 0.1, diffuse: 0.9, specular: 0.9, shininess: 200)
}

#if TEST
import XCTest

final class MaterialTests: XCTestCase {

    func test_lighting_eyeBetweenLightAndSurface() {
        let color = Material.default.lighting(
            at: .point(0, 0, 0),
            light: .pointLight(at: .point(0, 0, -10), intensity: .white),
            eyeVector: .vector(0, 0, -1),
            normal: .vector(0, 0, -1)
        )

        XCTAssertEqual(color, .rgb(1.9, 1.9, 1.9))
    }

    func test_lighting_eyeOffset45() {
        let color = Material.default.lighting(
            at: .point(0, 0, 0),
            light: .pointLight(at: .point(0, 0, -10), intensity: .white),
            eyeVector: .vector(0, sqrt(2) / 2, -sqrt(2) / 2),
            normal: .vector(0, 0, -1)
        )

        XCTAssertEqual(color, .white)
    }

    func test_lighting_lightOffset45() {
        let color = Material.default.lighting(
            at: .point(0, 0, 0),
            light: .pointLight(at: .point(0, 10, -10), intensity: .white),
            eyeVector: .vector(0, 0, -1),
            normal: .vector(0, 0, -1)
        )

        XCTAssertEqual(color, .rgb(0.7364, 0.7364, 0.7364))
    }

    func test_lighting_eyeAtReflection() {
        let color = Material.default.lighting(
            at: .point(0, 0, 0),
            light: .pointLight(at: .point(0, 10, -10), intensity: .white),
            eyeVector: .vector(0, -sqrt(2) / 2, -sqrt(2) / 2),
            normal: .vector(0, 0, -1)
        )

        XCTAssertEqual(color, .rgb(1.6364, 1.6364, 1.6364))
    }

    func test_lighting_lightBehindSurface() {
        let color = Material.default.lighting(
            at: .point(0, 0, 0),
            light: .pointLight(at: .point(0, 0, 10), intensity: .white),
            eyeVector: .vector(0, 0, -1),
            normal: .vector(0, 0, -1)
        )

        XCTAssertEqual(color, .rgb(0.1, 0.1, 0.1))
    }

    func test_lighting_lightAndEyeAtSameAngle() {
        let color = Material.default.lighting(
            at: .point(0, 0, 0),
            light: .pointLight(at: .point(0, 10, -10), intensity: .white),
            eyeVector: .vector(0, 5, -5),
            normal: .vector(0, 0, -1)
        )

        XCTAssertEqual(color, .rgb(0.7364, 0.7364, 0.7364))
    }

    func test_lighting_shadowed() {
        let color = Material.default.lighting(
            at: .point(0, 0, 0),
            light: .pointLight(at: .point(0, 10, -10), intensity: .white),
            eyeVector: .vector(0, 0, -1),
            normal: .vector(0, 0, -1),
            intensity: 0.0
        )

        XCTAssertEqual(color, .rgb(0.1, 0.1, 0.1))
    }

    func test_lighting_intensity() {
        let material = Material(color: .white, ambient: 0.1, diffuse: 0.9, specular: 0, shininess: 200)
        let light = Light.pointLight(at: .point(0, 0, -10), intensity: .white)

        let point = Tuple.point(0, 0, -1)
        let eyeVector = Tuple.vector(0, 0, -1)
        let normalVector = Tuple.vector(0, 0, -1)

        let r1 = material.lighting(at: point, light: light, eyeVector: eyeVector, normal: normalVector, intensity: 1.0)
        let r2 = material.lighting(at: point, light: light, eyeVector: eyeVector, normal: normalVector, intensity: 0.5)
        let r3 = material.lighting(at: point, light: light, eyeVector: eyeVector, normal: normalVector, intensity: 0)

        XCTAssertEqual(r1, .white)
        XCTAssertEqual(r2, .rgb(0.55, 0.55, 0.55))
        XCTAssertEqual(r3, .rgb(0.1, 0.1, 0.1))
    }
}
#endif
