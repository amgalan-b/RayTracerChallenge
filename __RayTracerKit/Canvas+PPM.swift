import Babbage
import Foundation

extension Canvas {

    public func ppm() -> String {
        return _ppmHeader() + "\n" + _ppmBody() + "\n"
    }

    fileprivate func _ppmHeader() -> String {
        """
        P3
        \(width) \(height)
        255
        """
    }

    fileprivate func _ppmBody() -> String {
        var result = ""
        for column in colorGrid {
            for color in column {
                result += color._encoded()
                result += " "
            }
        }
        result.removeLast()

        return result
    }
}

extension Color {

    fileprivate func _encoded() -> String {
        return "\(rgb[0]._string()) \(rgb[1]._string()) \(rgb[2]._string())"
    }
}

extension Double {

    fileprivate func _string() -> String {
        return (self * 255)
            .rounded()
            .run { Int($0) }
            .clamped(to: 0 ... 255)
            .run { String($0) }
    }
}

#if TEST
import XCTest

extension CanvasTests {

    func test_ppmHeader() {
        let canvas = Canvas(width: 5, height: 3)
        let expected = """
        P3
        5 3
        255
        """

        XCTAssertEqual(canvas._ppmHeader(), expected)
    }

    func test_ppmBody() {
        var canvas = Canvas(width: 5, height: 3)
        canvas[0, 0] = .rgb(1.5, 0, 0)
        canvas[2, 1] = .rgb(0, 0.5, 0)
        canvas[4, 2] = .rgb(-0.5, 0, 1)

        let expected = "255 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 128 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 255"
        let body = canvas._ppmBody()

        XCTAssertEqual(body, expected)
    }

    func test_ppmEnding() {
        let canvas = Canvas(width: 5, height: 3)
        let ppm = canvas.ppm()

        XCTAssert(ppm.last!.isNewline)
    }

    func test_ppmPerformance() {
        measure {
            let canvas = Canvas(width: 800, height: 800)
            _ = canvas.ppm()
        }
    }
}
#endif
