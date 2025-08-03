import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query private var localJobs: [Job]
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var selectedJob: Job?
    @State private var showingAddJob = false
    @State private var showingCalendarIntegration = false
    
    // Supabase data
    @StateObject private var jobService = JobService()
    @State private var supabaseJobs: [SupabaseJob] = []
    @State private var isLoading = false
    
    // Use Supabase jobs converted to local Job objects for display
    var jobs: [Job] {
        return supabaseJobs.map { $0.toLocalJob() }
    }
    
    private var upcomingEvents: [Job] {
        let today = Calendar.current.startOfDay(for: Date())
        return jobs
            .filter { job in
                guard let startDate = job.startDate else { return false }
                return Calendar.current.startOfDay(for: startDate) >= today
            }
            .sorted { ($0.startDate ?? Date()) < ($1.startDate ?? Date()) }
    }
    
    private var pastEvents: [Job] {
        let today = Calendar.current.startOfDay(for: Date())
        return jobs
            .filter { job in
                guard let startDate = job.startDate else { return false }
                return Calendar.current.startOfDay(for: startDate) < today
            }
            .sorted { ($0.startDate ?? Date()) > ($1.startDate ?? Date()) } // Most recent first
    }
    
    private func jobsForDate(_ date: Date) -> [Job] {
        let calendar = Calendar.current
        return jobs.filter { job in
            guard let startDate = job.startDate else { return false }
            return calendar.isDate(startDate, inSameDayAs: date)
        }
    }
    
    private func eventColorForDate(_ date: Date) -> Color? {
        let jobsOnDate = jobsForDate(date)
        if jobsOnDate.isEmpty { return nil }
        
        // Priority: casting (purple) > jobs (blue) > other (green)
        if jobsOnDate.contains(where: { $0.title.lowercased().contains("casting") }) {
            return .purple
        } else if jobsOnDate.contains(where: { $0.type == .contract || $0.type == .freelance }) {
            return .blue
        } else {
            return .green
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Page title
                HStack {
                    Text("Calendar")
                        .font(.pageTitle)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                calendarIntegrationSection
                
                calendarSection
                    
                upcomingEventsSection
                
                pastEventsSection
                }
                .padding(.bottom, 100) // Space for tab bar
        }
        .sheet(isPresented: $showingAddJob) {
            SimpleJobCreationView()
        }
        .sheet(item: $selectedJob) { job in
            JobDetailModalView(job: job)
        }
        .onAppear {
            loadJobs()
        }
        .refreshable {
            loadJobs()
        }
        .onChange(of: appState.dataRefreshTrigger) { _, _ in
            loadJobs()
        }
        .requiresAuthentication()
    }
    
    private var calendarIntegrationSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calendar Integration")
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(.white)
                    
                    Text("Sync with your preferred calendar app")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    showingCalendarIntegration = true
                }) {
                    Text("Connect")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.blue, lineWidth: 1)
                        )
                        .pulseAnimation(intensity: 0.3, duration: 6.0) // Pulse every 6s until linked
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.3))
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showingCalendarIntegration) {
            CalendarIntegrationView()
        }
    }
    
    private var calendarSection: some View {
        VStack(spacing: 0) {
            // Month navigation header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            // Calendar grid
            VStack(spacing: 0) {
                // Weekday headers
                HStack(spacing: 0) {
                    ForEach(weekdayHeaders, id: \.self) { weekday in
                        Text(weekday)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                
                // Calendar days
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                    ForEach(calendarDays, id: \.self) { date in
                        CalendarDayView(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month),
                            eventColor: eventColorForDate(date)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.appBackground)
    }
    
    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Upcoming Events")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .padding(.bottom, 20)
            
            if upcomingEvents.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 8) {
                        Text("No upcoming events")
                            .font(.headline)
                            .foregroundColor(Color.appPrimaryText)
                        
                        Text("Add your first job to see it here")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                    }
                    
                    Button(action: {
                        showingAddJob = true
                    }) {
                        Text("Add Job")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 120, height: 44)
                            .background(Color.blue)
                            .cornerRadius(22)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(upcomingEvents) { job in
                        EventCardView(job: job)
                            .onTapGesture {
                                selectedJob = job
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color.appBackground)
    }
    
    private var pastEventsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Past Events")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundColor(.white)
                
                Spacer()
                
                if !pastEvents.isEmpty {
                    Text("\(pastEvents.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.gray.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .padding(.bottom, 20)
            
            if pastEvents.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 8) {
                        Text("No past events")
                            .font(.headline)
                            .foregroundColor(Color.appPrimaryText)
                        
                        Text("Completed jobs will appear here")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(pastEvents.prefix(10)) { job in // Limit to 10 most recent
                        PastEventCardView(job: job)
                            .onTapGesture {
                                selectedJob = job
                            }
                    }
                    
                    if pastEvents.count > 10 {
                        Button("View All Past Events") {
                            // TODO: Show all past events modal
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color.appBackground)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var weekdayHeaders: [String] {
        ["S", "M", "T", "W", "T", "F", "S"]
    }
    
    private var calendarDays: [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        
        var days: [Date] = []
        var date = startOfWeek
        
        for _ in 0..<42 { // 6 weeks x 7 days
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return days
    }
    
    private func previousMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func nextMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func loadJobs() {
        guard appState.authenticationState == .authenticated else { 
            print("🔴 Calendar jobs load skipped - user not authenticated")
            return 
        }
        
        print("🔄 Loading jobs for Calendar view...")
        isLoading = true
        Task {
            do {
                let jobs = try await jobService.getAllJobs()
                await MainActor.run {
                    print("✅ Loaded \(jobs.count) jobs for Calendar view")
                    self.supabaseJobs = jobs
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("🔴 Error loading jobs: \(error)")
                }
            }
        }
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let eventColor: Color?
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Selected background with bounce animation
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)
                        .scaleEffect(1.1)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
                
                Text(dayNumber)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isCurrentMonth ? (isSelected ? .white : .white) : .gray)
            }
            
            // Event indicator dot with fade animation
            if let eventColor = eventColor {
                Circle()
                    .fill(eventColor)
                    .opacity(isSelected ? 0.7 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(height: 50)
    }
}

// MARK: - Event Card View
struct EventCardView: View {
    let job: Job
    
    private var eventType: String {
        if job.title.lowercased().contains("casting") {
            return "Casting"
        } else {
            return "Job"
        }
    }
    
    private var eventColor: Color {
        if job.title.lowercased().contains("casting") {
            return .purple
        } else {
            return .blue
        }
    }
    
    private var dateTimeString: String {
        guard let startDate = job.startDate else { return "TBD" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy • h:mm a"
        return formatter.string(from: startDate)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Colored left border
            Rectangle()
                .fill(eventColor)
                .frame(width: 4)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(job.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(dateTimeString)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Event type badge
                    Text(eventType)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(eventColor.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(eventColor, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Past Event Card View
struct PastEventCardView: View {
    let job: Job
    
    private var eventType: String {
        if job.title.lowercased().contains("casting") {
            return "Casting"
        } else {
            return "Job"
        }
    }
    
    private var eventColor: Color {
        return .gray // Past events use gray color
    }
    
    private var dateTimeString: String {
        guard let startDate = job.startDate else { return "TBD" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy • h:mm a"
        return formatter.string(from: startDate)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Colored left border
            Rectangle()
                .fill(eventColor)
                .frame(width: 4)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(job.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(dateTimeString)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Event type badge with "Completed" status
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Completed")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.green.opacity(0.1))
                            )
                        
                        Text(eventType)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(eventColor.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(eventColor, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4).opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Calendar Integration View
struct CalendarIntegrationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingGoogleCalendarAuth = false
    @State private var showingAppleCalendarPermission = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("Connect Your Calendar")
                            .font(.system(size: 20, weight: .bold, design: .default))
                            .foregroundColor(Color.appPrimaryText)
                        
                        Text("Sync your jobs with your preferred calendar app to stay organized")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 40)
                
                VStack(spacing: 16) {
                    // Google Calendar Option
                    Button(action: {
                        showingGoogleCalendarAuth = true
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundColor(.red)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Google Calendar")
                                    .font(.headline)
                                    .foregroundColor(Color.appPrimaryText)
                                
                                Text("Sync with your Google Calendar")
                                    .font(.subheadline)
                                    .foregroundColor(Color.appSecondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundColor(Color.appSecondaryText)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appCardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                    }
                    
                    // iOS Calendar Option
                    Button(action: {
                        showingAppleCalendarPermission = true
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Apple Calendar")
                                    .font(.headline)
                                    .foregroundColor(Color.appPrimaryText)
                                
                                Text("Sync with your iPhone/iPad Calendar")
                                    .font(.subheadline)
                                    .foregroundColor(Color.appSecondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundColor(Color.appSecondaryText)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appCardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Calendar Sync Benefits")
                        .font(.headline)
                        .foregroundColor(Color.appPrimaryText)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Never miss a job or casting")
                                .font(.subheadline)
                                .foregroundColor(Color.appSecondaryText)
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Get notifications on all your devices")
                                .font(.subheadline)
                                .foregroundColor(Color.appSecondaryText)
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Share schedules with agents and teams")
                                .font(.subheadline)
                                .foregroundColor(Color.appSecondaryText)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Calendar Integration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Google Calendar", isPresented: $showingGoogleCalendarAuth) {
            Button("Cancel", role: .cancel) { }
            Button("Authorize") {
                // TODO: Implement Google Calendar authorization
                print("🔵 Google Calendar authorization requested")
            }
        } message: {
            Text("This will redirect you to Google to authorize calendar access.")
        }
        .alert("Apple Calendar", isPresented: $showingAppleCalendarPermission) {
            Button("Cancel", role: .cancel) { }
            Button("Allow") {
                // TODO: Request calendar permission
                print("🔵 Apple Calendar permission requested")
            }
        } message: {
            Text("Allow Aure to access your Calendar app to sync events.")
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(AppState())
        .modelContainer(for: [Job.self, Agency.self, Payment.self])
}