import SwiftUI

struct OnboardingHeadline: View {
    let parts: [HeadlinePart]
    var useSerif: Bool = true
    var centered: Bool = true
    var foregroundColor: Color = Theme.Colors.textPrimary

    enum HeadlinePart {
        case plain(String)
        case serif(String)
    }

    var body: some View {
        parts.reduce(Text("")) { result, part in
            switch part {
            case .plain(let string):
                return result + Text(string)
                    .font(.system(size: OnboardingMetrics.headlineSize, weight: .regular, design: .default))
            case .serif(let string):
                return result + Text(string)
                    .font(.playfairItalic(size: OnboardingMetrics.headlineSize))
            }
        }
        .foregroundStyle(foregroundColor)
        .multilineTextAlignment(centered ? .center : .leading)
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct OnboardingSubheadline: View {
    let text: String
    var centered: Bool = true

    var body: some View {
        Text(text)
            .font(Theme.Fonts.routeSummary)
            .foregroundStyle(Theme.Colors.textSecondary)
            .multilineTextAlignment(centered ? .center : .leading)
            .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
    }
}
