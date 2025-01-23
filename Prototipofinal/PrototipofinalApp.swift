//
//  PrototipofinalApp.swift
//  Prototipofinal
//
//  Created by Frank Perez on 06/10/24.
//

import SwiftUI

@main
struct PrototipofinalApp: App {
    @StateObject var shipmentState = ShipmentState()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(shipmentState)
        }
    }
}
