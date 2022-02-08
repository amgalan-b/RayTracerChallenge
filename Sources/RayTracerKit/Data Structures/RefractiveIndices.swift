import Foundation

struct RefractiveIndices {

    let n1: Double
    let n2: Double

    func reflectanceSchlickApproximation(eyeVector: Vector, normalVector: Vector) -> Double {
        let cos = eyeVector.dotProduct(with: normalVector)
        let r0 = ((n1 - n2) / (n1 + n2)).pow(2)

        guard n1 > n2 else {
            return r0 + (1 - r0) * (1 - cos).pow(5)
        }

        let n = n1 / n2
        let sin2_t = n.pow(2) * (1 - cos.pow(2))

        if sin2_t > 1 {
            return 1
        }

        let cos_t = sqrt(1 - sin2_t)

        return r0 + (1 - r0) * (1 - cos_t).pow(5)
    }
}

extension RefractiveIndices: Equatable {
}

extension RefractiveIndices: ExpressibleByArrayLiteral {

    init(arrayLiteral elements: Double...) {
        assert(elements.count == 2)
        n1 = elements[0]
        n2 = elements[1]
    }
}

#if TEST
import XCTest

final class RefractiveIndicesTests: XCTestCase {

    func test_reflectance() {
        let indices = RefractiveIndices(n1: 1.5, n2: 1)
        let result = indices.reflectanceSchlickApproximation(
            eyeVector: Vector(0, -1, 0),
            normalVector: Vector(0, -1, 0)
        )

        XCTAssertEqual(result, 0.04, accuracy: .tolerance)
    }

    func test_reflectance_smallAngle() {
        let indices = RefractiveIndices(n1: 1, n2: 1.5)
        let result = indices.reflectanceSchlickApproximation(
            eyeVector: Vector(0, 0, -1),
            normalVector: Vector(0, 0.99, -0.1411)
        )

        XCTAssertEqual(result, 0.48873, accuracy: .tolerance)
    }
}
#endif
