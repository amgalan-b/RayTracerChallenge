#if TEST
import XCTest

public func XCTAssertEqual<T>(
    _ left: T,
    _ right: T,
    accuracy: T.Element,
    file: StaticString = #filePath,
    line: UInt = #line
) where T: Collection, T.Element: FloatingPoint, T.Index == Int {
    guard left.count == right.count else {
        return XCTFail()
    }

    for i in 0 ..< left.count {
        XCTAssertEqual(left[i], right[i], accuracy: accuracy, file: file, line: line)
    }
}
#endif
