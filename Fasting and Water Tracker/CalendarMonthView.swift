//
//  CalendarMonthView.swift
//  Fasting and Water Tracker
//
//  Created by Mark Holdsworth on 01/12/2025.
//

import SwiftUI

struct CalendarMonthView: View {
    @ObservedObject var viewModel: FastingTrackerViewModel
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Month Header
            HStack {
                Button(action: {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.tealTheme)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(monthYearString)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month) {
                        Button(action: {
                            withAnimation {
                                currentMonth = Date()
                            }
                        }) {
                            Text("Today")
                                .font(.caption)
                                .foregroundColor(.tealTheme)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundColor(.tealTheme)
                }
            }
            .padding(.horizontal)
            
            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isToday: calendar.isDateInToday(date),
                            hasFasting: viewModel.hasFastingOnDate(date),
                            hasWater: viewModel.hasWaterOnDate(date)
                        )
                    } else {
                        Color.clear
                            .frame(height: 50)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstDayOfMonth = monthInterval.start.dayStart,
              let firstDayWeekday = calendar.dateComponents([.weekday], from: firstDayOfMonth).weekday else {
            return []
        }
        
        let numberOfDaysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        let firstWeekday = (firstDayWeekday - 1) % 7 // Convert to 0-based (Sunday = 0)
        
        var days: [Date?] = []
        
        // Add empty cells for days before the first day of the month
        for _ in 0..<firstWeekday {
            days.append(nil)
        }
        
        // Add all days of the month
        for day in 1...numberOfDaysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
}

struct CalendarDayView: View {
    let date: Date
    let isToday: Bool
    let hasFasting: Bool
    let hasWater: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .tealTheme : .primary)
            
            HStack(spacing: 4) {
                if hasFasting {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.tealTheme)
                }
                
                if hasWater {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                }
            }
            .frame(height: 12)
        }
        .frame(width: 50, height: 50)
        .background(isToday ? Color.tealTheme.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

extension Date {
    var dayStart: Date? {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 0, minute: 0, second: 0, of: self)
    }
}

