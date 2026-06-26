//
//  StartMenuView.swift
//  room
//
//  Created by Raffi Chaesa Ananda on 26/06/26.
//


import SwiftUI

struct StartMenuView: View {
    var onPlayAction: () -> Void

    var body: some View {
        ZStack {
            Color.black
            Button("PLAY") {
                onPlayAction()
            }
            .font(.largeTitle)
            .foregroundStyle(.white)
        }
        .transition(.opacity)
    }
}