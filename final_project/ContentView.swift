import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        ZStack {
            HanSceneBackdrop()

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
