//
//  LogoView.swift
//  HappyBirthday
//
//  Created by Eric Terrisson on 09/05/2024.
//

import SwiftUI

struct LogoView: View {
    var body: some View {
        VStack {
            Image(systemName: "gift")

            Text("happy birthday")
                .textCase(.uppercase)
        }
        .foregroundColor(.pink)
    }
}

struct LogoView_Previews: PreviewProvider {
    static var previews: some View {
        LogoView()
    }
}
