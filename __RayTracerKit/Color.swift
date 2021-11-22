import simd

struct Color {

    private let _rgb: SIMD3<Double>

    init(rgb: SIMD3<Double>) {
        _rgb = rgb
    }

    init(red: Double, green: Double, blue: Double) {
        _rgb = [red, green, blue]
    }

    var rgb: SIMD3<Double> {
        return _rgb
    }
}

extension Color: Equatable {

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.rgb.x.isAlmostEqual(to: rhs.rgb.x)
            && lhs.rgb.y.isAlmostEqual(to: rhs.rgb.y)
            && lhs.rgb.z.isAlmostEqual(to: rhs.rgb.z)
    }
}

extension Color {

    static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Self {
        return Color(red: red, green: green, blue: blue)
    }
}

extension Color {

    static func + (lhs: Self, rhs: Self) -> Self {
        return Color(rgb: lhs.rgb + rhs.rgb)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        return Color(rgb: lhs.rgb - rhs.rgb)
    }

    static func * (lhs: Self, scalar: Double) -> Self {
        return Color(rgb: lhs.rgb * scalar)
    }

    static func * (lhs: Self, rhs: Self) -> Self {
        return Color(rgb: lhs.rgb * rhs.rgb)
    }
}

#if TEST
import XCTest

final class ColorTests: XCTestCase {

    func test_add() {
        let c1 = Color(red: 0.9, green: 0.6, blue: 0.75)
        let c2 = Color(red: 0.7, green: 0.1, blue: 0.25)

        XCTAssertEqual(c1 + c2, .rgb(1.6, 0.7, 1.0))
    }

    func test_subtract() {
        let c1 = Color(red: 0.9, green: 0.6, blue: 0.75)
        let c2 = Color(red: 0.7, green: 0.1, blue: 0.25)

        XCTAssertEqual(c1 - c2, .rgb(0.2, 0.5, 0.5))
    }

    func test_multiply_scalar() {
        let color = Color(red: 0.2, green: 0.3, blue: 0.4)
        XCTAssertEqual(color * 2, .rgb(0.4, 0.6, 0.8))
    }

    func test_multiply() {
        let c1 = Color(red: 1, green: 0.2, blue: 0.4)
        let c2 = Color(red: 0.9, green: 1, blue: 0.1)

        XCTAssertEqual(c1 * c2, .rgb(0.9, 0.2, 0.04))
    }
}
#endif
