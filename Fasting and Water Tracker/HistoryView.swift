//
//  HistoryView.swift
//  Fasting and Water Tracker
//
//  Created by Mark Holdsworth on 01/12/2025.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: FastingTrackerViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Calendar Section
                        CalendarMonthView(viewModel: viewModel)
                        
                        // Daily Log Section
                        DailyLogView(viewModel: viewModel)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}


