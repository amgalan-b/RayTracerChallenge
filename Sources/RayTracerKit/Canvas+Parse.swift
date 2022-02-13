import Foundation

extension Canvas {

    init?(ppm: String) {
        let lines = ppm.split(whereSeparator: \.isNewline)
            .filter { $0.count > 1 && !$0.hasPrefix("#") }

        guard lines[0] == "P3" else {
            return nil
        }

        let (width, height) = lines[1]
            .split(whereSeparator: \.isWhitespace)
            .map { Int($0)! }
            .run { ($0[0], $0[1]) }

        self.init(width: width, height: height)

        let scale = Double(lines[2])!
        let colors = lines[3...]
            .reduce1 { $0 + " " + $1 }!
            .split(whereSeparator: \.isWhitespace)
            .map { Double($0)! / scale }
            ._parseColors()

        for (index, color) in colors.enumerated() {
            let x = index % width
            let y = index / width

            self[x, y] = color
        }
    }
}

extension Array where Element == Double {

    fileprivate func _parseColors() -> [Color] {
        var colors = self
        var result = [Color]()
        while !colors.isEmpty {
            let r = colors.removeFirst()
            let g = colors.removeFirst()
            let b = colors.removeFirst()

            result.append(.rgb(r, g, b))
        }

        return result
    }
}

extension String {

    mutating func popLine() -> String? {
        guard let index = firstIndex(where: \.isNewline) else {
            return self
        }

        let substring = self[startIndex ..< index]
        removeSubrange(startIndex ... index)

        return String(substring)
    }
}

#if TEST
import XCTest

extension CanvasTests {

    func test_parsePPM_fail() {
        let content = """
        P32
        1 1
        255
        0 0 0
        """

        let canvas = Canvas(ppm: content)
        XCTAssertNil(canvas)
    }

    func test_parsePPM_default() {
        let content = """
        P3
        10 2
        255
        0 0 0  0 0 0  0 0 0  0 0 0  0 0 0
        0 0 0  0 0 0  0 0 0  0 0 0  0 0 0
        0 0 0  0 0 0  0 0 0  0 0 0  0 0 0
        0 0 0  0 0 0  0 0 0  0 0 0  0 0 0
        """

        let canvas = Canvas(ppm: content)
        let expected = Canvas(width: 10, height: 2)

        XCTAssertEqual(canvas, expected)
    }

    func test_parsePPM() {
        let content = """
        P3
        4 3
        255
        255 127 0  0 127 255  127 255 0  255 255 255
        0 0 0  255 0 0  0 255 0  0 0 255
        255 255 0  0 255 255  255 0 255  127 127 127
        """

        let canvas = Canvas(ppm: content)
        let expected = Canvas(grid: [
            [.rgb(1, 0.49804, 0), .rgb(0, 0, 0), .rgb(1, 1, 0)],
            [.rgb(0, 0.49804, 1), .rgb(1, 0, 0), .rgb(0, 1, 1)],
            [.rgb(0.49804, 1, 0), .rgb(0, 1, 0), .rgb(1, 0, 1)],
            [.rgb(1, 1, 1), .rgb(0, 0, 1), .rgb(0.49804, 0.49804, 0.49804)],
        ])

        XCTAssertEqual(canvas, expected)
    }

    func test_parsePPM_ignoreComment() {
        let content = """
        P3
        # this is a comment
        2 1
        # this, too
        255
        # another comment
        255 255 255
        # oh, no, comments in the pixel data!
        255 0 255
        """

        let canvas = Canvas(ppm: content)
        let expected = Canvas(grid: [
            [.rgb(1, 1, 1)],
            [.rgb(1, 0, 1)],
        ])

        XCTAssertEqual(canvas, expected)
    }
}
#endif
