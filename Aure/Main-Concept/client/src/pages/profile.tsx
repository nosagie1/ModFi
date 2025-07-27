import { useState, useEffect } from "react";
import BottomNavigation from "@/components/bottom-navigation";
import { User, Settings, Bell, CreditCard, HelpCircle, LogOut, ArrowLeft } from "lucide-react";
import { useQuery } from "@tanstack/react-query";
import { useLocation } from "wouter";
import type { Job } from "@shared/schema";

export default function Profile() {
  const [, setLocation] = useLocation();
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  
  useEffect(() => {
    // Get authenticated user ID from localStorage
    const userId = localStorage.getItem("currentUserId");
    setCurrentUserId(userId);
  }, []);
  
  // Fetch dashboard data to get user info
  const { data: dashboardData } = useQuery<{
    user: {name: string; id: number};
    account: any;
    cards: any[];
    transactions: any[];
  }>({
    queryKey: [`/api/dashboard/${currentUserId}`],
    enabled: !!currentUserId,
  });

  const handleLogout = () => {
    // Clear authentication data
    localStorage.removeItem("userAuthenticated");
    localStorage.removeItem("currentUserId");
    
    // Trigger auth state change event
    window.dispatchEvent(new Event('authStateChange'));
  };

  // Fetch jobs data to calculate real statistics
  const { data: jobs = [] } = useQuery<Job[]>({
    queryKey: [`/api/jobs/${currentUserId}`],
    enabled: !!currentUserId,
  });

  // Calculate real statistics from job data
  const totalBookings = jobs.length;
  const totalEarnings = jobs.reduce((sum, job) => sum + parseFloat(job.amount), 0);
  const availableBalance = totalEarnings * 0.8; // After 20% commission
  const uniqueAgencies = new Set(jobs.map(job => job.bookedBy)).size;

  return (
    <div className="max-w-sm mx-auto bg-background min-h-screen relative">
      
      {/* Header */}
      <div className="px-6 py-4">
        <div className="flex justify-between items-start">
          <div className="flex items-center space-x-3">
            <button 
              onClick={() => setLocation("/")}
              className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-full transition-colors"
            >
              <ArrowLeft className="h-5 w-5 text-gray-600 dark:text-gray-400" />
            </button>
            <div>
              <h1 className="text-xl font-semibold text-foreground">Profile</h1>
              <p className="text-muted-foreground text-sm">Manage your account</p>
            </div>
          </div>
        </div>
      </div>

      {/* Profile Info */}
      <div className="px-6 mb-6">
        <div className="bg-card border border-border rounded-3xl p-6 banking-shadow">
          <div className="flex items-center space-x-4">
            <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
              <span className="text-white text-xl font-bold">
                {dashboardData?.user?.name?.charAt(0) || 'R'}
              </span>
            </div>
            <div>
              <h2 className="text-foreground text-lg font-semibold">
                {dashboardData?.user?.name || 'Rakib'}
              </h2>
              <p className="text-muted-foreground text-sm">Fashion Model</p>
              <p className="text-muted-foreground text-xs">Member since 2024</p>
            </div>
          </div>
        </div>
      </div>

      

      {/* Menu Options */}
      <div className="px-6 mb-20">
        <div className="bg-card border border-border rounded-3xl p-6 banking-shadow">
          <div className="space-y-4">
            <div className="flex items-center justify-between p-3 hover:bg-muted rounded-lg transition-colors">
              <div className="flex items-center space-x-3">
                <Settings className="w-5 h-5 text-muted-foreground" />
                <span className="text-foreground font-medium">Account Settings</span>
              </div>
              <div className="w-2 h-2 bg-muted-foreground rounded-full"></div>
            </div>
            
            <div className="flex items-center justify-between p-3 hover:bg-muted rounded-lg transition-colors">
              <div className="flex items-center space-x-3">
                <Bell className="w-5 h-5 text-muted-foreground" />
                <span className="text-foreground font-medium">Notifications</span>
              </div>
              <div className="w-2 h-2 bg-muted-foreground rounded-full"></div>
            </div>
            
            <div className="flex items-center justify-between p-3 hover:bg-muted rounded-lg transition-colors">
              <div className="flex items-center space-x-3">
                <CreditCard className="w-5 h-5 text-muted-foreground" />
                <span className="text-foreground font-medium">Payment Methods</span>
              </div>
              <div className="w-2 h-2 bg-muted-foreground rounded-full"></div>
            </div>
            
            <div className="flex items-center justify-between p-3 hover:bg-muted rounded-lg transition-colors">
              <div className="flex items-center space-x-3">
                <HelpCircle className="w-5 h-5 text-muted-foreground" />
                <span className="text-foreground font-medium">Help & Support</span>
              </div>
              <div className="w-2 h-2 bg-muted-foreground rounded-full"></div>
            </div>
            
            <div className="border-t border-border pt-4">
              <div 
                className="flex items-center justify-between p-3 hover:bg-red-50 rounded-lg transition-colors cursor-pointer"
                onClick={handleLogout}
              >
                <div className="flex items-center space-x-3">
                  <LogOut className="w-5 h-5 text-red-500" />
                  <span className="text-red-500 font-medium">Sign Out</span>
                </div>
                <div className="w-2 h-2 bg-red-500 rounded-full"></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <BottomNavigation />
    </div>
  );
}