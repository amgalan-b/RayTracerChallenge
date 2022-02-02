import Foundation

extension Matrix: Decodable {

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let type = try container.decode(String.self)
        var values = [Double]()
        while !container.isAtEnd {
            let value = try container.decode(Double.self)
            values.append(value)
        }

        switch type {
        case "translate":
            assert(values.count == 3)
            self = .translation(values[0], values[1], values[2])
        case "scale":
            assert(values.count == 3)
            self = .scaling(values[0], values[1], values[2])
        case "rotate-x":
            assert(values.count == 1)
            self = .rotationX(values[0])
        case "rotate-y":
            assert(values.count == 1)
            self = .rotationY(values[0])
        case "rotate-z":
            assert(values.count == 1)
            self = .rotationZ(values[0])
        default:
            fatalError()
        }
    }
}

#if TEST
import XCTest
import Yams

extension MatrixTests {

    func test_decode() {
        let decoder = YAMLDecoder()
        let c1 = "[translate, 0, 0, 500]"
        let c2 = "[scale, 2, 2, 2]"
        let c3 = "[rotate-x, 1.5707963267948966]"

        let m1 = try! decoder.decode(Matrix.self, from: c1)
        let m2 = try! decoder.decode(Matrix.self, from: c2)
        let m3 = try! decoder.decode(Matrix.self, from: c3)

        XCTAssertEqual(m1, .translation(0, 0, 500))
        XCTAssertEqual(m2, .scaling(2, 2, 2))
        XCTAssertEqual(m3, .rotationX(1.570796))
    }
}
#endif
