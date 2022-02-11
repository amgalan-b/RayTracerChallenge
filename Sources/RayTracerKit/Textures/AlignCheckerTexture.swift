import Foundation

extension Texture {

    static func alignChecker(_ main: Color, _ ul: Color, _ ur: Color, _ bl: Color, _ br: Color) -> Texture {
        let texture = AlignCheckerTexture(main, ul, ur, bl, br)
        return .alignChecker(texture)
    }
}

struct AlignCheckerTexture: TextureProtocol {

    fileprivate let _main: Color
    fileprivate let _ul: Color
    fileprivate let _ur: Color
    fileprivate let _bl: Color
    fileprivate let _br: Color

    init(_ main: Color, _ ul: Color, _ ur: Color, _ bl: Color, _ br: Color) {
        self._main = main
        self._ul = ul
        self._ur = ur
        self._bl = bl
        self._br = br
    }

    func color(at point: Point2D) -> Color {
        switch point {
        case _ where point.u < 0.2 && point.v > 0.8:
            return _ul
        case _ where point.u > 0.8 && point.v > 0.8:
            return _ur
        case _ where point.u < 0.2 && point.v < 0.2:
            return _bl
        case _ where point.u > 0.8 && point.v < 0.2:
            return _br
        default:
            return _main
        }
    }
}

#if TEST
import XCTest

extension UVPatternTests {

    func test_alignChecker() {
        let texture = AlignCheckerTexture(.white, .rgb(1, 0, 0), .rgb(1, 1, 0), .rgb(0, 1, 0), .rgb(0, 1, 1))

        XCTAssertEqual(texture.color(at: Point2D(0.5, 0.5)), texture._main)
        XCTAssertEqual(texture.color(at: Point2D(0.1, 0.9)), texture._ul)
        XCTAssertEqual(texture.color(at: Point2D(0.9, 0.9)), texture._ur)
        XCTAssertEqual(texture.color(at: Point2D(0.1, 0.1)), texture._bl)
        XCTAssertEqual(texture.color(at: Point2D(0.9, 0.1)), texture._br)
    }
}
#endif
