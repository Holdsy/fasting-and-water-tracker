//
//  HistoryView.swift
//  Fasting and Water Tracker
//
//  Created by Mark Holdsworth on 01/12/2025.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: FastingTrackerViewModel
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Calendar Section
                        CalendarMonthView(viewModel: viewModel, selectedDate: $selectedDate)
                        
                        // Daily Log Section
                        DailyLogView(viewModel: viewModel, selectedDate: $selectedDate)
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


