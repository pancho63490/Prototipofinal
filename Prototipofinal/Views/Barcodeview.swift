import SwiftUI

struct BarcodeScannerView: View {
    @State private var scannedCode: String? = nil
    @State private var showingAlert = false
    
    var body: some View {
        ZStack {
           
            CameraScannerView(scannedCode: $scannedCode, onCodeScanned: { code in
                // Se activa cuando se detecta un código
                self.scannedCode = code
                self.showingAlert = true
            })
            .edgesIgnoringSafeArea(.all)
            
       
            Rectangle()
                .stroke(Color.green, lineWidth: 3)
                .frame(width: 350, height: 150)
                .position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY - 100)
            
        
            if let code = scannedCode {
                VStack {
                    Spacer()
                    Text("Scanned Code: \(code)")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding(.bottom, 50)
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Scanned Code"),
                message: Text(scannedCode ?? "N/A"),
                dismissButton: .default(Text("OK")) {
                   
                    scannedCode = nil
                }
            )
        }
    }
    
}
