import Foundation

extension Light {

    public static func pointLight(at position: Point, intensity: Color) -> Light {
        let pointLight = _PointLight(position: position, intensity: intensity, samples: [position])
        return Light(light: pointLight)
    }
}

private struct _PointLight: _Light {

    let position: Point
    let intensity: Color
    let samples: [Point]

    func shadowIntensity(at point: Point, isShadowed: (Point, Point) -> Bool) -> Double {
        if isShadowed(point, position) {
            return 1.0
        }

        return 0.0
    }
}
