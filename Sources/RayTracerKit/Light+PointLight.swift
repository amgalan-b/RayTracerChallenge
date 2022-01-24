import Foundation

extension Light {

    public static func pointLight(at position: Tuple, intensity: Color) -> Light {
        let pointLight = _PointLight(position: position, intensity: intensity, samples: [position])
        return Light(light: pointLight)
    }
}

private struct _PointLight: _Light {

    let position: Tuple
    let intensity: Color
    let samples: [Tuple]

    func shadowIntensity(at point: Tuple, isShadowed: (Tuple, Tuple) -> Bool) -> Double {
        if isShadowed(point, position) {
            return 1.0
        }

        return 0.0
    }
}
