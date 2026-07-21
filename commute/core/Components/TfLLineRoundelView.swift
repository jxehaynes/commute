import SwiftUI

struct TfLLineRoundelView: View {
    let line: TfLLine
    var size: CGFloat = 28

    var body: some View {
        Group {
            switch line.roundelStyle {
            case .capsule:
                capsuleRoundel
            case .roundedRect:
                roundedRectRoundel
            case .circle:
                circleRoundel
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("\(line.displayName) line")
    }

    private var circleRoundel: some View {
        ZStack {
            Circle()
                .fill(line.brandColor)

            Text(line.roundelMark)
                .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                .foregroundStyle(line.roundelForeground)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
    }

    private var capsuleRoundel: some View {
        ZStack {
            Capsule()
                .fill(line.brandColor)
                .frame(width: size * 1.35, height: size * 0.72)

            Text(line.roundelMark)
                .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(width: size * 1.2)
        }
    }

    private var roundedRectRoundel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(line.brandColor)
                .frame(width: size * 1.1, height: size * 0.78)

            Text(line.roundelMark)
                .font(.system(size: size * 0.3, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }
}

private extension TfLLine {
    enum RoundelStyle {
        case circle
        case capsule
        case roundedRect
    }

    var roundelStyle: RoundelStyle {
        switch self {
        case .elizabethLine, .elizabethExpress, .tflRail:
            return .capsule
        case .dlr, .bus:
            return .roundedRect
        default:
            return .circle
        }
    }

    var roundelMark: String {
        switch self {
        case .elizabethLine, .elizabethExpress:
            return "E"
        case .hammersmithAndCity:
            return "H"
        case .waterlooAndCity:
            return "W"
        case .overground, .liberty, .lioness, .mildmay, .suffragette, .weaver, .windrush:
            return "O"
        case .dlr:
            return "DLR"
        case .nationalRail:
            return "R"
        case .bus:
            return "BUS"
        default:
            return String(displayName.prefix(1))
        }
    }

    var roundelForeground: Color {
        switch self {
        case .circle:
            return .black
        case .jubilee, .northern:
            return .white
        default:
            return .white
        }
    }
}

#Preview {
    HStack(spacing: 10) {
        TfLLineRoundelView(line: .central)
        TfLLineRoundelView(line: .elizabethLine)
        TfLLineRoundelView(line: .dlr)
        TfLLineRoundelView(line: .overground)
    }
    .padding()
}
