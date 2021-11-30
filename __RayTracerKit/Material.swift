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

        var totalDiffuseSpecular = Color.black
        for sample in light.samples {
            totalDiffuseSpecular = totalDiffuseSpecular + _diffuseAndSpecular(
                for: sample,
                position: position,
                eyeVector: eyeVector,
                normalVector: normalVector,
                lightIntensity: light.intensity,
                effectiveColor: effectiveColor
            )
        }

        return ambientColor + totalDiffuseSpecular / Double(light.samples.count) * intensity
    }

    fileprivate func _diffuseAndSpecular(
        for lightSample: Tuple,
        position: Tuple,
        eyeVector: Tuple,
        normalVector: Tuple,
        lightIntensity: Color,
        effectiveColor: Color
    ) -> Color {
        let lightVector = (lightSample - position).normalized()
        let lightDotNormal = lightVector.dotProduct(with: normalVector)

        guard lightDotNormal >= 0 else {
            return .black
        }

        let diffuseColor = effectiveColor * diffuse * lightDotNormal
        let reflectionVector = -lightVector.reflected(on: normalVector)
        let reflectionDotEye = reflectionVector.dotProduct(with: eyeVector)

        guard reflectionDotEye > 0 else {
            return diffuseColor
        }

        let factor = reflectionDotEye.pow(shininess)
        let specularColor = lightIntensity * specular * factor

        return diffuseColor + specularColor
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

    func test_lighting_areaLight() {
        let light = Light.areaLight(origin: .point(-0.5, -0.5, -5), width: 1, height: 1, density: 2, intensity: .white)
        let sphere = Sphere()
        sphere.material.specular = 0

        let c1 = sphere.material.lighting(
            at: .point(0, 0, -1),
            light: light,
            eyeVector: .vector(0, 0, -1),
            normal: .vector(0, 0, -1),
            intensity: 1.0
        )

        let c2 = sphere.material.lighting(
            at: .point(0, 0.7071, -0.7071),
            light: light,
            eyeVector: .vector(0, 0.7071, -4.2929).normalized(),
            normal: .vector(0, 0.7071, -0.7071),
            intensity: 1.0
        )

        XCTAssertEqual(c1, .rgb(0.9965, 0.9965, 0.9965))
        XCTAssertEqual(c2, .rgb(0.62318, 0.62318, 0.62318))
    }
}
#endif
