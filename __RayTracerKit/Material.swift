import Foundation

public struct Material {

    public var color: Color
    public var ambient: Double
    public var diffuse: Double
    public var specular: Double
    public var shininess: Double
    public var reflective: Double
    public var transparency: Double
    public var refractiveIndex: Double
    public var pattern: Pattern?

    public init(
        color: Color,
        ambient: Double,
        diffuse: Double,
        specular: Double,
        shininess: Double,
        reflective: Double,
        transparency: Double,
        refractiveIndex: Double,
        pattern: Pattern? = nil
    ) {
        self.color = color
        self.ambient = ambient
        self.diffuse = diffuse
        self.specular = specular
        self.shininess = shininess
        self.reflective = reflective
        self.transparency = transparency
        self.refractiveIndex = refractiveIndex
        self.pattern = pattern
    }

    func lighting(
        at position: Tuple,
        light: Light,
        eyeVector: Tuple,
        normal normalVector: Tuple,
        objectTransform: Matrix = .identity,
        shadowIntensity: Double = 0.0
    ) -> Color {
        let effectiveColor = _effectiveColor(
            at: position,
            lightIntensity: light.intensity,
            objectTransform: objectTransform
        )
        let ambientColor = effectiveColor * ambient

        guard shadowIntensity < 1 else {
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

        return ambientColor + totalDiffuseSpecular / Double(light.samples.count) * (1 - shadowIntensity)
    }

    fileprivate func _effectiveColor(at point: Tuple, lightIntensity: Color, objectTransform: Matrix) -> Color {
        guard let pattern = pattern else {
            return color * lightIntensity
        }

        return pattern.color(at: point, objectTransform: objectTransform) * lightIntensity
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

extension Material {

    public static let `default` = Material(
        color: .white,
        ambient: 0.1,
        diffuse: 0.9,
        specular: 0.9,
        shininess: 200,
        reflective: 0,
        transparency: 0,
        refractiveIndex: 1
    )

    public static func `default`(
        color: Color = .white,
        ambient: Double = 0.1,
        diffuse: Double = 0.9,
        specular: Double = 0.9,
        shininess: Double = 200,
        reflective: Double = 0,
        transparency: Double = 0,
        refractiveIndex: Double = 1,
        pattern: Pattern? = nil
    ) -> Material {
        return Material(
            color: color,
            ambient: ambient,
            diffuse: diffuse,
            specular: specular,
            shininess: shininess,
            reflective: reflective,
            transparency: transparency,
            refractiveIndex: refractiveIndex,
            pattern: pattern
        )
    }
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
            shadowIntensity: 1.0
        )

        XCTAssertEqual(color, .rgb(0.1, 0.1, 0.1))
    }

    func test_lighting_intensity() {
        let material = Material.default(specular: 0)
        let light = Light.pointLight(at: .point(0, 0, -10), intensity: .white)

        let point = Tuple.point(0, 0, -1)
        let eyeVector = Tuple.vector(0, 0, -1)
        let normalVector = Tuple.vector(0, 0, -1)

        let r1 = material.lighting(
            at: point,
            light: light,
            eyeVector: eyeVector,
            normal: normalVector,
            shadowIntensity: 0
        )
        let r2 = material.lighting(
            at: point,
            light: light,
            eyeVector: eyeVector,
            normal: normalVector,
            shadowIntensity: 0.5
        )
        let r3 = material.lighting(
            at: point,
            light: light,
            eyeVector: eyeVector,
            normal: normalVector,
            shadowIntensity: 1
        )

        XCTAssertEqual(r1, .white)
        XCTAssertEqual(r2, .rgb(0.55, 0.55, 0.55))
        XCTAssertEqual(r3, .rgb(0.1, 0.1, 0.1))
    }

    func test_lighting_areaLight() {
        let light = Light.areaLight(origin: .point(-0.5, -0.5, -5), width: 1, height: 1, density: 2, intensity: .white)
        let sphere = Sphere(material: .default(specular: 0))

        let c1 = sphere.material.lighting(
            at: .point(0, 0, -1),
            light: light,
            eyeVector: .vector(0, 0, -1),
            normal: .vector(0, 0, -1)
        )

        let c2 = sphere.material.lighting(
            at: .point(0, 0.7071, -0.7071),
            light: light,
            eyeVector: .vector(0, 0.7071, -4.2929).normalized(),
            normal: .vector(0, 0.7071, -0.7071)
        )

        XCTAssertEqual(c1, .rgb(0.9965, 0.9965, 0.9965))
        XCTAssertEqual(c2, .rgb(0.62318, 0.62318, 0.62318))
    }

    func test_lighting_pattern() {
        let material = Material.default(ambient: 1, diffuse: 0, specular: 0, pattern: .stripe(.white, .black))

        let c1 = material.lighting(
            at: .point(0.9, 0, 0),
            light: .pointLight(at: .point(0, 0, -10), intensity: .white),
            eyeVector: .vector(0, 0, -1),
            normal: .vector(0, 0, -1)
        )
        let c2 = material.lighting(
            at: .point(1.1, 0, 0),
            light: .pointLight(at: .point(0, 0, -10), intensity: .white),
            eyeVector: .vector(0, 0, -1),
            normal: .vector(0, 0, -1)
        )

        XCTAssertEqual(c1, .white)
        XCTAssertEqual(c2, .black)
    }
}
#endif
