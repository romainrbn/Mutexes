//
//  ContentView.swift
//  Mutexes
//
//  Created by Romain Rabouan on 02/09/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var displayer = MutexDisplayer()

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            ForEach(displayer.results, id: \.self) { result in
                Text(result)
            }

            if displayer.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            }

            Spacer()

            Button(action: displayer.buttonAction) {
                Text("Start measuring")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
