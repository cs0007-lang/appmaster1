import SwiftUI

struct InstallFromURLView: View {
    let url: URL
    
    var body: some View {
        VStack {
            Text("Installing from URL")
            Text(url.absoluteString)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
