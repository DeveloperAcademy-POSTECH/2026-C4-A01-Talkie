import SwiftUI

struct OnboardingPageView: View {
    let data: OnboardingData
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer().frame(height: 70)
            
            
            VStack(alignment: .leading, spacing: 3) {
                Text(data.title)
                    .font(.pretendard(.bold, size: 22))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                 
                Text(data.description)
                    .font(.pretendard(.regular, size: 16))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
            }
            .frame(height: 90, alignment: .topLeading)
            .padding(.horizontal, 16)
            
            
            Spacer()
            
            if let imageName = data.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 450)
                    .frame(maxWidth: .infinity)
            }
            
            Spacer()
        }
    }
}

#Preview {
    DarkScreen {
        OnboardingPageView(data: OnboardingData.pages[0])
    }
}
