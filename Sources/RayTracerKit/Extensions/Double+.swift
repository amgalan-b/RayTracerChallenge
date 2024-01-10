import Foundation

extension Double {

    static let tolerance = 0.00001

    var absoluteValue: Self {
        return abs(self)
    }

    func modulo(dividingBy rhs: Double) -> Double {
        let remainder = truncatingRemainder(dividingBy: rhs)
        guard remainder >= 0 else {
            return remainder + rhs
        }

        return remainder
    }

    func pow(_ exponent: Self) -> Self {
        return Darwin.pow(self, exponent)
    }

    func isAlmostEqual(to other: Self, tolerance: Double = 0.0001) -> Bool {
        return abs(self - other) < tolerance
    }

    func floor() -> Self {
        return Darwin.floor(self)
    }
}

extension Comparable {

    /// Returns a value within `range` as close to the current value.
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

extension SIMD4 {

    var xyz: SIMD3<Scalar> {
        return SIMD3(x, y, z)
    }
}

#if TEST
import XCTest

final class DoubleTests: XCTestCase {

    func test_remainder() {
        XCTAssertEqual((-0.25).truncatingRemainder(dividingBy: 1), -0.25)
        XCTAssertEqual((-0.25).remainder(dividingBy: 1), -0.25)
        XCTAssertEqual(fmod(-0.25, 1), -0.25)
        XCTAssertEqual((-0.25).modulo(dividingBy: 1), 0.75)
    }
}
#endif
