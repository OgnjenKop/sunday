import XCTest
@testable import Sunday

final class VitaminDCalculatorTests: XCTestCase {
    func testClothingExposureFactor() {
        XCTAssertEqual(ClothingLevel.none.exposureFactor, 1.0)
        XCTAssertEqual(ClothingLevel.heavy.exposureFactor, 0.10, accuracy: 0.0001)
    }

    func testSunscreenTransmissionFactor() {
        XCTAssertEqual(SunscreenLevel.spf30.uvTransmissionFactor, 0.03, accuracy: 0.0001)
        XCTAssertEqual(SunscreenLevel.spf100.uvTransmissionFactor, 0.01, accuracy: 0.0001)
    }

    func testSkinTypeVitaminDFactor() {
        XCTAssertEqual(SkinType.type1.vitaminDFactor, 1.25, accuracy: 0.0001)
        XCTAssertEqual(SkinType.type6.vitaminDFactor, 0.2, accuracy: 0.0001)
    }
}
