import Foundation

extension Light {

    public static func pointLight(at position: Tuple, intensity: Color) -> Light {
        let pointLight = _PointLight(position: position, intensity: intensity)
        return Light(light: pointLight)
    }
}

private struct _PointLight: _Light {

    let position: Tuple
    let intensity: Color

    func intensity(at point: Tuple, isShadowed: (Tuple, Tuple) -> Bool) -> Double {
        if isShadowed(point, position) {
            return 0.0
        }

        return 1.0
    }
}
