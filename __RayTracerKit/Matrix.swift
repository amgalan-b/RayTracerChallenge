import Foundation
import simd

typealias Double4 = SIMD4<Double>

struct Matrix {

    private let _matrix: matrix_double4x4

    init(_ row1: Double4, _ row2: Double4, _ row3: Double4, _ row4: Double4) {
        _matrix = matrix_double4x4(rows: [row1, row2, row3, row4])
    }

    subscript(_ row: Int, _ column: Int) -> Double {
        return _matrix[column][row]
    }
}

extension Matrix: Equatable {
}

#if TEST
import XCTest

final class MatrixTests: XCTestCase {

    func test_matrix() {
        let matrix = Matrix([1, 2, 3, 4], [5.5, 6.5, 7.5, 8.5], [9, 19, 11, 12], [13.5, 14.5, 15.5, 16.5])

        XCTAssertEqual(matrix[0, 0], 1)
        XCTAssertEqual(matrix[0, 3], 4)
        XCTAssertEqual(matrix[1, 0], 5.5)
        XCTAssertEqual(matrix[1, 2], 7.5)
        XCTAssertEqual(matrix[2, 2], 11)
        XCTAssertEqual(matrix[3, 0], 13.5)
        XCTAssertEqual(matrix[3, 2], 15.5)
    }

    func test_equal() {
        let m1 = Matrix([1, 2, 3, 4], [5, 6, 7, 8], [9, 8, 7, 6], [5, 4, 3, 2])
        let m2 = Matrix([1, 2, 3, 4], [5, 6, 7, 8], [9, 8, 7, 6], [5, 4, 3, 2])

        XCTAssertEqual(m1, m2)
    }

    func test_equal_not() {
        let m1 = Matrix([1, 2, 3, 4], [5, 6, 7, 8], [9, 8, 7, 6], [5, 4, 3, 2])
        let m2 = Matrix([2, 3, 4, 5], [6, 7, 8, 9], [8, 7, 6, 5], [4, 3, 2, 1])

        XCTAssertNotEqual(m1, m2)
    }
}
#endif
