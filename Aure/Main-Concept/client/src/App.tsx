import { Switch, Route } from "wouter";
import { queryClient } from "./lib/queryClient";
import { QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import Dashboard from "@/pages/dashboard";
import Reports from "@/pages/reports";
import Profile from "@/pages/profile";
import AgencyDetails from "@/pages/agency-details";
import AccountDetails from "@/pages/account-details";
import JobsPage from "@/pages/jobs";
import Notifications from "@/pages/notifications";
import UpcomingPayments from "@/pages/upcoming-payments";
import OverduePayments from "@/pages/overdue-payments";
import LoginPage from "@/pages/login";
import SignupPage from "@/pages/signup";
import SplashPage from "@/pages/splash";
import OnboardingPage from "@/pages/onboarding";
import GetStartedPage from "@/pages/get-started";
import AddAgencyOnboardingPage from "@/pages/add-agency-onboarding";
import AddFirstJob from "@/pages/add-first-job";
import NotFound from "@/pages/not-found";
import { useState, useEffect } from "react";

function Router() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [showSplash, setShowSplash] = useState(true);

  useEffect(() => {
    // Check if user is already authenticated - skip splash for logged in users
    const userAuthenticated = localStorage.getItem("userAuthenticated");
    
    if (userAuthenticated === "true") {
      // User is logged in - skip splash
      setShowSplash(false);
    } else {
      // Check if this is first visit for non-authenticated users
      const hasVisited = localStorage.getItem("hasVisited");
      
      if (!hasVisited) {
        // First time visitor - show splash
        setShowSplash(true);
      } else {
        // Returning visitor - skip splash
        setShowSplash(false);
      }
    }

    // Listen for hasVisited changes to hide splash
    const handleSplashStorageChange = () => {
      if (localStorage.getItem("hasVisited") || localStorage.getItem("userAuthenticated") === "true") {
        setShowSplash(false);
      }
    };

    window.addEventListener('storage', handleSplashStorageChange);

    // Check authentication status
    const checkAuthStatus = () => {
      try {
        const userAuthenticated = localStorage.getItem("userAuthenticated");
        const currentUserId = localStorage.getItem("currentUserId");
        
        // If user ID is 1 (invalid), force fallback to demo user
        if (currentUserId === "1") {
          localStorage.setItem("currentUserId", "9");
          localStorage.setItem("userAuthenticated", "true");
          setIsAuthenticated(true);
        } else if (userAuthenticated === "true" && currentUserId) {
          setIsAuthenticated(true);
        } else {
          setIsAuthenticated(false);
        }
      } catch (error) {
        setIsAuthenticated(false);
      }
      setIsLoading(false);
    };

    // Initial check
    checkAuthStatus();

    // Listen for storage changes (when user logs in from the same tab)
    const handleStorageChange = () => {
      checkAuthStatus();
    };

    // Custom event for same-tab login
    window.addEventListener('storage', handleStorageChange);
    window.addEventListener('authStateChange', handleStorageChange);

    return () => {
      window.removeEventListener('storage', handleSplashStorageChange);
      window.removeEventListener('storage', handleStorageChange);
      window.removeEventListener('authStateChange', handleStorageChange);
    };
  }, []);

  // Show splash screen for first-time visitors
  if (showSplash) {
    return <SplashPage />;
  }

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return (
      <Switch>
        <Route path="/" component={SplashPage} />
        <Route path="/onboarding" component={OnboardingPage} />
        <Route path="/login" component={LoginPage} />
        <Route path="/signup" component={SignupPage} />
        <Route path="/onboarding" component={OnboardingPage} />
        <Route component={OnboardingPage} />
      </Switch>
    );
  }

  return (
    <Switch>
      <Route path="/" component={Dashboard} />
      <Route path="/get-started" component={GetStartedPage} />
      <Route path="/add-agency-onboarding" component={AddAgencyOnboardingPage} />
      <Route path="/add-first-job" component={AddFirstJob} />
      <Route path="/reports" component={Reports} />
      <Route path="/profile" component={Profile} />
      <Route path="/agency/:agencyName">
        {params => <AgencyDetails agencyName={params.agencyName} />}
      </Route>
      <Route path="/account/:accountName">
        {params => <AccountDetails accountName={params.accountName} />}
      </Route>
      <Route path="/jobs/:accountName">
        {params => <JobsPage accountName={params.accountName} />}
      </Route>
      <Route path="/notifications" component={Notifications} />
      <Route path="/upcoming-payments" component={UpcomingPayments} />
      <Route path="/overdue-payments" component={OverduePayments} />
      <Route path="/login" component={() => { window.location.href = "/"; return null; }} />
      <Route component={NotFound} />
    </Switch>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <Toaster />
        <Router />
      </TooltipProvider>
    </QueryClientProvider>
  );
}

export default App;
