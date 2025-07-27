# DiemPay - System Architecture

## Overview

DiemPay is a modern full-stack finance management application specifically designed for fashion models. Built with React, Express, and PostgreSQL, the app helps models manage their earnings from different modeling agencies. The application features a mobile-first design with a clean, modern UI using shadcn/ui components and Tailwind CSS. Each card represents a different modeling agency the user is signed with (Soul Artist Management, Wilhelmina London, WHY NOT Management, etc.), allowing models to track their consolidated earnings and agency-specific transactions.

## System Architecture

### Frontend Architecture
- **Framework**: React 18 with TypeScript
- **Routing**: Wouter for lightweight client-side routing
- **Styling**: Tailwind CSS with custom banking theme (dark mode with lime accents)
- **UI Components**: shadcn/ui component library based on Radix UI primitives
- **State Management**: TanStack Query (React Query) for server state management
- **Build Tool**: Vite for fast development and optimized builds
- **Mobile-First**: Responsive design optimized for mobile banking experience

### Backend Architecture
- **Runtime**: Node.js with Express.js
- **Language**: TypeScript with ES modules
- **API Design**: RESTful endpoints with JSON responses
- **Error Handling**: Centralized error middleware with proper HTTP status codes
- **Logging**: Custom request/response logging for API endpoints

### Data Storage
- **Database**: PostgreSQL (configured for production)
- **ORM**: Drizzle ORM for type-safe database operations
- **Schema**: Strongly typed schema definitions shared between client and server
- **Migrations**: Drizzle Kit for database schema management
- **Development**: In-memory storage implementation for quick prototyping

## Key Components

### Database Schema
- **Users**: Model profiles with personalized greetings and welcome messages
- **Accounts**: Consolidated financial account showing total earnings across all agencies
- **Cards**: Agency cards representing different modeling agencies (Soul Artist Management, Wilhelmina London, WHY NOT Management)
- **Transactions**: Transaction history from modeling jobs, brand collaborations, and agency payments

### API Endpoints
- `GET /api/dashboard/:userId` - Retrieves complete dashboard data for a user
- `GET /api/user/:id` - Fetches individual user information

### UI Components
- **Status Bar**: Mobile-style status indicator
- **Agency Cards**: Swipeable cards showing different modeling agencies with unique colors and branding
- **Action Buttons**: Quick access to send, receive, family, and more features
- **Transactions Section**: Scrollable transaction history showing earnings from different agencies and brands
- **Bottom Navigation**: Mobile-style tab navigation
- **Referral Section**: Promotional content for agency partnerships

## Data Flow

1. **Client Request**: React components use TanStack Query to fetch data
2. **API Layer**: Express routes handle HTTP requests and validation
3. **Storage Layer**: Storage interface abstracts database operations
4. **Response**: JSON data flows back through the API to update UI state
5. **UI Updates**: React components re-render with fresh data automatically

## External Dependencies

### Core Dependencies
- **Neon Database**: Serverless PostgreSQL hosting (@neondatabase/serverless)
- **Radix UI**: Accessible component primitives for form controls and overlays
- **Lucide React**: Icon library for consistent iconography
- **React Icons**: Additional icons for brand-specific elements (Apple, Figma, Dribbble)

### Development Tools
- **TypeScript**: Type safety across the entire stack
- **ESLint/Prettier**: Code formatting and linting
- **Drizzle Kit**: Database migration and management tools

## Deployment Strategy

### Build Process
1. **Frontend Build**: Vite compiles React app to static assets in `dist/public`
2. **Backend Build**: ESBuild bundles Express server to `dist/index.js`
3. **Type Checking**: TypeScript compiler validates all code before build

### Environment Configuration
- **Database**: Uses `DATABASE_URL` environment variable for PostgreSQL connection
- **Development**: Hot reload with Vite dev server and tsx for server restart
- **Production**: Serves static frontend from Express with API routes

### File Structure
- `client/` - React frontend application
- `server/` - Express backend API
- `shared/` - Common TypeScript types and database schema
- `migrations/` - Database migration files

