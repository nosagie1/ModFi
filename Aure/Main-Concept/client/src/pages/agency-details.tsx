import { useLocation } from "wouter";
import { ArrowLeft, TrendingUp, TrendingDown } from "lucide-react";
import { useQuery } from "@tanstack/react-query";
import { useState, useEffect } from "react";
import type { Job } from "@shared/schema";

interface DataPoint {
  month: string;
  income: number;
  expense: number;
}

const mockData: DataPoint[] = [
  { month: "Jan", income: 8200, expense: 5800 },
  { month: "Feb", income: 9100, expense: 6200 },
  { month: "Mar", income: 8875, expense: 6952 },
  { month: "Apr", income: 11200, expense: 7100 },
  { month: "May", income: 10800, expense: 8200 },
  { month: "Jun", income: 12500, expense: 7900 },
];

interface AgencyDetailsProps {
  agencyName?: string;
}

export default function AgencyDetails({ agencyName = "elite" }: AgencyDetailsProps) {
  const [, setLocation] = useLocation();
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);

  useEffect(() => {
    // Get authenticated user ID from localStorage
    const userId = localStorage.getItem("currentUserId");
    setCurrentUserId(userId);
  }, []);

  // Fetch all jobs for real-time calculations
  const { data: allJobs = [] } = useQuery<Job[]>({
    queryKey: [`/api/jobs/${currentUserId}`],
    enabled: !!currentUserId,
    staleTime: 0, // Always fetch fresh data
  });

  // Agency-specific data
  const agencyData = {
    elite: {
      name: "Soul Artist Management",
      color: "bg-gradient-to-br from-purple-600 to-purple-800",
      bookedByName: "Soul Artist Management"
    },
    wilhelmina: {
      name: "Wilhelmina London", 
      color: "bg-gradient-to-br from-blue-600 to-blue-800",
      bookedByName: "Wilhelmina London"
    },
    society: {
      name: "WHY NOT Management",
      color: "bg-gradient-to-br from-green-600 to-green-800",
      bookedByName: "WHY NOT Management"
    }
  };

  const currentAgency = agencyData[agencyName as keyof typeof agencyData] || agencyData.elite;

  // Filter jobs for this specific agency
  const agencyJobs = allJobs.filter(job => job.bookedBy === currentAgency.bookedByName);

  // Calculate monthly data from real jobs
  const calculateMonthlyData = () => {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const currentYear = new Date().getFullYear();
    const currentMonth = new Date().getMonth();
    
    const monthsData = [];
    for (let i = 5; i >= 0; i--) {
      const monthIndex = (currentMonth - i + 12) % 12;
      const year = currentMonth - i < 0 ? currentYear - 1 : currentYear;
      
      const monthJobs = agencyJobs.filter(job => {
        const jobDate = new Date(job.jobDate);
        return jobDate.getMonth() === monthIndex && jobDate.getFullYear() === year;
      });
      
      const monthIncome = monthJobs.reduce((sum, job) => sum + parseFloat(job.amount), 0);
      const monthExpense = monthIncome * 0.2; // 20% commission expense
      
      monthsData.push({
        month: monthNames[monthIndex],
        income: monthIncome,
        expense: monthExpense
      });
    }
    
    return monthsData;
  };

  const realData = calculateMonthlyData();
  
  // Calculate metrics from real data
  const totalIncome = realData.reduce((sum, data) => sum + data.income, 0);
  const totalExpense = realData.reduce((sum, data) => sum + data.expense, 0);
  const avgIncome = realData.length > 0 ? totalIncome / realData.length : 0;
  const avgExpense = realData.length > 0 ? totalExpense / realData.length : 0;

  // Calculate growth percentages
  const calculateGrowth = () => {
    if (realData.length < 2) return { incomeChange: 0, expenseChange: 0 };
    
    const lastMonth = realData[realData.length - 1];
    const prevMonth = realData[realData.length - 2];
    
    const incomeChange = prevMonth.income > 0 ? 
      ((lastMonth.income - prevMonth.income) / prevMonth.income * 100) : 0;
    
    const expenseChange = prevMonth.expense > 0 ? 
      ((lastMonth.expense - prevMonth.expense) / prevMonth.expense * 100) : 0;
    
    return { incomeChange, expenseChange };
  };

  const { incomeChange, expenseChange } = calculateGrowth();
  
  // Calculate current balance for this agency
  const agencyBalance = agencyJobs.reduce((sum, job) => sum + parseFloat(job.amount), 0) * 0.8; // Net after commission

  const formatCurrency = (amount: number): string => {
    return amount.toLocaleString('en-US', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    });
  };

  return (
    <div className="max-w-sm mx-auto bg-background min-h-screen relative">
      
      {/* Header */}
      <div className="px-6 py-4">
        <div className="flex items-center space-x-4 mb-4">
          <button 
            onClick={() => setLocation("/")}
            className="p-2 hover:bg-muted rounded-full transition-colors"
          >
            <ArrowLeft className="w-5 h-5 text-foreground" />
          </button>
          <div>
            <h1 className="text-xl font-semibold text-foreground">{currentAgency.name}</h1>
            <p className="text-muted-foreground text-sm">Income-Expense Insight Analyzer</p>
          </div>
        </div>
        
        {/* Time selector */}
        <div className="flex justify-end">
          <select className="bg-card border border-border rounded-lg px-3 py-1 text-sm text-foreground">
            <option>6 Months</option>
            <option>3 Months</option>
            <option>1 Year</option>
          </select>
        </div>
      </div>

      {/* Chart Section */}
      <div className="px-6 mb-6">
        <div className="bg-gradient-to-b from-card to-card/95 border border-border rounded-[24px] p-6 shadow-[0_8px_32px_rgba(0,0,0,0.12)] backdrop-blur-sm">
          {/* Chart labels */}
          <div className="flex space-x-4 mb-8">
            <div className="bg-black text-white px-4 py-2 rounded-full text-sm font-medium">
              ${formatCurrency(agencyBalance)}
            </div>
            <div className="text-foreground font-medium">
              ${formatCurrency(totalExpense)}
            </div>
          </div>
          
          {/* SVG Chart */}
          <div className="h-40 mb-6 relative">
            <svg viewBox="0 0 300 120" className="w-full h-full">
              {/* Income line (orange) */}
              <path
                d="M 10 80 Q 60 60 100 70 T 180 50 Q 220 45 260 40 T 290 35"
                stroke="#f97316"
                strokeWidth="3"
                fill="none"
                strokeLinecap="round"
              />
              {/* Income data point */}
              <circle cx="100" cy="70" r="4" fill="#f97316" />
              
              {/* Expense line (green) */}
              <path
                d="M 10 100 Q 60 95 100 90 T 180 85 Q 220 80 260 75 T 290 70"
                stroke="#22c55e"
                strokeWidth="3"
                fill="none"
                strokeLinecap="round"
              />
              {/* Expense data point */}
              <circle cx="100" cy="90" r="4" fill="#22c55e" />
            </svg>
          </div>
          
          {/* Month labels */}
          <div className="flex justify-between text-sm">
            {realData.map((data, index) => (
              <div
                key={data.month}
                className={`px-3 py-1 rounded-full text-center ${
                  index === realData.length - 1 ? 'bg-foreground text-background' : 'text-muted-foreground'
                }`}
              >
                {data.month}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Metrics Cards */}
      <div className="px-6 grid grid-cols-2 gap-4 mb-20">
        {/* Average Income */}
        <div className="bg-gradient-to-b from-card to-card/95 border border-border rounded-[24px] p-6 shadow-[0_8px_32px_rgba(0,0,0,0.12)] backdrop-blur-sm">
          <div className="text-muted-foreground text-sm mb-2">Average Income</div>
          <div className="text-2xl font-bold text-foreground mb-2">
            ${avgIncome.toLocaleString('en-US', { minimumFractionDigits: 2 })}
          </div>
          <div className="flex items-center space-x-1">
            {incomeChange >= 0 ? (
              <>
                <TrendingUp className="w-3 h-3 text-green-600" />
                <span className="text-green-600 text-xs font-medium">+{incomeChange.toFixed(1)}%</span>
              </>
            ) : (
              <>
                <TrendingDown className="w-3 h-3 text-red-600" />
                <span className="text-red-600 text-xs font-medium">{incomeChange.toFixed(1)}%</span>
              </>
            )}
          </div>
        </div>
        
        {/* Average Expense */}
        <div className="bg-gradient-to-b from-card to-card/95 border border-border rounded-[24px] p-6 shadow-[0_8px_32px_rgba(0,0,0,0.12)] backdrop-blur-sm">
          <div className="text-muted-foreground text-sm mb-2">Average Expense</div>
          <div className="text-2xl font-bold text-foreground mb-2">
            ${avgExpense.toLocaleString('en-US', { minimumFractionDigits: 2 })}
          </div>
          <div className="flex items-center space-x-1">
            {expenseChange >= 0 ? (
              <>
                <TrendingUp className="w-3 h-3 text-red-600" />
                <span className="text-red-600 text-xs font-medium">+{expenseChange.toFixed(1)}%</span>
              </>
            ) : (
              <>
                <TrendingDown className="w-3 h-3 text-green-600" />
                <span className="text-green-600 text-xs font-medium">{expenseChange.toFixed(1)}%</span>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}