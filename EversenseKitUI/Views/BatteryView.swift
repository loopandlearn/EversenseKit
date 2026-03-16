import SwiftUI

struct BatteryView: View {
    private let backgroundStyle = Color(red: 209 / 255, green: 209 / 255, blue: 209 / 255)
    var batteryLevel: Double

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                GeometryReader { rectangle in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: rectangle.size.width)
                            .foregroundColor(backgroundStyle)
                        Rectangle()
                            .frame(width: rectangle.size.width - (rectangle.size.width * (1 - min(batteryLevel, 1))))
                            .foregroundColor(getColor())
                        if batteryLevel > 1 {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.white)
                                .frame(width: rectangle.size.width, height: rectangle.size.height)
                        }
                    }
                    .compositingGroup()
                    .cornerRadius(6)
                }
                HalfCircleShape()
                    .frame(width: geo.size.width / 7, height: geo.size.height / 7)
                    .foregroundColor(backgroundStyle)
            }
        }
    }

    private func getColor() -> Color {
        switch batteryLevel {
        // returns red color for range 0% to 20%
        case 0 ... 0.2:
            return Color.red
        // returns yellow color for range 20% to 50%
        case 0.2 ... 0.5:
            return Color.yellow
        // returns green color for range 50% to 100%
        case 0.5 ... 1.0:
            return Color.green
        default:
            return Color.green
        }
    }
}

struct HalfCircleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addArc(
            center: CGPoint(x: rect.minX, y: rect.midY),
            radius: rect.height,
            startAngle: .degrees(90),
            endAngle: .degrees(270),
            clockwise: true
        )
        return path
    }
}
