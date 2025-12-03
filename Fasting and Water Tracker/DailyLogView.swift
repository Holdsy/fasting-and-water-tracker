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
            if let fast = editingFast {
                editFastSheet(for: fast)
            }
        }
    }
    
    private func logCard(for log: DailyLog) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Date Header
            Text(formatDate(log.date))
                .font(.headline)
                .foregroundColor(.tealTheme)
            
            Divider()
            
            // Water Intake
            HStack {
                Image(systemName: "drop.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Water Intake")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.2f", log.waterIntake)) L")
                        .font(.title3)
                        .fontWeight(.semibold)
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
            
            // Fasting Entry
            if let fasting = log.fastingEntry {
                Button(action: {
                    // Only allow editing when the fast has ended
                    guard let endTime = fasting.endTime else { return }
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
            }
        }
    }
    
    private var emptyLogCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No log entry for this date")
                .font(.subheadline)
                .foregroundColor(.secondary)
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
    
    // MARK: - Edit Fast Sheet
    
    private func editFastSheet(for fast: FastingEntry) -> some View {
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
                        viewModel.updateHistoricalFast(
                            entryID: fast.id,
                            newStartTime: editedStartTime,
                            newEndTime: editedEndTime
                        )
                        showEditFastSheet = false
                    }
                    .foregroundColor(.tealTheme)
                }
            }
            .navigationTitle("Edit Fast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showEditFastSheet = false
                    }
                }
            }
        }
    }
}


