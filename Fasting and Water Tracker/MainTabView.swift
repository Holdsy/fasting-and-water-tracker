//
//  MainTabView.swift
//  Fasting and Water Tracker
//
//  Created by Mark Holdsworth on 01/12/2025.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = FastingTrackerViewModel()
    
    var body: some View {
        TabView {
            ContentView(viewModel: viewModel)
                .tabItem {
                    Label("Tracker", systemImage: "house.fill")
                }
            
            HistoryView(viewModel: viewModel)
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
        }
        .accentColor(.tealTheme)
    }
}


