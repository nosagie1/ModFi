import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useLocation } from "wouter";
import { useState, useEffect } from "react";
import BalanceCard from "@/components/balance-card";
import MonthIncomeChart from "@/components/month-income-chart";
import DeductionsOverview from "@/components/deductions-overview";
import BottomNavigation from "@/components/bottom-navigation";
import AddAgencyModal from "@/components/add-agency-modal";
import { Bell, FileText, Briefcase, User, ArrowLeft } from "lucide-react";
import type { Job, InsertAgency } from "@shared/schema";

export default function Dashboard() {
  const [isAddAgencyModalOpen, setIsAddAgencyModalOpen] = useState(false);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const queryClient = useQueryClient();
  
  useEffect(() => {
    // Get authenticated user ID from localStorage
    let userId = localStorage.getItem("currentUserId");
    
    // Fallback to demo user (ID 9) if no valid user or invalid user ID
    if (!userId || userId === "6" || userId === "1") {
      userId = "9";
      localStorage.setItem("currentUserId", "9");
      localStorage.setItem("userAuthenticated", "true");
      
      // Clear any stale cache entries for invalid user IDs
      queryClient.clear(); // Clear all cached queries
    }
    
    setCurrentUserId(userId);
  }, []);

  // Handle authentication state changes
  useEffect(() => {
    const handleAuthChange = () => {
      const userId = localStorage.getItem("currentUserId");
      setCurrentUserId(userId);
    };

    window.addEventListener('authStateChange', handleAuthChange);
    return () => window.removeEventListener('authStateChange', handleAuthChange);
  }, []);
  
  const { data: dashboardData, isLoading } = useQuery({
    queryKey: [`/api/dashboard/${currentUserId}`],
    enabled: !!currentUserId,
  });

  // Fetch jobs data for real-time calculations and deductions overview
  const { data: jobs = [] } = useQuery<Job[]>({
    queryKey: [`/api/jobs/${currentUserId}`],
    enabled: !!currentUserId,
    staleTime: 0, // Always fetch fresh data
  });
  
  const [, setLocation] = useLocation();

  // Mutation for creating new agencies
  const createAgencyMutation = useMutation({
    mutationFn: async (agencyData: InsertAgency) => {
      const response = await fetch('/api/agencies', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(agencyData)
      });
      
      if (!response.ok) {
        throw new Error('Failed to create agency');
      }
      
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [`/api/dashboard/${currentUserId}`] });
      queryClient.invalidateQueries({ queryKey: [`/api/agencies/${currentUserId}`] });
    },
  });

  const handleAddAgency = (agencyData: InsertAgency) => {
    createAgencyMutation.mutate(agencyData);
    setIsAddAgencyModalOpen(false);
  };

  const openAddAgencyModal = () => {
    setLocation("/add-agency-onboarding");
  };

  if (isLoading) {
    return (
      <div className="max-w-sm mx-auto bg-background min-h-screen flex items-center justify-center">
        <div className="text-foreground">Loading...</div>
      </div>
    );
  }

  if (!dashboardData) {
    return (
      <div className="max-w-sm mx-auto bg-background min-h-screen flex items-center justify-center">
        <div className="text-foreground">Error loading dashboard</div>
      </div>
    );
  }

  // Check if dashboardData has the expected structure
  if (!dashboardData || typeof dashboardData !== 'object' || !('user' in dashboardData)) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  const { user, account, cards = [], transactions = [] } = dashboardData;

  // Calculate real-time metrics from jobs data
  const calculateDashboardMetrics = () => {
    if (!jobs || jobs.length === 0) {
      return {
        currentIncome: 0,
        percentageChange: 0,
        upcomingIncome: 0,
        overdueIncome: 0
      };
    }

    const currentDate = new Date();
    const currentMonth = currentDate.getMonth();
    const currentYear = currentDate.getFullYear();
    const lastMonth = new Date(currentYear, currentMonth - 1);

    // Current month earnings (Received status only)
    const currentIncome = jobs
      .filter((job: Job) => {
        const jobDate = new Date(job.jobDate);
        return jobDate.getMonth() === currentMonth && 
               jobDate.getFullYear() === currentYear &&
               job.status === 'Received';
      })
      .reduce((sum: number, job: Job) => sum + parseFloat(job.amount), 0);

    // Last month earnings for percentage calculation
    const lastMonthIncome = jobs
      .filter((job: Job) => {
        const jobDate = new Date(job.jobDate);
        return jobDate.getMonth() === lastMonth.getMonth() && 
               jobDate.getFullYear() === lastMonth.getFullYear() &&
               job.status === 'Received';
      })
      .reduce((sum: number, job: Job) => sum + parseFloat(job.amount), 0);

    // Calculate percentage change
    const percentageChange = lastMonthIncome > 0 ? 
      ((currentIncome - lastMonthIncome) / lastMonthIncome * 100) : 0;

    // Upcoming income (Pending/Invoiced status)
    const upcomingIncome = jobs
      .filter((job: Job) => ['Pending', 'Invoiced', 'Partially Paid'].includes(job.status))
      .reduce((sum: number, job: Job) => sum + parseFloat(job.amount), 0);

    // Overdue income (due date passed, not received)
    const overdueIncome = jobs
      .filter((job: Job) => {
        const dueDate = new Date(job.dueDate);
        return dueDate < currentDate && 
               !['Received'].includes(job.status);
      })
      .reduce((sum: number, job: Job) => sum + parseFloat(job.amount), 0);

    return {
      currentIncome,
      percentageChange,
      upcomingIncome,
      overdueIncome
    };
  };

  const dashboardMetrics = calculateDashboardMetrics();

  // Check if this is a new user with minimal data
  const isNewUser = jobs.length === 0 && cards.length <= 1;
  
  // Calculate setup progress
  const calculateSetupProgress = () => {
    let progress = 0;
    let checklist = [];
    
    // Check for agencies
    if (cards.length > 0) {
      progress += 25;
      checklist.push({ completed: true, text: "Add agency" });
    } else {
      checklist.push({ completed: false, text: "Add agency" });
    }
    
    // Check for jobs
    if (jobs.length > 0) {
      progress += 25;
      checklist.push({ completed: true, text: "Add job" });
    } else {
      checklist.push({ completed: false, text: "Add job" });
    }
    
    // Check for income goal (placeholder for now)
    checklist.push({ completed: false, text: "Set income goal" });
    
    // Check for payments (if any job has "Received" status)
    const hasPayments = jobs.some((job: Job) => job.status === 'Received');
    if (hasPayments) {
      progress += 25;
      checklist.push({ completed: true, text: "Log your first payment" });
    } else {
      checklist.push({ completed: false, text: "Log your first payment" });
    }
    
    return { progress, checklist };
  };

  const setupStatus = calculateSetupProgress();

  if (isNewUser) {
    return (
      <div className="max-w-sm mx-auto bg-gray-50 min-h-screen">
        {/* Header with Back Button */}
        <div className="flex items-center justify-between px-6 py-4">
          <div className="flex items-center space-x-4">
            <button 
              onClick={() => setLocation("/get-started")}
              className="p-2 hover:bg-gray-100 rounded-full transition-colors"
            >
              <ArrowLeft className="h-5 w-5 text-gray-600" />
            </button>
            <div className="text-sm font-semibold">9:41 AM</div>
          </div>
          <div className="flex items-center space-x-1">
            <div className="flex space-x-1">
              <div className="w-1 h-3 bg-black rounded-full"></div>
              <div className="w-1 h-3 bg-black rounded-full"></div>
              <div className="w-1 h-3 bg-black rounded-full"></div>
              <div className="w-1 h-3 bg-gray-300 rounded-full"></div>
            </div>
            <div className="ml-2 flex space-x-1">
              <div className="w-4 h-2 border border-black rounded-sm">
                <div className="w-full h-full bg-black rounded-sm"></div>
              </div>
            </div>
          </div>
        </div>

        {/* Header */}
        <div className="px-6 mb-4">
          <div className="flex justify-between items-center">
            {/* Profile Button */}
            <button
              onClick={() => setLocation("/profile")}
              className="hover:scale-105 transition-transform"
            >
              <div className="w-10 h-10 rounded-full flex items-center justify-center bg-gray-100 text-gray-700 hover:bg-gray-200 transition-all duration-200">
                <User className="w-4 h-4" />
              </div>
            </button>
            
            {/* Notification Button */}
            <button 
              onClick={() => setLocation("/notifications")}
              className="p-2 hover:bg-gray-100 rounded-full transition-colors"
              title="Notifications"
            >
              <Bell className="w-5 h-5 text-gray-700" />
            </button>
          </div>
        </div>

        {/* Welcome Section */}
        <div className="px-6 mb-8">
          <h1 className="text-2xl font-bold text-gray-900 mb-2">
            Welcome, {user.name}! Let's get you started.
          </h1>
          <p className="text-gray-600">
            Track your jobs, earnings, and payments — all in one place.
          </p>
        </div>

        {/* Progress Ring */}
        <div className="px-6 mb-8">
          <div className="bg-white rounded-2xl p-6 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-900">Account Setup</h2>
              <div className="text-sm font-medium text-gray-500">{setupStatus.progress}% Complete</div>
            </div>
            
            

            {/* Checklist */}
            <div className="space-y-3">
              {setupStatus.checklist.map((item, index) => (
                <div key={index} className="flex items-center space-x-3">
                  
                  <span className={`${item.completed ? 'text-gray-900' : 'text-gray-500'}`}>
                    {item.text}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>

        

        {/* Agency Card */}
        {cards.length > 0 && (
          <div className="px-6 mb-8">
            <div className="relative">
              <BalanceCard account={account} cards={cards} onAddAgency={openAddAgencyModal} />
              <div className="absolute -top-2 -right-2 w-6 h-6 bg-emerald-500 rounded-full flex items-center justify-center animate-pulse">
                <span className="text-white text-xs">✨</span>
              </div>
              <p className="text-center text-gray-600 mt-3">
                Add an agency to get started.
              </p>
            </div>
          </div>
        )}

        {/* Monthly Goal Module */}
        <div className="px-6 mb-8">
          <div className="bg-white rounded-2xl p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">This Month</h2>
            <div className="text-center">
              <div className="text-3xl font-bold text-gray-400 mb-2">$0 of $0</div>
              <button className="text-emerald-600 font-medium hover:text-emerald-700">
                ➕ Set your monthly income goal
              </button>
            </div>
          </div>
        </div>



        {/* Deductions Overview */}
        <div className="px-6 mb-8">
          <DeductionsOverview jobs={jobs} />
        </div>

        <div className="h-24"></div>
        <BottomNavigation />

        <AddAgencyModal
          isOpen={isAddAgencyModalOpen}
          onClose={() => setIsAddAgencyModalOpen(false)}
          onAddAgency={handleAddAgency}
          userId={currentUserId ? parseInt(currentUserId) : 0}
        />
      </div>
    );
  }

  return (
    <div className="w-full max-w-md mx-auto bg-background min-h-screen relative overflow-x-hidden">
      {/* Header */}
      <div className="px-4 py-3">
        <div className="flex justify-between items-start">
          <div className="flex items-center space-x-3">
            {/* Profile Button */}
            <button
              onClick={() => setLocation("/profile")}
              className="hover:scale-105 transition-transform"
            >
              <div className="w-10 h-10 rounded-full flex items-center justify-center bg-card text-foreground hover:bg-muted transition-all duration-200">
                <User className="w-4 h-4" />
              </div>
            </button>
            <div>
              <h1 className="text-lg font-semibold text-foreground">{user?.greeting || "Hello"}</h1>
              <p className="text-muted-foreground text-xs">{user?.welcomeMessage || "Welcome back"}</p>
            </div>
          </div>
          <div className="flex items-center space-x-2">
            <button 
              onClick={() => setLocation("/notifications")}
              className="p-1.5 hover:bg-muted rounded-full transition-colors"
              title="Notifications"
            >
              <Bell className="w-4 h-4 text-foreground" />
            </button>
          </div>
        </div>
      </div>

      <div className="px-2 space-y-3">
        {account && (
          <div className="transform transition-all duration-300 hover:translate-y-[-1px]">
            <BalanceCard account={account} cards={cards} onAddAgency={openAddAgencyModal} />
          </div>
        )}
        
        <div className="transform transition-all duration-300 hover:translate-y-[-1px]">
          <MonthIncomeChart 
            currentIncome={dashboardMetrics.currentIncome}
            percentageChange={dashboardMetrics.percentageChange}
            upcomingIncome={dashboardMetrics.upcomingIncome}
            overdueIncome={dashboardMetrics.overdueIncome}
          />
        </div>
        
        <div className="transform transition-all duration-300 hover:translate-y-[-1px] pb-24">
          <DeductionsOverview jobs={jobs} />
        </div>
      </div>
      
      <BottomNavigation />

      {/* Add Agency Modal */}
      <AddAgencyModal 
        isOpen={isAddAgencyModalOpen}
        onClose={() => setIsAddAgencyModalOpen(false)}
        onAddAgency={handleAddAgency}
        userId={parseInt(currentUserId || "9")}
      />
    </div>
  );
}
