import Foundation

extension World {

    func _reflectedColor(
        at position: Tuple,
        reflective: Double,
        reflectionVector: Tuple,
        recursionLimit: Int
    ) -> Color {
        guard recursionLimit > 0 else {
            return .black
        }

        guard reflective > 0 else {
            return .black
        }

        let reflectedRay = Ray(origin: position, direction: reflectionVector)
        let color = color(for: reflectedRay, recursionLimit: recursionLimit - 1)

        return color * reflective
    }
}
