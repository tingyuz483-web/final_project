import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.98, green: 0.95, blue: 0.90), Color(red: 0.93, green: 0.82, blue: 0.70)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            if viewModel.currentUser == nil {
                AuthFlowView()
                    .environmentObject(viewModel)
            } else {
                RootTabView()
                    .environmentObject(viewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
