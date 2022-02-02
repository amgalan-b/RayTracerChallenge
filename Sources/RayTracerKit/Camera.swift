import Babbage
import Foundation

/// Canvas is always 1-unit away from the camera.
public struct Camera: Equatable {

    let width: Int
    let height: Int
    let fieldOfView: Double
    let transform: Matrix

    let halfWidth: Double
    let halfHeight: Double
    let pixelSize: Double

    public init(width: Int, height: Int, fieldOfView: Double, transform: Matrix = .identity) {
        self.width = width
        self.height = height
        self.fieldOfView = fieldOfView
        self.transform = transform

        let halfView = tan(fieldOfView / 2)
        let aspectRatio = Double(width) / Double(height)

        if aspectRatio >= 1 {
            self.halfWidth = halfView
            self.halfHeight = halfView / aspectRatio
        } else {
            self.halfWidth = halfView * aspectRatio
            self.halfHeight = halfView
        }

        self.pixelSize = (self.halfWidth * 2) / Double(self.width)
    }

    public func render(world: World) -> Canvas {
        var canvas = Canvas(width: width, height: height)

        for x in 0 ..< width {
            let start = CFAbsoluteTimeGetCurrent()
            for y in 0 ..< height {
                let ray = _ray(forPixelAtX: x, y: y)
                let color = world.color(for: ray)

                canvas[x, y] = color
            }
            let diff = CFAbsoluteTimeGetCurrent() - start
            let output = String(format: "%.3f seconds", diff)
            print("Column: \(x) \(output)", to: &standardError)
        }

        return canvas
    }

    public func renderParallel(world: World) async -> Canvas {
        let colorGrid = await withTaskGroup(
            of: (column: Int, colors: [Color]).self,
            returning: [[Color]].self
        ) { group in
            for x in 0 ..< width {
                group.addTask {
                    let start = CFAbsoluteTimeGetCurrent()
                    var column = [Color]()
                    for y in 0 ..< height {
                        let ray = _ray(forPixelAtX: x, y: y)
                        let color = world.color(for: ray)

                        column.append(color)
                    }

                    let diff = CFAbsoluteTimeGetCurrent() - start
                    let output = String(format: "%.3f seconds", diff)
                    print("Column: \(x) \(output)", terminator: "\r", to: &standardError)
                    return (x, column)
                }
            }


            var matrix = [[Color]](repeating: [], count: width)
            for await taskResult in group {
                matrix[taskResult.column] = taskResult.colors
            }
            print("", to: &standardError)

            return matrix
        }

        return Canvas(grid: colorGrid)
    }

    fileprivate func _ray(forPixelAtX x: Int, y: Int) -> Ray {
        let offsetX = (Double(x) + 0.5) * pixelSize
        let offsetY = (Double(y) + 0.5) * pixelSize

        let worldX = halfWidth - offsetX
        let worldY = halfHeight - offsetY

        let pixel = transform.inversed() * Point(worldX, worldY, -1)
        let origin = transform.inversed() * Point(0, 0, 0)
        let direction = (pixel - origin).normalized()

        return Ray(origin: origin, direction: direction)
    }
}

#if TEST
import XCTest

final class CameraTests: XCTestCase {

    func test_pixelSize_horizontal() {
        let camera = Camera(width: 200, height: 125, fieldOfView: .pi / 2)
        XCTAssertEqual(camera.pixelSize, 0.01, accuracy: .tolerance)
    }

    func test_pixelSize_vertical() {
        let camera = Camera(width: 125, height: 200, fieldOfView: .pi / 2)
        XCTAssertEqual(camera.pixelSize, 0.01, accuracy: .tolerance)
    }

    func test_ray_canvasCenter() {
        let camera = Camera(width: 201, height: 101, fieldOfView: .pi / 2)
        let ray = camera._ray(forPixelAtX: 100, y: 50)
        let expected = Ray(origin: Point(0, 0, 0), direction: Vector(0, 0, -1))

        XCTAssertEqual(ray, expected)
    }

    func test_ray_canvasCorner() {
        let camera = Camera(width: 201, height: 101, fieldOfView: .pi / 2)
        let ray = camera._ray(forPixelAtX: 0, y: 0)
        let expected = Ray(origin: Point(0, 0, 0), direction: Vector(0.66519, 0.33259, -0.66851))

        XCTAssertEqual(ray, expected)
    }

    func test_ray_transformedCamera() {
        let camera = Camera(
            width: 201,
            height: 101,
            fieldOfView: .pi / 2,
            transform: .rotationY(.pi / 4) * .translation(0, -2, 5)
        )

        let ray = camera._ray(forPixelAtX: 100, y: 50)
        let expected = Ray(origin: Point(0, 2, -5), direction: Vector(1, 0, -1).normalized())

        XCTAssertEqual(ray, expected)
    }
}
#endif
