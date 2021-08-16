import SwiftUI
import PureSwiftUI

private let dotSize = 8
private let maxOffset = UIScreen.mainWidthScaled(0.5) + dotSize.asCGFloat
private let numDots = 5
private let controlPointSize: CGFloat = 10
private let gridCoordName = "grid-coord"

struct ContentView: View {
    @State private var cp0 = CGPoint(x: 0.4, y: 0.4)
    @State private var cp1 = CGPoint(x: 0.6, y: 0.6)

    @State private var animating = [Bool](repeating: false, count: numDots)
    @State private var change = false

    var body: some View {
        contentWithColorChange(duration: 1)
    }

    func contentWithColorChange(duration: Double) -> some View {
        let customTimingCurve = CustomTimingCurve(cp0: $cp0, cp1: $cp1)
        return ZStack {
            Color.blue.ignoresSafeArea()
            HStack(spacing: 0) {
                Color.green.ignoresSafeArea()
                    .offset(x: change ? -UIScreen.main.width : 0)
                    .animation(customTimingCurve.generate(duration: duration))
            }

            VStack {
                customTimingCurve.asView(200)
            }
        }
        .onAppear {
            every(duration) { _ in
                change.toggle()
            }
        }
    }

    func contentWithDots(duration: Double) -> some View {
        let customTimingCurve = CustomTimingCurve(cp0: $cp0, cp1: $cp1)
        return ZStack {
            Color.blue.ignoresSafeArea()

            VStack {
                CustomText("InLook", 80, .white)
                ZStack {
                    ForEach(0..<numDots) { index in
                        Circle()
                            .fillColor(.white)
                            .frame(dotSize.asCGFloat)
                            .xOffset(animating[index] ? maxOffset : -maxOffset)
                            .onAppear {
                                after(index.asDouble * 0.2) {
                                    every(duration) { timer in
                                        self.animating[index] = false
                                        withAnimation(customTimingCurve.generate(duration: duration)) {
                                            animating[index] = true
                                        }
                                    }
                                }
                            }
                    }
                }
                customTimingCurve.asView(200)
            }
        }
        .onAppear {
            every(duration) { _ in
                change.toggle()
            }
        }
    }
}

struct CustomTimingCurve {
    @Binding var cp0: CGPoint
    @Binding var cp1: CGPoint

    func asView(_ size: CGFloat) -> some View {
        let cp0Mapped = mapFromUnitPoint(cp0, to: size)
        let cp1Mapped = mapFromUnitPoint(cp1, to: size)
        return VStack {
            ZStack {
                CustomTimingCurveShape(cp0Mapped: cp0Mapped, cp1Mapped: cp1Mapped)
                    .stroke(Color.white, lineWidth: 2)
                    .layoutGuide(.grid(columns: 10, rows: 10), color: .white)
                    .showLayoutGuides(true)
                CustomTimingCurveView(cp0Mapped: cp0Mapped, cp1Mapped: cp1Mapped, cp0: $cp0, cp1: $cp1)
            }
            .coordinateSpace(name: gridCoordName)
            .frame(size)
            textForPoint(cp0, name: "CP0")
            textForPoint(cp1, name: "CP1")
        }
    }

    func generate(duration: Double = 0.35) -> Animation {
        Animation.timingCurve(cp0.x.asDouble, cp0.y.asDouble, cp1.x.asDouble, cp1.y.asDouble, duration: duration)
    }
}

struct CustomTimingCurveShape: Shape {

    let cp0Mapped: CGPoint
    let cp1Mapped: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(rect.bottomLeading)
        path.curve(rect.topTrailing, cp1: cp0Mapped, cp2: cp1Mapped, showControlPoints: true)
        return path
    }

}

private struct CustomTimingCurveView: View {

    let cp0Mapped: CGPoint
    let cp1Mapped: CGPoint

    @Binding var cp0: CGPoint
    @Binding var cp1: CGPoint

    var body: some View {
        GeometryReader { (geo: GeometryProxy) in
            ZStack {
                Frame(controlPointSize)
                    .clipCircleWithStroke(.black, lineWidth: 2, fill: Color.green)
                    .offsetToPosition(cp0Mapped, in: gridCoordName)
                    .gesture(DragGesture(coordinateSpace: .named(gridCoordName)).onChanged { value in
                        cp0 = mapToUnitPoint(value.location, from: geo.width)
                    })
                Frame(controlPointSize)
                    .clipCircleWithStroke(.black, lineWidth: 2, fill: Color.yellow)
                    .offsetToPosition(cp1Mapped, in: gridCoordName)
                    .gesture(DragGesture(coordinateSpace: .named(gridCoordName)).onChanged { value in
                        cp1 = mapToUnitPoint(value.location, from: geo.width)
                        //cp0 = CGPoint(1 - self.cp1.x, 1 - cp1.y)
                    })
            }
        }
    }
}

private func textForPoint(_ point: CGPoint, name: String) -> Text {
    Text("\(name): (\(point.x, specifier: "%.2f"), \(point.y, specifier: "%.2f")")
        .headlineFont(.white)
}

private func invertY(_ unitPoint: CGPoint) -> CGPoint {
    CGPoint(unitPoint.x, 1 - unitPoint.y)
}

private func mapFromUnitPoint(
    _ unitPoint: CGPoint,
    to size: CGFloat
) -> CGPoint {
    let invertedPoint = invertY(unitPoint)
    return invertedPoint.scaled(size)
}

private func mapToUnitPoint(_ point: CGPoint, from size: CGFloat) -> CGPoint {
    let scaledPoint = point.scaled(1 / size)
    return invertY(scaledPoint)
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
