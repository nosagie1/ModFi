# Authentication & Onboarding Integration Guide

This guide explains how to integrate the new enhanced authentication and onboarding flows into your existing Aure app.

## 🎯 Overview

The new authentication system provides:
- **Step-by-step sign-up**: Email → Phone → Password → SMS Verification  
- **Enhanced login**: Phone/email input with optional 2FA
- **Modern onboarding**: Currency → Permissions → Agency → Confirmation
- **Complete job setup**: 7-step job creation with payment status
- **Currency formatting**: All amounts display with proper thousand separators

## 📁 Files Created

### Authentication Views
- `NewAuthenticationView.swift` - Main auth container with step-by-step flows
- `NewOnboardingView.swift` - Enhanced onboarding with currency/permissions
- `JobSetupFlowView.swift` - 7-step job creation process
- `PaymentStatusView.swift` - Payment status selection after job creation

## 🔄 Integration Steps

### 1. Replace Main Authentication View

**In `MainAppView.swift`**, replace the current authentication view:

```swift
// OLD
case .authentication:
    AuthenticationView()

// NEW
case .authentication:
    NewAuthenticationView()
```

### 2. Replace Onboarding View

**In `MainAppView.swift`**, replace the current onboarding:

```swift
// OLD  
case .onboarding:
    OnboardingView()

// NEW
case .onboarding:
    NewOnboardingView()
```

### 3. Add Job Setup Flow

**In your dashboard or wherever you want to add jobs**, present the new flow:

```swift
.sheet(isPresented: $showingJobSetup) {
    JobSetupFlowView()
}
```

### 4. Update App Navigation

The new flows integrate seamlessly with your existing `AppState` management:

- **Sign-up completion** → Automatically triggers onboarding
- **Onboarding completion** → Calls `appState.completeOnboarding()`
- **Job creation** → Can integrate with existing SwiftData models

## 🎨 Design Features

### Visual Consistency
- Uses existing app colors (`Color.appAccentBlue`, `Color.appPrimaryText`, etc.)
- Maintains dark theme compatibility
- Follows iOS Human Interface Guidelines

### Interactive Elements
- **Progress indicators** for multi-step flows
- **Real-time validation** with visual feedback
- **Smooth animations** between steps
- **Native iOS components** (DatePicker, Toggle, TextField)

### User Experience
- **Auto-formatting** for phone numbers and currency
- **Smart defaults** (payment due date = job date + 30 days)
- **Accessibility support** with proper labels
- **Keyboard optimization** for each input type

## 💰 Currency Formatting

All monetary values now display with proper formatting:
- **Thousands separators**: $1,000.00 instead of $1000.00
- **Consistent decimal places**: Always shows .00 for whole amounts
- **Currency symbols**: Proper $ prefix for USD amounts

## 🔧 Technical Details

### State Management
- Uses `@ObservableObject` classes for form data
- Integrates with existing `AppState` for authentication
- Maintains state across navigation steps

### Validation
- **Email**: Requires @ and . characters
- **Phone**: Minimum 10 digits with auto-formatting
- **Password**: Minimum 8 characters with strength indicator
- **SMS Code**: Exactly 6 digits with clipboard paste support

### Data Models
```swift
// Sign-up data
class SignUpData: ObservableObject {
    @Published var email = ""
    @Published var phoneNumber = ""
    @Published var password = ""
    @Published var smsCode = ""
    @Published var acceptedTerms = false
}

// Onboarding data  
class OnboardingData: ObservableObject {
    @Published var selectedCurrency: Currency = .usd
    @Published var faceIDEnabled = false
    @Published var notificationsEnabled = false
    @Published var agencyName = ""
}

// Job setup data
class JobSetupData: ObservableObject {
    @Published var clientName = ""
    @Published var amount: Double = 0
    @Published var commissionPercentage: Int = 20
    @Published var bookedBy = ""
    @Published var jobTitle = ""
    @Published var jobDate = Date()
    @Published var paymentDueDate = Date()
    @Published var paymentStatus: PaymentStatus = .pending
}
```

## 🚀 Next Steps

1. **Test the flows** in your development environment
2. **Customize colors/styling** if needed to match your brand
3. **Connect to your backend** by updating the authentication service calls
4. **Add analytics tracking** for conversion optimization
5. **Implement proper error handling** for production use

## 🎯 Benefits

- **Better conversion**: Step-by-step reduces form abandonment
- **Professional UX**: Modern, polished interface
- **Type safety**: Strong typing with proper validations  
- **Maintainable**: Clean, modular SwiftUI architecture
- **Accessible**: Built-in support for VoiceOver and Dynamic Type

The new authentication flows provide a significantly improved user experience while maintaining compatibility with your existing app architecture.