import CoreGraphics
import Testing

@testable import Pane

struct LayoutTests {
    static let threshold = Config.Gesture.threshold

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
        #expect(Layout(travel: travel, threshold: Self.threshold) == expected)
    }

    @Test func waitsForTheThreshold() {
        #expect(Layout(travel: CGVector(dx: Self.threshold - 1, dy: 0), threshold: Self.threshold) == nil)
        #expect(Layout(travel: CGVector(dx: Self.threshold, dy: 0), threshold: Self.threshold) == .rightHalf)
        #expect(Layout(travel: CGVector(dx: 60, dy: 0), threshold: 80) == nil)
    }

    @Test func toleratesDriftBeforeGoingDiagonal() {
        #expect(Layout(travel: CGVector(dx: -200, dy: 60), threshold: Self.threshold) == .leftHalf)
        #expect(Layout(travel: CGVector(dx: -200, dy: 120), threshold: Self.threshold) == .topLeft)
    }

    @Test func dividesTheVisibleFrameWithoutGaps() {
        let visible = CGRect(x: 100, y: 40, width: 1001, height: 701)
        #expect(Layout.leftHalf.frame(in: visible) == CGRect(x: 100, y: 40, width: 501, height: 701))
        #expect(Layout.rightHalf.frame(in: visible) == CGRect(x: 601, y: 40, width: 500, height: 701))
        #expect(Layout.topLeft.frame(in: visible) == CGRect(x: 100, y: 391, width: 501, height: 350))
        #expect(Layout.bottomRight.frame(in: visible) == CGRect(x: 601, y: 40, width: 500, height: 351))
        #expect(Layout.maximize.frame(in: visible) == visible)
    }

    @Test func thirdsTileTheWidth() {
        let visible = CGRect(x: 0, y: 93, width: 1710, height: 981)
        #expect(Layout.leftThird.frame(in: visible) == CGRect(x: 0, y: 93, width: 570, height: 981))
        #expect(Layout.rightTwoThirds.frame(in: visible) == CGRect(x: 570, y: 93, width: 1140, height: 981))
        #expect(Layout.leftTwoThirds.frame(in: visible).maxX == Layout.rightThird.frame(in: visible).minX)
    }

    @Test func swipingTheSameWayStepsThroughWidths() {
        let visible = CGRect(x: 0, y: 93, width: 1710, height: 981)
        var frame = Layout.leftHalf.frame(in: visible)
        var widths: [Layout] = []
        for _ in 0..<3 {
            guard let next = Layout.leftHalf.nextWidth(after: frame, in: visible) else { break }
            widths.append(next)
            frame = next.frame(in: visible)
        }
        #expect(widths == [.leftTwoThirds, .leftThird, .leftHalf])
        #expect(Layout.rightHalf.nextWidth(after: Layout.rightHalf.frame(in: visible), in: visible) == .rightTwoThirds)
    }

    @Test func aWindowAwayFromTheEdgeSnapsToTheHalf() {
        let visible = CGRect(x: 0, y: 93, width: 1710, height: 981)
        let floating = CGRect(x: 300, y: 200, width: 900, height: 560)
        #expect(Layout.leftHalf.nextWidth(after: floating, in: visible) == nil)
        #expect(Layout.maximize.nextWidth(after: visible, in: visible) == nil)
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
