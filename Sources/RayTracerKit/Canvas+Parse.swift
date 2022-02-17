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

        print("reading ppm", to: &standardError)
        let scale = Double(ppm._popLine()!)!

        var colors = [Color]()
        var double = ""
        var numbers = [Double]()
        var isComment = false
        for character in ppm {
            guard !isComment else {
                isComment = !character.isNewline
                continue
            }

            guard character != "#" else {
                isComment = true
                continue
            }

            guard character.isWhitespace else {
                double.append(character)
                continue
            }

            guard !double.isEmpty else {
                continue
            }

            numbers.append(Double(double)! / scale)
            double = ""

            guard numbers.count == 3 else {
                continue
            }

            colors.append(.rgb(numbers[0], numbers[1], numbers[2]))
            numbers = []
        }
        print("reading line", to: &standardError)

        for (index, color) in colors.enumerated() {
            let x = index % width
            let y = index / width

            self[x, y] = color
        }
        print("done ppm", to: &standardError)
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

    func test_parsePPM_performance() throws {
        let fileLocation = "/Users/amgalan/Projects/RayTracerChallenge/Sources/RayTracerChallenge/Scenes/negx.ppm"
        let content = try String(contentsOfFile: fileLocation)
        let canvas = Canvas(ppm: content)
    }
}
#endif