## Recent Changes
- July 01, 2025: Initial setup as banking app replica
- July 01, 2025: Evolved into fashion model finance management app
- July 01, 2025: Added PostgreSQL database with multi-agency card support
- July 01, 2025: Updated balance to $10,340.98 and added modeling agencies (ELITE Model Management, Wilhelmina London, WHY NOT Management)
- July 01, 2025: Implemented swipeable agency cards with unique colors and branding
- July 02, 2025: Updated each agency card to show individual balances instead of consolidated total
- July 02, 2025: Implemented light background color palette (#F5F6F8 primary, #FFFFFF cards, #E0E0E0 shadows)
- July 02, 2025: Added earnings overview card with $115,246 earned, $6,175 fees, and pending/overdue tracking
- July 02, 2025: Created dedicated upcoming payments page with agency-specific payments and status tracking
- July 02, 2025: Made "Upcoming" section in month income chart clickable to navigate to payments page
- July 02, 2025: Moved upcoming payments section from balance card to dedicated page for better organization
- July 02, 2025: Created dedicated overdue payments page with red alert theme and critical status indicators
- July 02, 2025: Made "Overdue" section in month income chart clickable to navigate to overdue payments page
- July 02, 2025: Removed earnings overview card and applied smooth animations to AI insights card
- July 02, 2025: Added comprehensive Jobs section to reports page with search, filter, and brand-specific job tracking (Calvin Klein, Apple, Mitsubishi, Louis Vuitton, L'Oréal)
- July 05, 2025: Updated available balances to show net amounts after 20% commission deductions across all accounts
- July 05, 2025: Added scrollable navigation to Jobs card with custom scrollbar styling and fade indicators
- July 05, 2025: Implemented comprehensive PDF statement parsing system with server-side processing, advanced pattern matching for clients/brands/amounts/dates, structured job extraction from agency statements, and intelligent fallback mechanisms
- July 05, 2025: Updated primary agency branding from "ELITE Model Management" to "Soul Artist Management" across all components, including reports page, job forms, agency details, and database records
- July 07, 2025: Updated "Society Management" to "WHY NOT Management" across all components and database records
- July 05, 2025: Implemented comprehensive real-time data consistency across entire application - dashboard, earnings overview, balance cards, and account details now all calculate and display data from actual job records instead of static values, ensuring synchronized updates when jobs are added/edited
- July 05, 2025: Achieved complete data consistency across ALL application components - reports page now displays real calculated earnings ($136,091 gross), agency-specific percentages, actual fee calculations ($27,218), and dynamic overdue tracking, eliminating final static values
- July 06, 2025: Implemented complete authentication system with username/password login for user "Kwakuansong" (password: Test123), updated user greeting from "Hello Rakib" to "Hello Kwaku", added login page with professional design, localStorage-based session management, and logout functionality in profile page
- July 06, 2025: Developed comprehensive onboarding flow with 4-slide carousel inspired by Wealthsimple design, mobile-first authentication screens with status bar and home indicator, added signup functionality with validation, email field, and automatic account creation
- July 06, 2025: Created multi-step signup flow matching Wealthsimple UI mockups: Email → Password → Phone → Verification (with phone keypad) → Permissions (Face ID/notifications), added post-signup get-started page with agency onboarding options
- July 07, 2025: Added minimalist splash screen inspired by Wealthsimple design with clean white background, simple typography, and 2.5-second auto-redirect to onboarding for first-time visitors only
- July 07, 2025: Rebranded application from "Model Finance" to "DiemPay" across splash screen and documentation
- July 07, 2025: Designed custom DiemPay logo with modern hexagonal container, creative flowing letterforms, inner glow effects, and professional fintech aesthetic for splash page
- July 07, 2025: Fixed division by zero error in balance card component and reorganized financial overview layout to stack Total Income above Expenses vertically instead of side-by-side grid
- July 07, 2025: Removed financial summary card and added Total Income section below Current Value using consistent design pattern with large typography and percentage badge
- July 07, 2025: Switched positions to display Total Income above Current Value, prioritizing income visibility in the dashboard layout
- July 07, 2025: Reduced Current Value font size from 40px to text-2xl (24px) to prevent overwhelming users with large numbers
- July 07, 2025: Implemented comprehensive system optimization including email-based authentication (kwaku@example.com/Test123), API rate limiting with caching in Brandfetch service, removal of excessive console logging for production performance, and tsx dependency resolution
- July 07, 2025: Updated login page text from "modeling career" to "career" for broader appeal, replaced logo with elegant DiemPay brand typography with accent line
- July 07, 2025: Created comprehensive onboarding flow that guides new users through agency creation followed by first job addition, ensuring complete dashboard data from signup through first use

## User Preferences

Preferred communication style: Simple, everyday language.
App Purpose: DiemPay helps fashion models manage their earnings from multiple modeling agencies with streamlined payment tracking and financial insights.