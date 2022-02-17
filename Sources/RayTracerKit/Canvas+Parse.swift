import Babbage
import Foundation

extension Canvas {

    init?(ppm: String) {
        var ppm = ppm
        guard ppm._popLine() == "P3" else {
            return nil
        }

        let (width, height) = ppm._popLine()!
            .split(whereSeparator: \.isWhitespace)
            .map { Int($0)! }
            .run { ($0[0], $0[1]) }

        self.init(width: width, height: height)

        let scale = Double(ppm._popLine()!)!
        var totalColors = [Color]()
        var currentRawColorValues = ""
        var currentColorValues = [Double]()
        var isComment = false
        for index in ppm.indices {
            let character = ppm[index]
            guard !isComment else {
                isComment = !character.isNewline
                continue
            }

            guard character != "#" else {
                isComment = true
                continue
            }

            guard !character.isWhitespace else {
                continue
            }

            currentRawColorValues.append(character)
            let nextIndex = ppm.index(after: index)
            guard nextIndex == ppm.endIndex || ppm[nextIndex].isWhitespace else {
                continue
            }

            currentColorValues.append(Double(currentRawColorValues)! / scale)
            currentRawColorValues = ""

            guard currentColorValues.count == 3 else {
                continue
            }

            totalColors.append(.rgb(currentColorValues[0], currentColorValues[1], currentColorValues[2]))
            currentColorValues = []
        }

        for (index, color) in totalColors.enumerated() {
            let x = index % width
            let y = index / width

            self[x, y] = color
        }
    }
}

extension String {

    fileprivate mutating func _popLine() -> Substring? {
        while let line = popLine() {
            if line.count > 1, !line.hasPrefix("#") {
                return line
            }
        }

        return nil
    }
}

extension Array where Element == Double {

    /// - Note: Instead of using a stack, we are reversing the array and popping last elements.
    fileprivate func _parseColors() -> ReversedCollection<[Color]> {
        var colors = self
        var result = [Color]()
        while !colors.isEmpty {
            let b = colors.popLast()!
            let g = colors.popLast()!
            let r = colors.popLast()!

            result.append(.rgb(r, g, b))
        }

        return result.reversed()
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
