//
//  DailyLogView.swift
//  Fasting and Water Tracker
//
//  Created by Mark Holdsworth on 01/12/2025.
//

import SwiftUI

struct DailyLogView: View {
    @ObservedObject var viewModel: FastingTrackerViewModel
    @Binding var selectedDate: Date
    @State private var showEditFastSheet = false
    @State private var editingFast: FastingEntry?
    @State private var editedStartTime: Date = Date()
    @State private var editedEndTime: Date = Date()
    @State private var isCreatingNewFast: Bool = false
    @State private var showEditWaterSheet = false
    @State private var editedWaterAmount: String = ""
    @State private var customWaterMl: String = ""
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Logs")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 4)
        
            // Log for selected date (controlled by calendar selection)
            if let log = viewModel.getDailyLog(for: selectedDate) {
                logCard(for: log)
            } else {
                emptyLogCard
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        .sheet(isPresented: $showEditFastSheet) {
            editFastSheet()
        }
        .sheet(isPresented: $showEditWaterSheet) {
            editWaterSheet()
        }
    }
    
    private func logCard(for log: DailyLog) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Date Header
            Text(formatDate(log.date))
                .font(.headline)
                .foregroundColor(.tealTheme)
            
            Divider()
            
            // Water Intake (tap to edit) or "Add Water" when zero
            Button(action: {
                editedWaterAmount = String(format: "%.2f", log.waterIntake)
                showEditWaterSheet = true
            }) {
                HStack {
                    Image(systemName: log.waterIntake > 0 ? "drop.fill" : "drop.triangle.badge.exclamationmark.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Water Intake")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(log.waterIntake > 0 ? "\(String(format: "%.2f", log.waterIntake)) L" : "Add water for this day")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(log.waterIntake > 0 ? .primary : .blue)
                    }
                    
                    Spacer()
                    
                    if log.waterIntake >= 2.0 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // Fasting Entry or "Add Fast" button if missing
            if let fasting = log.fastingEntry {
                Button(action: {
                    // Only allow editing when the fast has ended
                    guard let endTime = fasting.endTime else { return }
                    isCreatingNewFast = false
                    editingFast = fasting
                    editedStartTime = fasting.startTime
                    editedEndTime = endTime
                    showEditFastSheet = true
                }) {
                    HStack {
                        Image(systemName: "moon.fill")
                            .font(.title3)
                            .foregroundColor(.tealTheme)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fasting")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let endTime = fasting.endTime {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Duration: \(fasting.formattedDuration)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    Text("Started: \(formatTime(fasting.startTime))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("Ended: \(formatTime(endTime))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Ongoing")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.tealTheme.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    // Create a new fasting entry for this date
                    isCreatingNewFast = true
                    let calendar = Calendar.current
                    let startOfDay = calendar.startOfDay(for: log.date)
                    editedStartTime = startOfDay.addingTimeInterval(8 * 3600) // default 8am
                    editedEndTime = editedStartTime.addingTimeInterval(TimeInterval(viewModel.fastingWindowHours * 3600))
                    editingFast = nil
                    showEditFastSheet = true
                }) {
                    HStack {
                        Image(systemName: "moon.badge.plus")
                            .font(.title3)
                            .foregroundColor(.tealTheme)
                        
                        Text("Add Fast for This Day")
                            .font(.headline)
                            .foregroundColor(.tealTheme)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.tealTheme.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var emptyLogCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No log entry for this date")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                // Create a new fasting entry for this date
                isCreatingNewFast = true
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: selectedDate)
                editedStartTime = startOfDay.addingTimeInterval(8 * 3600) // default 8am
                editedEndTime = editedStartTime.addingTimeInterval(TimeInterval(viewModel.fastingWindowHours * 3600))
                editingFast = nil
                showEditFastSheet = true
            }) {
                Text("Add Fast for This Day")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.tealTheme)
                    .cornerRadius(12)
            }
            
            Button(action: {
                editedWaterAmount = ""
                showEditWaterSheet = true
            }) {
                Text("Add Water for This Day")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Edit / Create Fast Sheet
    
    private func editFastSheet() -> some View {
        NavigationView {
            Form {
                Section(header: Text("Fasting Times")) {
                    DatePicker(
                        "Start Time",
                        selection: $editedStartTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    DatePicker(
                        "End Time",
                        selection: $editedEndTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                Section {
                    Button("Save") {
                        if isCreatingNewFast {
                            viewModel.addHistoricalFast(
                                for: selectedDate,
                                startTime: editedStartTime,
                                endTime: editedEndTime
                            )
                        } else if let fast = editingFast {
                            viewModel.updateHistoricalFast(
                                entryID: fast.id,
                                newStartTime: editedStartTime,
                                newEndTime: editedEndTime
                            )
                        }
                        showEditFastSheet = false
                        isCreatingNewFast = false
                    }
                    .foregroundColor(.tealTheme)
                }
            }
            .navigationTitle(isCreatingNewFast ? "Add Fast" : "Edit Fast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showEditFastSheet = false
                        isCreatingNewFast = false
                    }
                }
            }
        }
    }
    
    // MARK: - Edit / Create Water Sheet
    
    private func editWaterSheet() -> some View {
        NavigationView {
            Form {
                Section(header: Text("Water Intake")) {
                    TextField("Litres", text: $editedWaterAmount)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Quick Add")) {
                    HStack {
                        ForEach(viewModel.commonWaterSizes, id: \.self) { size in
                            Button(action: {
                                let current = Double(editedWaterAmount.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                                let addedLitres = size / 1000.0
                                let newTotal = current + addedLitres
                                editedWaterAmount = String(format: "%.2f", newTotal)
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "drop.fill")
                                        .font(.headline)
                                    Text("\(Int(size)) ml")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                
                Section(header: Text("Custom Add (ml)")) {
                    HStack {
                        TextField("Amount in ml", text: $customWaterMl)
                            .keyboardType(.numberPad)
                        
                        Button("Add") {
                            let baseLitres = Double(editedWaterAmount.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                            if let ml = Double(customWaterMl.trimmingCharacters(in: .whitespacesAndNewlines)), ml > 0 {
                                let newTotal = baseLitres + (ml / 1000.0)
                                editedWaterAmount = String(format: "%.2f", newTotal)
                                customWaterMl = ""
                            }
                        }
                    }
                }
                
                Section {
                    Button("Save") {
                        let trimmed = editedWaterAmount.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let value = Double(trimmed), value >= 0 {
                            viewModel.setHistoricalWaterIntake(for: selectedDate, litres: value)
                        }
                        showEditWaterSheet = false
                        customWaterMl = ""
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Set Water Intake")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showEditWaterSheet = false
                    }
                }
            }
        }
    }
}


