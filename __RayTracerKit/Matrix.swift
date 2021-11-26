import Foundation
import simd

typealias Double4 = SIMD4<Double>

public struct Matrix {

    private let _matrix: matrix_double4x4

    init(matrix: matrix_double4x4) {
        _matrix = matrix
    }

    init(_ row1: Double4, _ row2: Double4, _ row3: Double4, _ row4: Double4) {
        _matrix = matrix_double4x4(rows: [row1, row2, row3, row4])
    }

    subscript(_ row: Int, _ column: Int) -> Double {
        return _matrix[column][row]
    }

    func transposed() -> Matrix {
        return Matrix(matrix: simd_transpose(_matrix))
    }

    func inverted() -> Matrix {
        return Matrix(matrix: simd_inverse(_matrix))
    }
}

extension Matrix: Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return simd_almost_equal_elements(lhs._matrix, rhs._matrix, 0.00001)
    }
}

extension Matrix {

    public static func * (lhs: Self, rhs: Self) -> Self {
        return Matrix(matrix: lhs._matrix * rhs._matrix)
    }

    public static func * (lhs: Self, rhs: Tuple) -> Tuple {
        return Tuple(xyzw: lhs._matrix * rhs.xyzw)
    }
}

extension Matrix {

    public static let identity = Matrix([1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1])
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

    func test_multiply() {
        let m1 = Matrix([1, 2, 3, 4], [5, 6, 7, 8], [9, 8, 7, 6], [5, 4, 3, 2])
        let m2 = Matrix([-2, 1, 2, 3], [3, 2, 1, -1], [4, 3, 6, 5], [1, 2, 7, 8])
        let expected = Matrix([20, 22, 50, 48], [44, 54, 114, 108], [40, 58, 110, 102], [16, 26, 46, 42])

        XCTAssertEqual(m1 * m2, expected)
    }

    func test_multiply_tuple() {
        let matrix = Matrix([1, 2, 3, 4], [2, 4, 4, 2], [8, 6, 4, 1], [0, 0, 0, 1])
        let tuple = Tuple(1, 2, 3, 1)
        let expected = Tuple(18, 24, 33, 1)

        XCTAssertEqual(matrix * tuple, expected)
    }

    func test_multiply_identity() {
        let matrix = Matrix([0, 1, 2, 4], [1, 2, 4, 8], [2, 4, 8, 16], [4, 8, 16, 32])
        XCTAssertEqual(matrix * .identity, matrix)
    }

    func test_tranposed() {
        let matrix = Matrix([0, 9, 3, 0], [9, 8, 0, 8], [1, 8, 5, 3], [0, 0, 5, 8])
        let expected = Matrix([0, 9, 1, 0], [9, 8, 8, 0], [3, 0, 5, 5], [0, 8, 3, 8])

        XCTAssertEqual(matrix.transposed(), expected)
    }

    func test_tranposed_identity() {
        XCTAssertEqual(Matrix.identity.transposed(), .identity)
    }

    func test_inversed() {
        let matrix = Matrix([8, -5, 9, 2], [7, 5, 6, 1], [-6, 0, 9, 6], [-3, 0, -9, -4])
        let expected = Matrix(
            [-0.15385, -0.15385, -0.28205, -0.53846],
            [-0.07692, 0.12308, 0.02564, 0.03077],
            [0.35897, 0.35897, 0.43590, 0.92308],
            [-0.69231, -0.69231, -0.76923, -1.92308]
        )

        XCTAssertEqual(matrix.inverted(), expected)
    }

    func test_inversed_2() {
        let matrix = Matrix([9, 3, 0, 9], [-5, -2, -6, -3], [-4, 9, 6, 4], [-7, 6, 6, 2])
        let expected = Matrix(
            [-0.04074, -0.07778, 0.14444, -0.22222],
            [-0.07778, 0.03333, 0.36667, -0.33333],
            [-0.02901, -0.14630, -0.10926, 0.12963],
            [0.17778, 0.06667, -0.26667, 0.33333]
        )

        XCTAssertEqual(matrix.inverted(), expected)
    }

    func test_multiply_productWithInverse() {
        let m1 = Matrix([3, -9, 7, 3], [3, -8, 2, -9], [-4, 4, 4, 1], [-6, 5, -1, 1])
        let m2 = Matrix([8, 2, 2, 2], [3, -1, 7, 0], [7, 0, 5, 4], [6, -2, 0, 5])

        XCTAssertEqual((m1 * m2) * m2.inverted(), m1)
        XCTAssertEqual((m2 * m1) * m1.inverted(), m2)
    }
}
#endif
