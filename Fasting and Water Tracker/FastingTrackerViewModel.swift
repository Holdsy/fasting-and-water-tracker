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
    @Published var dailyLogs: [DailyLog] = []
    
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
        let calendar = Calendar.current
        let startTime = Date()
        fastingStartTime = startTime
        isFasting = true
        
        // Add to history
        let entry = FastingEntry(startTime: startTime, fastingWindowHours: fastingWindowHours)
        fastingHistory.append(entry)
        
        // Create daily log for the day fasting started
        let startDate = calendar.startOfDay(for: startTime)
        updateOrCreateDailyLog(for: startDate, fastingEntry: entry)
        
        saveData()
    }
    
    func stopFasting() {
        let calendar = Calendar.current
        let endTime = Date()
        
        // Update the last entry with end time if it exists
        if let lastEntry = fastingHistory.last, lastEntry.endTime == nil {
            let index = fastingHistory.count - 1
            fastingHistory[index] = FastingEntry(
                startTime: lastEntry.startTime,
                endTime: endTime,
                fastingWindowHours: lastEntry.fastingWindowHours
            )
            
            // Create or update daily log for the day the fast ended
            let endDate = calendar.startOfDay(for: endTime)
            updateOrCreateDailyLog(for: endDate, fastingEntry: fastingHistory[index])
        }
        
        fastingStartTime = nil
        isFasting = false
        saveData()
    }
    
    /// Updates the start & end time for a historical fast identified by entry ID.
    func updateHistoricalFast(entryID: UUID, newStartTime: Date, newEndTime: Date?) {
        // Update in fasting history
        guard let index = fastingHistory.firstIndex(where: { $0.id == entryID }) else { return }
        
        let existing = fastingHistory[index]
        let updatedEntry = FastingEntry(
            id: existing.id,
            startTime: newStartTime,
            endTime: newEndTime,
            fastingWindowHours: existing.fastingWindowHours
        )
        fastingHistory[index] = updatedEntry
        
        // Update any daily log that references this entry
        if let logIndex = dailyLogs.firstIndex(where: { $0.fastingEntry?.id == entryID }) {
            dailyLogs[logIndex].fastingEntry = updatedEntry
        }
        
        saveData()
    }
    
    /// Updates the start time of the current ongoing fast and adjusts history & daily logs.
    func updateFastingStartTime(to newStartTime: Date) {
        guard isFasting, let currentStart = fastingStartTime else { return }
        
        fastingStartTime = newStartTime
        
        let calendar = Calendar.current
        let oldStartDay = calendar.startOfDay(for: currentStart)
        let newStartDay = calendar.startOfDay(for: newStartTime)
        
        // Update the ongoing fasting history entry, if any
        if let lastIndex = fastingHistory.indices.last,
           fastingHistory[lastIndex].endTime == nil {
            let existing = fastingHistory[lastIndex]
            let updatedEntry = FastingEntry(
                id: existing.id,
                startTime: newStartTime,
                endTime: existing.endTime,
                fastingWindowHours: existing.fastingWindowHours
            )
            fastingHistory[lastIndex] = updatedEntry
            
            // Remove reference from the old daily log day if it pointed to this entry
            if let oldLogIndex = dailyLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: oldStartDay) }) {
                if dailyLogs[oldLogIndex].fastingEntry?.id == existing.id {
                    dailyLogs[oldLogIndex].fastingEntry = nil
                }
            }
            
            // Attach the updated entry to the new start day log
            updateOrCreateDailyLog(for: newStartDay, fastingEntry: updatedEntry)
        }
        
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
    
    /// Returns the total water intake (in litres) for the given date (defaults to today)
    func currentDayWaterIntake(for date: Date = Date()) -> Double {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        
        return waterEntries
            .filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            .reduce(0.0) { $0 + $1.amount }
    }
    
    func addWater(amount: Double) {
        let calendar = Calendar.current
        let now = Date()
        let litres = amount / 1000.0 // Convert ml to litres
        waterEntries.append(WaterEntry(amount: litres, timestamp: now))
        
        // Recalculate today's total from entries so UI is always driven by timestamps
        let today = calendar.startOfDay(for: now)
        dailyWaterIntake = currentDayWaterIntake(for: today)
        
        // Update daily log for today
        updateOrCreateDailyLog(for: today, waterAmount: dailyWaterIntake)
        
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
        // Always base progress on today's entries so it automatically resets with the new day
        let todayIntake = currentDayWaterIntake()
        return min(todayIntake / dailyTarget, 1.0)
    }
    
    // MARK: - Calendar Methods
    
    func hasFastingOnDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        return dailyLogs.contains { log in
            calendar.isDate(log.date, inSameDayAs: targetDate) && log.fastingEntry != nil
        }
    }
    
    func hasWaterOnDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        return dailyLogs.contains { log in
            calendar.isDate(log.date, inSameDayAs: targetDate) && log.waterIntake > 0
        }
    }
    
    func getDailyLog(for date: Date) -> DailyLog? {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        return dailyLogs.first { log in
            calendar.isDate(log.date, inSameDayAs: targetDate)
        }
    }
    
    private func updateOrCreateDailyLog(for date: Date, fastingEntry: FastingEntry? = nil, waterAmount: Double? = nil) {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        if let index = dailyLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: targetDate) }) {
            // Update existing log
            var log = dailyLogs[index]
            if let fasting = fastingEntry {
                log.fastingEntry = fasting
            }
            if let water = waterAmount {
                log.waterIntake = water
            }
            dailyLogs[index] = log
        } else {
            // Create new log
            var log = DailyLog(date: targetDate)
            if let fasting = fastingEntry {
                log.fastingEntry = fasting
            }
            if let water = waterAmount {
                log.waterIntake = water
            }
            dailyLogs.append(log)
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
        
        // Save daily logs
        if let encoded = try? JSONEncoder().encode(dailyLogs) {
            UserDefaults.standard.set(encoded, forKey: "dailyLogs")
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
        
        // Load daily logs
        if let data = UserDefaults.standard.data(forKey: "dailyLogs"),
           let decoded = try? JSONDecoder().decode([DailyLog].self, from: data) {
            dailyLogs = decoded
        } else {
            // If no logs exist, rebuild from existing data
            rebuildLogsFromHistory()
        }
        
        checkAndResetDailyWater()
    }
    
    private func rebuildLogsFromHistory() {
        let calendar = Calendar.current
        
        // Rebuild logs from water entries - group by day
        var waterByDay: [Date: Double] = [:]
        for entry in waterEntries {
            let entryDate = calendar.startOfDay(for: entry.timestamp)
            waterByDay[entryDate, default: 0.0] += entry.amount
        }
        
        for (date, amount) in waterByDay {
            if let index = dailyLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                dailyLogs[index].waterIntake = amount
            } else {
                var log = DailyLog(date: date)
                log.waterIntake = amount
                dailyLogs.append(log)
            }
        }
        
        // Rebuild logs from fasting history
        for fasting in fastingHistory {
            if let endTime = fasting.endTime {
                // Fast ended - log goes to the day it ended
                let endDate = calendar.startOfDay(for: endTime)
                if let index = dailyLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: endDate) }) {
                    dailyLogs[index].fastingEntry = fasting
                } else {
                    var log = DailyLog(date: endDate)
                    log.fastingEntry = fasting
                    dailyLogs.append(log)
                }
            } else {
                // Ongoing fast - log goes to the day it started
                let startDate = calendar.startOfDay(for: fasting.startTime)
                if let index = dailyLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: startDate) }) {
                    dailyLogs[index].fastingEntry = fasting
                } else {
                    var log = DailyLog(date: startDate)
                    log.fastingEntry = fasting
                    dailyLogs.append(log)
                }
            }
        }
        
        // Sort logs by date
        dailyLogs.sort { $0.date < $1.date }
    }
    
    private func checkAndResetDailyWater() {
        let lastResetDate = UserDefaults.standard.object(forKey: "lastWaterResetDate") as? Date ?? Date()
        let calendar = Calendar.current
        
        if !calendar.isDateInToday(lastResetDate) {
            // New day - reset daily intake and finalize yesterday's log
            let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            let yesterdayStart = calendar.startOfDay(for: yesterday)
            
            // Finalize yesterday's water log
            let yesterdayWater = waterEntries
                .filter { calendar.isDate($0.timestamp, inSameDayAs: yesterday) }
                .reduce(0.0) { $0 + $1.amount }
            
            if yesterdayWater > 0 {
                updateOrCreateDailyLog(for: yesterdayStart, waterAmount: yesterdayWater)
            }
            
            // Reset today's intake
            let today = Date()
            dailyWaterIntake = currentDayWaterIntake(for: today)
            
            UserDefaults.standard.set(Date(), forKey: "lastWaterResetDate")
            saveData()
        } else {
            // Recalculate today's intake
            let today = Date()
            dailyWaterIntake = currentDayWaterIntake(for: today)
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
    
    init(id: UUID, startTime: Date, endTime: Date? = nil, fastingWindowHours: Int) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.fastingWindowHours = fastingWindowHours
    }
    
    enum CodingKeys: String, CodingKey {
        case id, startTime, endTime, fastingWindowHours
    }
    
    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "Ongoing" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%dh %dm", hours, minutes)
    }
}

// MARK: - Daily Log Model

struct DailyLog: Codable, Identifiable {
    var id: UUID
    let date: Date
    var waterIntake: Double // in litres
    var fastingEntry: FastingEntry?
    
    init(date: Date, waterIntake: Double = 0.0, fastingEntry: FastingEntry? = nil) {
        self.id = UUID()
        self.date = date
        self.waterIntake = waterIntake
        self.fastingEntry = fastingEntry
    }
    
    enum CodingKeys: String, CodingKey {
        case id, date, waterIntake, fastingEntry
    }
}

