//
//  CustomIcons.swift
//  Aure
//
//  Custom icon implementations to match design requirements
//

import SwiftUI

// MARK: - Custom Home Icon
struct CustomHomeIcon: View {
    let size: CGFloat
    let strokeWidth: CGFloat
    
    init(size: CGFloat = 16, strokeWidth: CGFloat = 1.5) {
        self.size = size
        self.strokeWidth = strokeWidth
    }
    
    var body: some View {
        Canvas { context, canvasSize in
            let width = canvasSize.width
            let height = canvasSize.height
            
            // Scale factor to fit the design in the available space
            let scale = min(width, height) / 24
            
            // Center the drawing
            let offsetX = (width - 24 * scale) / 2
            let offsetY = (height - 24 * scale) / 2
            
            context.translateBy(x: offsetX, y: offsetY)
            context.scaleBy(x: scale, y: scale)
            
            // Create the path matching the SVG
            var path = Path()
            
            // Roof line - from bottom left of roof to peak to bottom right
            // M 2.25 12 l 8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12
            path.move(to: CGPoint(x: 2.25, y: 12))
            path.addLine(to: CGPoint(x: 11.204, y: 3.045)) // 2.25 + 8.954, 12 - 8.955
            // Add the curved peak (simplified as straight lines for now)
            path.addLine(to: CGPoint(x: 12.795, y: 3.045)) // Peak with width
            path.addLine(to: CGPoint(x: 21.75, y: 12))
            
            // House body - left wall
            // M 4.5 9.75 v 10.125c0 .621.504 1.125 1.125 1.125H9.75
            var housePath = Path()
            housePath.move(to: CGPoint(x: 4.5, y: 9.75))
            housePath.addLine(to: CGPoint(x: 4.5, y: 19.875)) // 9.75 + 10.125
            housePath.addLine(to: CGPoint(x: 9.75, y: 19.875))
            
            // Door area
            // v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21
            housePath.addLine(to: CGPoint(x: 9.75, y: 15)) // 19.875 - 4.875
            housePath.addLine(to: CGPoint(x: 14.25, y: 15)) // 9.75 + 2.25 + 2.25
            housePath.addLine(to: CGPoint(x: 14.25, y: 21))
            
            // Right wall
            // h4.125c.621 0 1.125-.504 1.125-1.125V9.75
            housePath.addLine(to: CGPoint(x: 18.375, y: 21)) // 14.25 + 4.125
            housePath.addLine(to: CGPoint(x: 19.5, y: 21))
            housePath.addLine(to: CGPoint(x: 19.5, y: 9.75))
            
            // Bottom line
            // M8.25 21h8.25
            var bottomPath = Path()
            bottomPath.move(to: CGPoint(x: 8.25, y: 21))
            bottomPath.addLine(to: CGPoint(x: 16.5, y: 21))
            
            // Draw the paths
            context.stroke(path, with: .color(Color.primary), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            context.stroke(housePath, with: .color(Color.primary), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            context.stroke(bottomPath, with: .color(Color.primary), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Custom Home Icon Filled
struct CustomHomeIconFilled: View {
    let size: CGFloat
    let strokeWidth: CGFloat
    
    init(size: CGFloat = 16, strokeWidth: CGFloat = 1.5) {
        self.size = size
        self.strokeWidth = strokeWidth
    }
    
    var body: some View {
        Canvas { context, canvasSize in
            let width = canvasSize.width
            let height = canvasSize.height
            
            // Scale factor to fit the design in the available space
            let scale = min(width, height) / 24
            
            // Center the drawing
            let offsetX = (width - 24 * scale) / 2
            let offsetY = (height - 24 * scale) / 2
            
            context.translateBy(x: offsetX, y: offsetY)
            context.scaleBy(x: scale, y: scale)
            
            // Create filled paths
            var housePath = Path()
            
            // Roof triangle (filled)
            housePath.move(to: CGPoint(x: 2.25, y: 12))
            housePath.addLine(to: CGPoint(x: 12, y: 2.5))
            housePath.addLine(to: CGPoint(x: 21.75, y: 12))
            housePath.addLine(to: CGPoint(x: 19.5, y: 12))
            housePath.addLine(to: CGPoint(x: 12, y: 4.5))
            housePath.addLine(to: CGPoint(x: 4.5, y: 12))
            housePath.closeSubpath()
            
            // House body (filled)
            var bodyPath = Path()
            bodyPath.move(to: CGPoint(x: 4.5, y: 12))
            bodyPath.addLine(to: CGPoint(x: 4.5, y: 21))
            bodyPath.addLine(to: CGPoint(x: 19.5, y: 21))
            bodyPath.addLine(to: CGPoint(x: 19.5, y: 12))
            bodyPath.closeSubpath()
            
            // Door cutout (unfilled area)
            var doorPath = Path()
            doorPath.move(to: CGPoint(x: 9.75, y: 21))
            doorPath.addLine(to: CGPoint(x: 9.75, y: 15))
            doorPath.addLine(to: CGPoint(x: 14.25, y: 15))
            doorPath.addLine(to: CGPoint(x: 14.25, y: 21))
            doorPath.closeSubpath()
            
            // Fill the house (roof and body)
            context.fill(housePath, with: .color(Color.primary))
            context.fill(bodyPath, with: .color(Color.primary))
            
            // Cut out the door area
            context.blendMode = .destinationOut
            context.fill(doorPath, with: .color(Color.primary))
            context.blendMode = .normal
            
            // Stroke the door outline
            context.stroke(doorPath, with: .color(Color.primary), style: StrokeStyle(lineWidth: strokeWidth * 0.7, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Custom Jobs Icon
struct CustomJobsIcon: View {
    let size: CGFloat
    let strokeWidth: CGFloat
    
    init(size: CGFloat = 16, strokeWidth: CGFloat = 1.5) {
        self.size = size
        self.strokeWidth = strokeWidth
    }
    
    var body: some View {
        Canvas { context, canvasSize in
            let width = canvasSize.width
            let height = canvasSize.height
            
            // Scale factor to fit the design in the available space
            let scale = min(width, height) / 24
            
            // Center the drawing
            let offsetX = (width - 24 * scale) / 2
            let offsetY = (height - 24 * scale) / 2
            
            context.translateBy(x: offsetX, y: offsetY)
            context.scaleBy(x: scale, y: scale)
            
            // Create the path matching the briefcase SVG
            var path = Path()
            
            // Top section with handle
            // M20.25 14.15v4.25c0 1.094-.787 2.036-1.872 2.18-2.087.277-4.216.42-6.378.42s-4.291-.143-6.378-.42c-1.085-.144-1.872-1.086-1.872-2.18v-4.25
            path.move(to: CGPoint(x: 20.25, y: 14.15))
            path.addLine(to: CGPoint(x: 20.25, y: 18.4)) // v4.25
            
            // Rounded top right corner and bottom edge
            path.addCurve(to: CGPoint(x: 18.378, y: 20.58), 
                         control1: CGPoint(x: 20.25, y: 19.494), 
                         control2: CGPoint(x: 19.463, y: 20.436))
            
            // Bottom curved section
            path.addCurve(to: CGPoint(x: 12, y: 21), 
                         control1: CGPoint(x: 16.291, y: 20.857), 
                         control2: CGPoint(x: 14.162, y: 21))
            
            path.addCurve(to: CGPoint(x: 5.622, y: 20.58), 
                         control1: CGPoint(x: 9.838, y: 21), 
                         control2: CGPoint(x: 7.709, y: 20.857))
            
            path.addCurve(to: CGPoint(x: 3.75, y: 18.4), 
                         control1: CGPoint(x: 4.537, y: 20.436), 
                         control2: CGPoint(x: 3.75, y: 19.494))
            
            path.addLine(to: CGPoint(x: 3.75, y: 14.15))
            
            // Middle section
            // m16.5 0a2.18 2.18 0 0 0 .75-1.661V8.706c0-1.081-.768-2.015-1.837-2.175a48.114 48.114 0 0 0-3.413-.387
            var middlePath = Path()
            middlePath.move(to: CGPoint(x: 20.25, y: 14.15))
            middlePath.addCurve(to: CGPoint(x: 21, y: 12.489), 
                              control1: CGPoint(x: 20.644, y: 13.985), 
                              control2: CGPoint(x: 21, y: 13.324))
            middlePath.addLine(to: CGPoint(x: 21, y: 8.706))
            
            // Top section curves
            middlePath.addCurve(to: CGPoint(x: 19.163, y: 6.531), 
                              control1: CGPoint(x: 21, y: 7.625), 
                              control2: CGPoint(x: 20.232, y: 6.691))
            
            middlePath.addCurve(to: CGPoint(x: 15.75, y: 6.144), 
                              control1: CGPoint(x: 18.076, y: 6.254), 
                              control2: CGPoint(x: 16.947, y: 6.144))
            
            // Left side mirror
            var leftPath = Path()
            leftPath.move(to: CGPoint(x: 3.75, y: 14.15))
            leftPath.addCurve(to: CGPoint(x: 3, y: 12.489), 
                            control1: CGPoint(x: 3.356, y: 13.985), 
                            control2: CGPoint(x: 3, y: 13.324))
            leftPath.addLine(to: CGPoint(x: 3, y: 8.706))
            
            leftPath.addCurve(to: CGPoint(x: 4.837, y: 6.531), 
                            control1: CGPoint(x: 3, y: 7.625), 
                            control2: CGPoint(x: 3.768, y: 6.691))
            
            leftPath.addCurve(to: CGPoint(x: 8.25, y: 6.144), 
                            control1: CGPoint(x: 5.924, y: 6.254), 
                            control2: CGPoint(x: 7.053, y: 6.144))
            
            // Handle section at top
            // m7.5 0V5.25A2.25 2.25 0 0 0 13.5 3h-3a2.25 2.25 0 0 0-2.25 2.25v.894
            var handlePath = Path()
            handlePath.move(to: CGPoint(x: 15.75, y: 6.144))
            handlePath.addLine(to: CGPoint(x: 15.75, y: 5.25))
            handlePath.addCurve(to: CGPoint(x: 13.5, y: 3), 
                              control1: CGPoint(x: 15.75, y: 4.006), 
                              control2: CGPoint(x: 14.744, y: 3))
            handlePath.addLine(to: CGPoint(x: 10.5, y: 3))
            handlePath.addCurve(to: CGPoint(x: 8.25, y: 5.25), 
                              control1: CGPoint(x: 9.256, y: 3), 
                              control2: CGPoint(x: 8.25, y: 4.006))
            handlePath.addLine(to: CGPoint(x: 8.25, y: 6.144))
            
            // Center dot
            // M12 12.75h.008v.008H12v-.008
            var dotPath = Path()
            dotPath.addRect(CGRect(x: 12, y: 12.75, width: 0.008, height: 0.008))
            
            // Draw all paths
            context.stroke(path, with: .color(Color.primary), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            context.stroke(middlePath, with: .color(Color.primary), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            context.stroke(leftPath, with: .color(Color.primary), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            context.stroke(handlePath, with: .color(Color.primary), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            context.fill(Path(ellipseIn: CGRect(x: 11.5, y: 12.25, width: 1, height: 1)), with: .color(Color.primary))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Custom Jobs Icon Filled
struct CustomJobsIconFilled: View {
    let size: CGFloat
    let strokeWidth: CGFloat
    
    init(size: CGFloat = 16, strokeWidth: CGFloat = 1.5) {
        self.size = size
        self.strokeWidth = strokeWidth
    }
    
    var body: some View {
        Canvas { context, canvasSize in
            let width = canvasSize.width
            let height = canvasSize.height
            
            // Scale factor to fit the design in the available space
            let scale = min(width, height) / 24
            
            // Center the drawing
            let offsetX = (width - 24 * scale) / 2
            let offsetY = (height - 24 * scale) / 2
            
            context.translateBy(x: offsetX, y: offsetY)
            context.scaleBy(x: scale, y: scale)
            
            // Create filled briefcase body
            var briefcasePath = Path()
            
            // Main briefcase body (simplified filled version)
            briefcasePath.move(to: CGPoint(x: 3.75, y: 14.15))
            briefcasePath.addLine(to: CGPoint(x: 3.75, y: 18.4))
            briefcasePath.addCurve(to: CGPoint(x: 5.622, y: 20.58), 
                                 control1: CGPoint(x: 3.75, y: 19.494), 
                                 control2: CGPoint(x: 4.537, y: 20.436))
            briefcasePath.addCurve(to: CGPoint(x: 12, y: 21), 
                                 control1: CGPoint(x: 7.709, y: 20.857), 
                                 control2: CGPoint(x: 9.838, y: 21))
            briefcasePath.addCurve(to: CGPoint(x: 18.378, y: 20.58), 
                                 control1: CGPoint(x: 14.162, y: 21), 
                                 control2: CGPoint(x: 16.291, y: 20.857))
            briefcasePath.addCurve(to: CGPoint(x: 20.25, y: 18.4), 
                                 control1: CGPoint(x: 19.463, y: 20.436), 
                                 control2: CGPoint(x: 20.25, y: 19.494))
            briefcasePath.addLine(to: CGPoint(x: 20.25, y: 14.15))
            
            // Connect to top section
            briefcasePath.addCurve(to: CGPoint(x: 21, y: 12.489), 
                                 control1: CGPoint(x: 20.644, y: 13.985), 
                                 control2: CGPoint(x: 21, y: 13.324))
            briefcasePath.addLine(to: CGPoint(x: 21, y: 8.706))
            briefcasePath.addCurve(to: CGPoint(x: 19.163, y: 6.531), 
                                 control1: CGPoint(x: 21, y: 7.625), 
                                 control2: CGPoint(x: 20.232, y: 6.691))
            briefcasePath.addCurve(to: CGPoint(x: 15.75, y: 6.144), 
                                 control1: CGPoint(x: 18.076, y: 6.254), 
                                 control2: CGPoint(x: 16.947, y: 6.144))
            
            // Handle
            briefcasePath.addLine(to: CGPoint(x: 15.75, y: 5.25))
            briefcasePath.addCurve(to: CGPoint(x: 13.5, y: 3), 
                                 control1: CGPoint(x: 15.75, y: 4.006), 
                                 control2: CGPoint(x: 14.744, y: 3))
            briefcasePath.addLine(to: CGPoint(x: 10.5, y: 3))
            briefcasePath.addCurve(to: CGPoint(x: 8.25, y: 5.25), 
                                 control1: CGPoint(x: 9.256, y: 3), 
                                 control2: CGPoint(x: 8.25, y: 4.006))
            briefcasePath.addLine(to: CGPoint(x: 8.25, y: 6.144))
            
            // Left side
            briefcasePath.addCurve(to: CGPoint(x: 4.837, y: 6.531), 
                                 control1: CGPoint(x: 7.053, y: 6.144), 
                                 control2: CGPoint(x: 5.924, y: 6.254))
            briefcasePath.addCurve(to: CGPoint(x: 3, y: 8.706), 
                                 control1: CGPoint(x: 3.768, y: 6.691), 
                                 control2: CGPoint(x: 3, y: 7.625))
            briefcasePath.addLine(to: CGPoint(x: 3, y: 12.489))
            briefcasePath.addCurve(to: CGPoint(x: 3.75, y: 14.15), 
                                 control1: CGPoint(x: 3, y: 13.324), 
                                 control2: CGPoint(x: 3.356, y: 13.985))
            briefcasePath.closeSubpath()
            
            // Fill the briefcase
            context.fill(briefcasePath, with: .color(Color.primary))
            
            // Add center lock dot
            context.fill(Path(ellipseIn: CGRect(x: 11.5, y: 12.25, width: 1, height: 1)), with: .color(.white))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Custom Calendar Icon
struct CustomCalendarIcon: View {
    let size: CGFloat
    let strokeWidth: CGFloat
    
    init(size: CGFloat = 16, strokeWidth: CGFloat = 1.5) {
        self.size = size
        self.strokeWidth = strokeWidth
    }
    
    var body: some View {
        Canvas { context, canvasSize in
            let width = canvasSize.width
            let height = canvasSize.height
            
            // Scale factor to fit the design in the available space
            let scale = min(width, height) / 24
            
            // Center the drawing
            let offsetX = (width - 24 * scale) / 2
            let offsetY = (height - 24 * scale) / 2
            
            context.translateBy(x: offsetX, y: offsetY)
            context.scaleBy(x: scale, y: scale)
            
            // Create the path matching the calendar SVG
            
            // Top pins/tabs
            // M6.75 3v2.25M17.25 3v2.25
            var topPinsPath = Path()
            topPinsPath.move(to: CGPoint(x: 6.75, y: 3))
            topPinsPath.addLine(to: CGPoint(x: 6.75, y: 5.25))
            
            topPinsPath.move(to: CGPoint(x: 17.25, y: 3))
            topPinsPath.addLine(to: CGPoint(x: 17.25, y: 5.25))
            
            // Main calendar body
            // M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75
            var mainBodyPath = Path()
            mainBodyPath.move(to: CGPoint(x: 3, y: 18.75))
            mainBodyPath.addLine(to: CGPoint(x: 3, y: 7.5))
            
            // Top left corner curve
            mainBodyPath.addCurve(to: CGPoint(x: 5.25, y: 5.25), 
                                control1: CGPoint(x: 3, y: 6.257), 
                                control2: CGPoint(x: 4.007, y: 5.25))
            
            // Top edge
            mainBodyPath.addLine(to: CGPoint(x: 18.75, y: 5.25))
            
            // Top right corner curve  
            mainBodyPath.addCurve(to: CGPoint(x: 21, y: 7.5), 
                                control1: CGPoint(x: 19.993, y: 5.25), 
                                control2: CGPoint(x: 21, y: 6.257))
            
            // Right edge
            mainBodyPath.addLine(to: CGPoint(x: 21, y: 18.75))
            
            // Bottom right corner curve
            mainBodyPath.addCurve(to: CGPoint(x: 18.75, y: 21), 
                                control1: CGPoint(x: 21, y: 19.993), 
                                control2: CGPoint(x: 19.993, y: 21))
            
            // Bottom edge
            mainBodyPath.addLine(to: CGPoint(x: 5.25, y: 21))
            
            // Bottom left corner curve
            mainBodyPath.addCurve(to: CGPoint(x: 3, y: 18.75), 
                                control1: CGPoint(x: 4.007, y: 21), 
                                control2: CGPoint(x: 3, y: 19.993))
            
            // Calendar header separator
            // m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5
            var headerSeparatorPath = Path()
            headerSeparatorPath.move(to: CGPoint(x: 3, y: 11.25))
            headerSeparatorPath.addLine(to: CGPoint(x: 21, y: 11.25))
            
            // Draw all paths
            context.stroke(topPinsPath, with: .color(Color.primary), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            context.stroke(mainBodyPath, with: .color(Color.primary), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            context.stroke(headerSeparatorPath, with: .color(Color.primary), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Custom Calendar Icon Filled
struct CustomCalendarIconFilled: View {
    let size: CGFloat
    let strokeWidth: CGFloat
    
    init(size: CGFloat = 16, strokeWidth: CGFloat = 1.5) {
        self.size = size
        self.strokeWidth = strokeWidth
    }
    
    var body: some View {
        Canvas { context, canvasSize in
            let width = canvasSize.width
            let height = canvasSize.height
            
            // Scale factor to fit the design in the available space
            let scale = min(width, height) / 24
            
            // Center the drawing
            let offsetX = (width - 24 * scale) / 2
            let offsetY = (height - 24 * scale) / 2
            
            context.translateBy(x: offsetX, y: offsetY)
            context.scaleBy(x: scale, y: scale)
            
            // Create filled calendar body
            var calendarPath = Path()
            
            // Main calendar body with rounded corners
            calendarPath.move(to: CGPoint(x: 3, y: 7.5))
            calendarPath.addCurve(to: CGPoint(x: 5.25, y: 5.25), 
                                control1: CGPoint(x: 3, y: 6.257), 
                                control2: CGPoint(x: 4.007, y: 5.25))
            calendarPath.addLine(to: CGPoint(x: 18.75, y: 5.25))
            calendarPath.addCurve(to: CGPoint(x: 21, y: 7.5), 
                                control1: CGPoint(x: 19.993, y: 5.25), 
                                control2: CGPoint(x: 21, y: 6.257))
            calendarPath.addLine(to: CGPoint(x: 21, y: 18.75))
            calendarPath.addCurve(to: CGPoint(x: 18.75, y: 21), 
                                control1: CGPoint(x: 21, y: 19.993), 
                                control2: CGPoint(x: 19.993, y: 21))
            calendarPath.addLine(to: CGPoint(x: 5.25, y: 21))
            calendarPath.addCurve(to: CGPoint(x: 3, y: 18.75), 
                                control1: CGPoint(x: 4.007, y: 21), 
                                control2: CGPoint(x: 3, y: 19.993))
            calendarPath.closeSubpath()
            
            // Fill main calendar body
            context.fill(calendarPath, with: .color(Color.primary))
            
            // Add header separator line (slightly lighter)
            var headerLine = Path()
            headerLine.move(to: CGPoint(x: 3, y: 11.25))
            headerLine.addLine(to: CGPoint(x: 21, y: 11.25))
            context.stroke(headerLine, with: .color(.white), style: StrokeStyle(lineWidth: strokeWidth * 0.8, lineCap: .round))
            
            // Add top binding pins (cut out from filled body)
            var leftPin = Path()
            leftPin.addRect(CGRect(x: 6.25, y: 2.5, width: 1, height: 3))
            
            var rightPin = Path()
            rightPin.addRect(CGRect(x: 16.75, y: 2.5, width: 1, height: 3))
            
            // Fill the pins with background color to create cutout effect
            context.fill(leftPin, with: .color(.white))
            context.fill(rightPin, with: .color(.white))
            
            // Stroke the pin outlines
            context.stroke(leftPin, with: .color(Color.primary), style: StrokeStyle(lineWidth: strokeWidth * 0.8, lineCap: .round))
            context.stroke(rightPin, with: .color(Color.primary), style: StrokeStyle(lineWidth: strokeWidth * 0.8, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Custom Profile Icon
struct CustomProfileIcon: View {
    let size: CGFloat
    let strokeWidth: CGFloat
    
    init(size: CGFloat = 16, strokeWidth: CGFloat = 1.5) {
        self.size = size
        self.strokeWidth = strokeWidth
    }
    
    var body: some View {
        Canvas { context, canvasSize in
            let width = canvasSize.width
            let height = canvasSize.height
            
            // Scale factor to fit the design in the available space
            let scale = min(width, height) / 24
            
            // Center the drawing
            let offsetX = (width - 24 * scale) / 2
            let offsetY = (height - 24 * scale) / 2
            
            context.translateBy(x: offsetX, y: offsetY)
            context.scaleBy(x: scale, y: scale)
            
            // Create the path matching a person icon
            var path = Path()
            
            // Head circle
            path.addEllipse(in: CGRect(x: 8, y: 4, width: 8, height: 8))
            
            // Body path
            var bodyPath = Path()
            bodyPath.move(to: CGPoint(x: 4, y: 20))
            bodyPath.addCurve(to: CGPoint(x: 8, y: 16), 
                            control1: CGPoint(x: 4, y: 18), 
                            control2: CGPoint(x: 6, y: 16))
            bodyPath.addLine(to: CGPoint(x: 16, y: 16))
            bodyPath.addCurve(to: CGPoint(x: 20, y: 20), 
                            control1: CGPoint(x: 18, y: 16), 
                            control2: CGPoint(x: 20, y: 18))
            bodyPath.addLine(to: CGPoint(x: 20, y: 22))
            bodyPath.addLine(to: CGPoint(x: 4, y: 22))
            bodyPath.closeSubpath()
            
            // Draw the paths
            context.stroke(path, with: .color(Color.primary), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            context.stroke(bodyPath, with: .color(Color.primary), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Custom Profile Icon Filled
struct CustomProfileIconFilled: View {
    let size: CGFloat
    let strokeWidth: CGFloat
    
    init(size: CGFloat = 16, strokeWidth: CGFloat = 1.5) {
        self.size = size
        self.strokeWidth = strokeWidth
    }
    
    var body: some View {
        Canvas { context, canvasSize in
            let width = canvasSize.width
            let height = canvasSize.height
            
            // Scale factor to fit the design in the available space
            let scale = min(width, height) / 24
            
            // Center the drawing
            let offsetX = (width - 24 * scale) / 2
            let offsetY = (height - 24 * scale) / 2
            
            context.translateBy(x: offsetX, y: offsetY)
            context.scaleBy(x: scale, y: scale)
            
            // Create filled paths
            var headPath = Path()
            headPath.addEllipse(in: CGRect(x: 8, y: 4, width: 8, height: 8))
            
            // Body path (filled)
            var bodyPath = Path()
            bodyPath.move(to: CGPoint(x: 4, y: 20))
            bodyPath.addCurve(to: CGPoint(x: 8, y: 16), 
                            control1: CGPoint(x: 4, y: 18), 
                            control2: CGPoint(x: 6, y: 16))
            bodyPath.addLine(to: CGPoint(x: 16, y: 16))
            bodyPath.addCurve(to: CGPoint(x: 20, y: 20), 
                            control1: CGPoint(x: 18, y: 16), 
                            control2: CGPoint(x: 20, y: 18))
            bodyPath.addLine(to: CGPoint(x: 20, y: 22))
            bodyPath.addLine(to: CGPoint(x: 4, y: 22))
            bodyPath.closeSubpath()
            
            // Fill both head and body
            context.fill(headPath, with: .color(Color.primary))
            context.fill(bodyPath, with: .color(Color.primary))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Custom Icon Preview
#Preview {
    VStack(spacing: 30) {
        Text("Outline Icons")
            .foregroundColor(.white)
            .font(.headline)
        
        HStack(spacing: 30) {
            VStack(spacing: 10) {
                Text("Home")
                    .foregroundColor(.white)
                    .font(.caption)
                CustomHomeIcon(size: 32)
            }
            
            VStack(spacing: 10) {
                Text("Jobs")
                    .foregroundColor(.white)
                    .font(.caption)
                CustomJobsIcon(size: 32)
            }
            
            VStack(spacing: 10) {
                Text("Calendar")
                    .foregroundColor(.white)
                    .font(.caption)
                CustomCalendarIcon(size: 32)
            }
            
            VStack(spacing: 10) {
                Text("Profile")
                    .foregroundColor(.white)
                    .font(.caption)
                CustomProfileIcon(size: 32)
            }
        }
        
        Text("Filled Icons")
            .foregroundColor(.white)
            .font(.headline)
        
        HStack(spacing: 30) {
            VStack(spacing: 10) {
                Text("Home")
                    .foregroundColor(.white)
                    .font(.caption)
                CustomHomeIconFilled(size: 32)
            }
            
            VStack(spacing: 10) {
                Text("Jobs")
                    .foregroundColor(.white)
                    .font(.caption)
                CustomJobsIconFilled(size: 32)
            }
            
            VStack(spacing: 10) {
                Text("Calendar")
                    .foregroundColor(.white)
                    .font(.caption)
                CustomCalendarIconFilled(size: 32)
            }
            
            VStack(spacing: 10) {
                Text("Profile")
                    .foregroundColor(.white)
                    .font(.caption)
                CustomProfileIconFilled(size: 32)
            }
        }
    }
    .padding()
    .background(Color.black)
    .foregroundColor(.white)
}