//
//  FastingTrackerViewModel.swift
//  Fasting and Water Tracker
//
//  Created by Mark Holdsworth on 01/12/2025.
//

import Foundation
import SwiftUI
import Combine

class FastingTrackerViewModel: ObservableObject {
    // Fasting properties
    @Published var fastingWindowHours: Int = 16
    @Published var eatingWindowHours: Int = 8
    @Published var fastingStartTime: Date?
    @Published var isFasting: Bool = false
    
    // Water properties
    @Published var dailyWaterIntake: Double = 0.0 // in litres
    @Published var dailyTarget: Double = 2.0 // 2 litres
    @Published var waterEntries: [WaterEntry] = []
    
    // History tracking
    @Published var fastingHistory: [FastingEntry] = []
    
    // Common fasting windows
    let commonFastingWindows: [(hours: Int, name: String)] = [
        (16, "16:8"),
        (18, "18:6"),
        (20, "20:4"),
        (23, "OMAD (23:1)")
    ]
    
    // Common water sizes in ml
    let commonWaterSizes: [Double] = [250, 500, 750] // ml
    
    private var timer: Timer?
    
    init() {
        loadData()
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Fasting Methods
    
    func startFasting() {
        fastingStartTime = Date()
        isFasting = true
        // Add to history
        let entry = FastingEntry(startTime: Date(), fastingWindowHours: fastingWindowHours)
        fastingHistory.append(entry)
        saveData()
    }
    
    func stopFasting() {
        // Update the last entry with end time if it exists
        if let lastEntry = fastingHistory.last, lastEntry.endTime == nil {
            let index = fastingHistory.count - 1
            fastingHistory[index] = FastingEntry(
                startTime: lastEntry.startTime,
                endTime: Date(),
                fastingWindowHours: lastEntry.fastingWindowHours
            )
        }
        fastingStartTime = nil
        isFasting = false
        saveData()
    }
    
    func setFastingWindow(fastingHours: Int, eatingHours: Int) {
        fastingWindowHours = fastingHours
        eatingWindowHours = eatingHours
        saveData()
    }
    
    func timeUntilNextMeal() -> TimeInterval? {
        guard let startTime = fastingStartTime, isFasting else { return nil }
        
        let fastingEndTime = startTime.addingTimeInterval(TimeInterval(fastingWindowHours * 3600))
        let now = Date()
        
        if now < fastingEndTime {
            return fastingEndTime.timeIntervalSince(now)
        } else {
            // Fasting window has ended
            return 0
        }
    }
    
    func formattedTimeUntilNextMeal() -> String {
        guard let timeInterval = timeUntilNextMeal() else {
            return "Not fasting"
        }
        
        if timeInterval <= 0 {
            return "Fasting complete!"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    func elapsedFastingTime() -> TimeInterval? {
        guard let startTime = fastingStartTime, isFasting else { return nil }
        return Date().timeIntervalSince(startTime)
    }
    
    func formattedElapsedTime() -> String {
        guard let timeInterval = elapsedFastingTime() else {
            return "00:00:00"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func fastingProgress() -> Double {
        guard let startTime = fastingStartTime, isFasting else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        let total = TimeInterval(fastingWindowHours * 3600)
        return min(elapsed / total, 1.0)
    }
    
    func fastingEndTime() -> Date? {
        guard let startTime = fastingStartTime, isFasting else { return nil }
        return startTime.addingTimeInterval(TimeInterval(fastingWindowHours * 3600))
    }
    
    // MARK: - Water Methods
    
    func addWater(amount: Double) {
        let litres = amount / 1000.0 // Convert ml to litres
        dailyWaterIntake += litres
        waterEntries.append(WaterEntry(amount: litres, timestamp: Date()))
        saveData()
    }
    
    func resetDailyWater() {
        let calendar = Calendar.current
        let today = Date()
        
        // Remove only today's entries
        waterEntries.removeAll { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: today)
        }
        
        // Reset daily intake
        dailyWaterIntake = 0.0
        
        saveData()
    }
    
    func waterProgress() -> Double {
        return min(dailyWaterIntake / dailyTarget, 1.0)
    }
    
    // MARK: - Calendar Methods
    
    func hasFastingOnDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return fastingHistory.contains { entry in
            calendar.isDate(entry.startTime, inSameDayAs: date)
        }
    }
    
    func hasWaterOnDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return waterEntries.contains { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: date)
        }
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
    
    // MARK: - Persistence
    
    private func saveData() {
        UserDefaults.standard.set(fastingWindowHours, forKey: "fastingWindowHours")
        UserDefaults.standard.set(eatingWindowHours, forKey: "eatingWindowHours")
        UserDefaults.standard.set(fastingStartTime, forKey: "fastingStartTime")
        UserDefaults.standard.set(isFasting, forKey: "isFasting")
        UserDefaults.standard.set(dailyWaterIntake, forKey: "dailyWaterIntake")
        UserDefaults.standard.set(dailyTarget, forKey: "dailyTarget")
        
        // Save water entries
        if let encoded = try? JSONEncoder().encode(waterEntries) {
            UserDefaults.standard.set(encoded, forKey: "waterEntries")
        }
        
        // Save fasting history
        if let encoded = try? JSONEncoder().encode(fastingHistory) {
            UserDefaults.standard.set(encoded, forKey: "fastingHistory")
        }
        
        // Check if we need to reset daily water (new day)
        checkAndResetDailyWater()
    }
    
    private func loadData() {
        fastingWindowHours = UserDefaults.standard.integer(forKey: "fastingWindowHours")
        if fastingWindowHours == 0 {
            fastingWindowHours = 16 // Default
        }
        
        eatingWindowHours = UserDefaults.standard.integer(forKey: "eatingWindowHours")
        if eatingWindowHours == 0 {
            eatingWindowHours = 8 // Default
        }
        
        if let startTime = UserDefaults.standard.object(forKey: "fastingStartTime") as? Date {
            fastingStartTime = startTime
        }
        
        isFasting = UserDefaults.standard.bool(forKey: "isFasting")
        dailyWaterIntake = UserDefaults.standard.double(forKey: "dailyWaterIntake")
        dailyTarget = UserDefaults.standard.double(forKey: "dailyTarget")
        if dailyTarget == 0 {
            dailyTarget = 2.0 // Default 2 litres
        }
        
        // Load water entries
        if let data = UserDefaults.standard.data(forKey: "waterEntries"),
           let decoded = try? JSONDecoder().decode([WaterEntry].self, from: data) {
            waterEntries = decoded
        }
        
        // Load fasting history
        if let data = UserDefaults.standard.data(forKey: "fastingHistory"),
           let decoded = try? JSONDecoder().decode([FastingEntry].self, from: data) {
            fastingHistory = decoded
        }
        
        checkAndResetDailyWater()
    }
    
    private func checkAndResetDailyWater() {
        let lastResetDate = UserDefaults.standard.object(forKey: "lastWaterResetDate") as? Date ?? Date()
        let calendar = Calendar.current
        
        if !calendar.isDateInToday(lastResetDate) {
            // Reset daily intake but keep history
            let today = Date()
            dailyWaterIntake = waterEntries
                .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
                .reduce(0.0) { $0 + $1.amount }
            
            UserDefaults.standard.set(Date(), forKey: "lastWaterResetDate")
            saveData()
        } else {
            // Recalculate today's intake
            let today = Date()
            dailyWaterIntake = waterEntries
                .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
                .reduce(0.0) { $0 + $1.amount }
        }
    }
}

// MARK: - Water Entry Model

struct WaterEntry: Codable, Identifiable {
    var id: UUID
    let amount: Double // in litres
    let timestamp: Date
    
    init(amount: Double, timestamp: Date) {
        self.id = UUID()
        self.amount = amount
        self.timestamp = timestamp
    }
    
    enum CodingKeys: String, CodingKey {
        case id, amount, timestamp
    }
}

// MARK: - Fasting Entry Model

struct FastingEntry: Codable, Identifiable {
    var id: UUID
    let startTime: Date
    var endTime: Date?
    let fastingWindowHours: Int
    
    init(startTime: Date, endTime: Date? = nil, fastingWindowHours: Int) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.fastingWindowHours = fastingWindowHours
    }
    
    enum CodingKeys: String, CodingKey {
        case id, startTime, endTime, fastingWindowHours
    }
}

