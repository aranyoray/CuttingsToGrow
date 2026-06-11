import SwiftUI

@main
struct CuttingsToGrowApp: App {
    @StateObject private var nursery = NurseryStore()
    @StateObject private var exchange = ExchangeStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(nursery)
                .environmentObject(exchange)
                .tint(Theme.leaf)
                .onAppear { NotificationService.shared.requestAuthorization() }
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            ScannerView()
                .tabItem { Label("Scan", systemImage: "camera.viewfinder") }
            NurseryView()
                .tabItem { Label("Nursery", systemImage: "leaf.circle") }
            SwapMapView()
                .tabItem { Label("Swap Map", systemImage: "map") }
            ExchangeView()
                .tabItem { Label("Exchange", systemImage: "arrow.triangle.2.circlepath") }
        }
    }
}
