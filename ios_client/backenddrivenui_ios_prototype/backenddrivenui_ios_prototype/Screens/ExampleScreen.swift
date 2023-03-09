//
//  ExampleScreen.swift
//  backenddrivenui_ios_prototype
//
//  Created by Dominik Deimel on 09.03.23.
//

import SwiftUI

struct ExampleScreen: View {
    @ObservedObject var parser = Parser.instance
    var body: some View {
        Button("Load Screen from Server"){
            Task {
                await parser.loadScreen("exampleScreen")
            }
        }
        parser.currentView.render()
    }
}
