//
//  ContentView.swift
//  Fasting and Water Tracker
//
//  Created by Mark Holdsworth on 01/12/2025.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: FastingTrackerViewModel
    @State private var showCustomFastingWindow = false
    @State private var showCustomWaterAmount = false
    @State private var customFastingHours: String = ""
    @State private var customEatingHours: String = ""
    @State private var customWaterAmount: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Fasting Section
                        fastingSection
                        
                        // Water Section
                        waterSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.isFasting ? "You're Fasting" : "Fasting Tracker")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.tealTheme, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .sheet(isPresented: $showCustomFastingWindow) {
            customFastingWindowSheet
        }
        .sheet(isPresented: $showCustomWaterAmount) {
            customWaterAmountSheet
        }
    }
    
    // MARK: - Fasting Section
    
    private var fastingSection: some View {
        VStack(spacing: 20) {
            // Main Fasting Timer Card
            VStack(spacing: 20) {
                if viewModel.isFasting {
                    // Circular Progress with Elapsed Time
                    ZStack {
                        CircularProgressView(
                            progress: viewModel.fastingProgress(),
                            lineWidth: 16,
                            color: .tealTheme
                        )
                        .frame(width: 220, height: 220)
                        
                        VStack(spacing: 8) {
                            Text("Elapsed Time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(viewModel.formattedElapsedTime())
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.primary)
                            
                            if let endTime = viewModel.fastingEndTime() {
                                Text("Goal: \(formatTime(endTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // Remaining Time
                    VStack(spacing: 8) {
                        Text("Remaining Time")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.formattedTimeUntilNextMeal())
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.tealTheme)
                            .monospacedDigit()
                    }
                    
                    // End Fast Button
                    Button(action: {
                        viewModel.stopFasting()
                    }) {
                        Text("END FAST")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .padding(.top, 10)
                    
                    // Fasting Details
                    HStack(spacing: 30) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Started")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let startTime = viewModel.fastingStartTime {
                                Text(formatTime(startTime))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Goal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let endTime = viewModel.fastingEndTime() {
                                Text(formatTime(endTime))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // Not Fasting State
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.tealTheme)
                        
                        Text("Not Currently Fasting")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
            
            // Fasting Window Selection
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Fasting Window")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(viewModel.commonFastingWindows, id: \.hours) { window in
                        fastingWindowButton(hours: window.hours, name: window.name)
                    }
                    
                    Button(action: {
                        showCustomFastingWindow = true
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.tealTheme)
                            Text("Custom")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
            
            // Current Window & Start Button
            VStack(spacing: 12) {
                HStack {
                    Text("Current Window:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(viewModel.fastingWindowHours):\(viewModel.eatingWindowHours)")
                        .fontWeight(.semibold)
                        .foregroundColor(.tealTheme)
                }
                .padding(.horizontal)
                
                Button(action: {
                    if viewModel.isFasting {
                        viewModel.stopFasting()
                    } else {
                        viewModel.startFasting()
                    }
                }) {
                    Text(viewModel.isFasting ? "END FAST" : "START FAST")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isFasting ? Color.red : Color.tealTheme)
                        .cornerRadius(12)
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        }
    }
    
    private func fastingWindowButton(hours: Int, name: String) -> some View {
        Button(action: {
            let eatingHours = 24 - hours
            viewModel.setFastingWindow(fastingHours: hours, eatingHours: eatingHours)
        }) {
            VStack(spacing: 6) {
                Text(name)
                    .font(.headline)
                Text("\(hours)h fast")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.fastingWindowHours == hours ? Color.tealTheme.opacity(0.15) : Color(.systemGray6))
            .foregroundColor(.primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(viewModel.fastingWindowHours == hours ? Color.tealTheme : Color.clear, lineWidth: 2)
            )
        }
    }
    
    // MARK: - Water Section
    
    private var waterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Water Intake")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 4)
            
            // Water Progress Card
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Water")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        // Drive the UI from today's entries so it always reflects the current day
                        Text("\(String(format: "%.1f", viewModel.currentDayWaterIntake())) / \(String(format: "%.1f", viewModel.dailyTarget)) L")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    Image(systemName: "drop.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.tealTheme)
                }
                
                // Circular Progress for Water
                ZStack {
                    CircularProgressView(
                        progress: viewModel.waterProgress(),
                        lineWidth: 12,
                        color: .tealTheme
                    )
                    .frame(width: 120, height: 120)
                    
                    Text("\(Int(viewModel.waterProgress() * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.tealTheme)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
            
            // Quick Add Buttons
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Add")
                    .font(.headline)
                    .padding(.horizontal, 4)
                
                HStack(spacing: 12) {
                    ForEach(viewModel.commonWaterSizes, id: \.self) { size in
                        Button(action: {
                            viewModel.addWater(amount: size)
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "drop.fill")
                                    .font(.title3)
                                Text("\(Int(size))ml")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.tealTheme.opacity(0.15))
                            .foregroundColor(.tealTheme)
                            .cornerRadius(12)
                        }
                    }
                    
                    Button(action: {
                        showCustomWaterAmount = true
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Custom")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        }
    }
    
    // MARK: - Custom Fasting Window Sheet
    
    private var customFastingWindowSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Custom Fasting Window")) {
                    TextField("Fasting Hours", text: $customFastingHours)
                        .keyboardType(.numberPad)
                    
                    TextField("Eating Hours", text: $customEatingHours)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("Set Custom Window") {
                        if let fastingHours = Int(customFastingHours),
                           let eatingHours = Int(customEatingHours),
                           fastingHours > 0, eatingHours > 0,
                           fastingHours + eatingHours == 24 {
                            viewModel.setFastingWindow(fastingHours: fastingHours, eatingHours: eatingHours)
                            showCustomFastingWindow = false
                            customFastingHours = ""
                            customEatingHours = ""
                        }
                    }
                    .disabled(customFastingHours.isEmpty || customEatingHours.isEmpty)
                    .foregroundColor(.tealTheme)
                }
            }
            .navigationTitle("Custom Window")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showCustomFastingWindow = false
                        customFastingHours = ""
                        customEatingHours = ""
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Water Amount Sheet
    
    private var customWaterAmountSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Custom Water Amount")) {
                    TextField("Amount (ml)", text: $customWaterAmount)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Button("Add Water") {
                        if let amount = Double(customWaterAmount), amount > 0 {
                            viewModel.addWater(amount: amount)
                            showCustomWaterAmount = false
                            customWaterAmount = ""
                        }
                    }
                    .disabled(customWaterAmount.isEmpty)
                    .foregroundColor(.tealTheme)
                }
            }
            .navigationTitle("Custom Amount")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showCustomWaterAmount = false
                        customWaterAmount = ""
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView(viewModel: FastingTrackerViewModel())
}
