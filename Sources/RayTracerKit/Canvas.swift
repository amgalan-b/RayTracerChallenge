import Foundation

public struct Canvas {

    let width: Int
    let height: Int

    private var _colorGrid: [[Color]]

    public init(width: Int, height: Int) {
        self._colorGrid = [[Color]](
            repeating: [Color](repeating: .black, count: height),
            count: width
        )

        self.width = width
        self.height = height
    }

    init(grid: [[Color]]) {
        self._colorGrid = grid
        self.width = grid.count
        self.height = grid[0].count
    }

    subscript(_ x: Int, _ y: Int) -> Color {
        get { _colorGrid[x][y] }
        set { _setColor(newValue, atX: x, y: y) }
    }

    private mutating func _setColor(_ color: Color, atX x: Int, y: Int) {
        guard x < width, x >= 0, y < height, y >= 0 else {
            fatalError()
        }

        _colorGrid[x][y] = color
    }
}

extension Canvas: Equatable {
}

#if TEST
import XCTest

final class CanvasTests: XCTestCase {

    func test_init() {
        let canvas = Canvas(width: 10, height: 20)

        XCTAssertEqual(canvas.width, 10)
        XCTAssertEqual(canvas.height, 20)

        for x in 0 ..< canvas.width {
            for y in 0 ..< canvas.height {
                XCTAssertEqual(canvas[x, y], .black)
            }
        }
    }

    func test_subscript() {
        var canvas = Canvas(width: 10, height: 20)
        canvas[2, 3] = .rgb(1, 0, 0)

        XCTAssertEqual(canvas[2, 3], .rgb(1, 0, 0))
    }
}
#endif
