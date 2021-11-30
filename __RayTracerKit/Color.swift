import simd

public struct Color {

    private let _rgb: SIMD3<Double>

    init(rgb: SIMD3<Double>) {
        _rgb = rgb
    }

    init(red: Double, green: Double, blue: Double) {
        _rgb = [red, green, blue]
    }

    var red: Double {
        return _rgb[0]
    }

    var green: Double {
        return _rgb[1]
    }

    var blue: Double {
        return _rgb[2]
    }
}

extension Color: Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs._rgb.x.isAlmostEqual(to: rhs._rgb.x, tolerance: .tolerance)
            && lhs._rgb.y.isAlmostEqual(to: rhs._rgb.y, tolerance: .tolerance)
            && lhs._rgb.z.isAlmostEqual(to: rhs._rgb.z, tolerance: .tolerance)
    }
}

extension Color {

    public static let white = Color(red: 1, green: 1, blue: 1)
    public static let black = Color(red: 0, green: 0, blue: 0)

    public static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Self {
        return Color(red: red, green: green, blue: blue)
    }
}

extension Color {

    static func + (lhs: Self, rhs: Self) -> Self {
        return Color(rgb: lhs._rgb + rhs._rgb)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        return Color(rgb: lhs._rgb - rhs._rgb)
    }

    static func * (lhs: Self, scalar: Double) -> Self {
        return Color(rgb: lhs._rgb * scalar)
    }

    static func * (lhs: Self, rhs: Self) -> Self {
        return Color(rgb: lhs._rgb * rhs._rgb)
    }

    static func / (lhs: Self, scalar: Double) -> Self {
        return Color(rgb: lhs._rgb / scalar)
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

    func test_divide_scalar() {
        let color = Color(red: 1, green: 1, blue: 0.5)
        XCTAssertEqual(color / 2, .rgb(0.5, 0.5, 0.25))
    }
}
#endif
