import CoreGraphics
import Testing

@testable import Pane

struct LayoutTests {
    static let directions: [(CGVector, Layout)] = [
        (CGVector(dx: -120, dy: 0), .leftHalf),
        (CGVector(dx: 120, dy: 0), .rightHalf),
        (CGVector(dx: 0, dy: 120), .maximize),
        (CGVector(dx: 0, dy: -120), .minimize),
        (CGVector(dx: -120, dy: 120), .topLeft),
        (CGVector(dx: 120, dy: 120), .topRight),
        (CGVector(dx: -120, dy: -120), .bottomLeft),
        (CGVector(dx: 120, dy: -120), .bottomRight),
    ]

    @Test(arguments: directions)
    func picksTheLayoutTheFingersPointAt(travel: CGVector, expected: Layout) {
        #expect(Layout(travel: travel) == expected)
    }

    @Test func waitsForTheThreshold() {
        #expect(Layout(travel: CGVector(dx: Config.Gesture.threshold - 1, dy: 0)) == nil)
        #expect(Layout(travel: CGVector(dx: Config.Gesture.threshold, dy: 0)) == .rightHalf)
    }

    @Test func toleratesDriftBeforeGoingDiagonal() {
        #expect(Layout(travel: CGVector(dx: -200, dy: 60)) == .leftHalf)
        #expect(Layout(travel: CGVector(dx: -200, dy: 120)) == .topLeft)
    }

    @Test func dividesTheVisibleFrameWithoutGaps() {
        let visible = CGRect(x: 100, y: 40, width: 1001, height: 701)
        #expect(Layout.leftHalf.frame(in: visible) == CGRect(x: 100, y: 40, width: 501, height: 701))
        #expect(Layout.rightHalf.frame(in: visible) == CGRect(x: 601, y: 40, width: 500, height: 701))
        #expect(Layout.topLeft.frame(in: visible) == CGRect(x: 100, y: 391, width: 501, height: 350))
        #expect(Layout.bottomRight.frame(in: visible) == CGRect(x: 601, y: 40, width: 500, height: 351))
        #expect(Layout.maximize.frame(in: visible) == visible)
    }
}

struct GeometryTests {
    @Test func flippingTwiceGivesBackTheFrame() {
        let frame = CGRect(x: 1710, y: -270, width: 960, height: 478)
        #expect(Screens.flip(Screens.flip(frame)) == frame)
    }

    @Test func framesMatchWithinTolerance() {
        let frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        #expect(frame.isClose(to: frame.offsetBy(dx: 9, dy: -9)))
        #expect(!frame.isClose(to: frame.insetBy(dx: 0, dy: -10)))
    }
}
