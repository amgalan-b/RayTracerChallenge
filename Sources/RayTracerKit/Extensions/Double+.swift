import Foundation

extension Double {

    static let tolerance = 0.00001

    func modulo(dividingBy rhs: Double) -> Double {
        let remainder = truncatingRemainder(dividingBy: rhs)
        guard remainder >= 0 else {
            return remainder + rhs
        }

        return remainder
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
