import SwiftUI

/// Стартовый (сплеш) экран: бренд-картинка + индикатор загрузки.
struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                ProgressView()
            }
        }
    }
}
