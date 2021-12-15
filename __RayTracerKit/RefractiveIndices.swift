import Foundation

struct RefractiveIndices {

    let n1: Double
    let n2: Double

    func reflectanceSchlickApproximation(eyeVector: Tuple, normalVector: Tuple) -> Double {
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
