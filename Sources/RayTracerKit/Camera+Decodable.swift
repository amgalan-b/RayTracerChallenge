import Foundation

extension Camera: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)

        self.init(
            width: try container.decode(Int.self, forKey: .width),
            height: try container.decode(Int.self, forKey: .height),
            fieldOfView: try container.decode(Double.self, forKey: .fieldOfView),
            transform: .viewTransform(
                origin: try container.decode(Point.self, forKey: .origin),
                target: try container.decode(Point.self, forKey: .target),
                orientation: try container.decode(Vector.self, forKey: .orientation)
            )
        )
    }

    private enum _CodingKeys: String, CodingKey {

        case width
        case height
        case fieldOfView = "field_of_view"
        case origin = "from"
        case target = "to"
        case orientation = "up"
    }
}

#if TEST
import XCTest
import Yams

extension CameraTests {

    func test_decode_camera() {
        let content = """
        add: camera
        width: 400
        height: 300
        field_of_view: 1.047
        from: [0, 1.5, -5]
        to: [0, 1, 0]
        up: [0, 1, 0]
        """

        let decoder = YAMLDecoder()
        let cameras = try! decoder.decode(Camera.self, from: content)
        let expected = Camera(
            width: 400,
            height: 300,
            fieldOfView: 1.047,
            transform: .viewTransform(
                origin: Point(0, 1.5, -5),
                target: Point(0, 1, 0),
                orientation: Vector(0, 1, 0)
            )
        )

        XCTAssertEqual(cameras, expected)
    }
}
#endif
