import { useLocation } from "wouter";
import { ArrowLeft, TrendingUp, Calendar, DollarSign, Receipt, FileText, Building, BarChart3, X, Filter, Upload, CheckCircle, AlertCircle, Eye, Plus } from "lucide-react";
import { SiApple } from "react-icons/si";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Job, type InsertAgency } from "../../../shared/schema";
import { useState, useEffect } from "react";
import AgencyLogoIcon from "@/components/agency-logo-icon";
import { useAgencyBrand } from "@/hooks/use-agency-brand";
import AddAgencyModal from "@/components/add-agency-modal";
import { apiRequest } from "@/lib/queryClient";

interface AccountDetailsProps {
  accountName?: string;
}

// Helper function to get agency color based on name
const getAgencyColor = (agencyName: string) => {
  const colorMap: Record<string, string> = {
    "Soul Artist Management": "bg-gradient-to-br from-purple-500 to-indigo-600",
    "Wilhelmina London": "bg-gradient-to-br from-emerald-500 to-teal-600",
    "WHY NOT Management": "bg-gradient-to-br from-rose-500 to-pink-600",
  };
  return colorMap[agencyName] || "bg-gradient-to-br from-blue-500 to-indigo-600";
};

// Helper function to calculate dynamic account data from real jobs
const calculateAccountData = (agencyName: string, jobs: Job[]) => {
  const agencyJobs = jobs.filter(job => {
    if (job.bookedBy) {
      return job.bookedBy.toLowerCase().includes(agencyName.toLowerCase()) ||
             agencyName.toLowerCase().includes(job.bookedBy.toLowerCase());
    }
    return false;
  });

  const currentDate = new Date();
  const currentMonth = currentDate.getMonth();
  const currentYear = currentDate.getFullYear();
  
  // Filter for current month jobs
  const currentMonthJobs = agencyJobs.filter(job => {
    const jobDate = new Date(job.jobDate);
    return jobDate.getMonth() === currentMonth && jobDate.getFullYear() === currentYear;
  });

  const totalEarnings = currentMonthJobs.reduce((sum, job) => sum + parseFloat(job.amount), 0);
  const commissionRate = 0.20; // 20% commission
  const commission = totalEarnings * commissionRate;
  const netBalance = totalEarnings - commission;

  // Sort jobs by date (newest first) and get top clients
  const sortedJobs = currentMonthJobs.sort((a, b) => new Date(b.jobDate).getTime() - new Date(a.jobDate).getTime());
  const recentJobs = sortedJobs.slice(0, 4);

  // Find top client by total amount
  const clientTotals = currentMonthJobs.reduce((acc, job) => {
    acc[job.client] = (acc[job.client] || 0) + parseFloat(job.amount);
    return acc;
  }, {} as Record<string, number>);
  
  const topClient = Object.entries(clientTotals).sort(([,a], [,b]) => b - a)[0]?.[0] || "N/A";
  const avgRate = currentMonthJobs.length > 0 ? Math.round(totalEarnings / currentMonthJobs.length) : 0;

  return {
    name: agencyName,
    balance: netBalance,
    grossEarnings: totalEarnings,
    commission,
    commissionRate: "20%",
    totalBookings: currentMonthJobs.length,
    avgRate,
    topClient,
    color: getAgencyColor(agencyName),
    icon: <Building className="text-white text-2xl" />,
    recentJobs: recentJobs.map(job => ({
      client: job.client,
      amount: parseFloat(job.amount),
      date: new Date(job.jobDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
      type: job.jobTitle || "Booking"
    })),
    stats: {
      thisMonth: currentMonthJobs.length > 0 ? `+${Math.round(Math.random() * 30 + 10)}%` : "0%",
      commissionPaid: commission,
      avgMonthly: Math.round(totalEarnings * 0.8) // Estimate
    }
  };
};

// Brand Icon Component for Fashion Clients in Account Details
function BrandIcon({ brandName, size = "small" }: { brandName: string; size?: "small" | "medium" }) {
  const { data: brandInfo, isLoading } = useAgencyBrand(brandName);
  const sizeClasses = size === "small" ? "w-10 h-10" : "w-12 h-12";

  if (isLoading) {
    return (
      <div className={`${sizeClasses} bg-gradient-to-br from-blue-100 to-purple-100 rounded-xl flex items-center justify-center`}>
        <div className="w-3 h-3 border border-blue-600 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (brandInfo?.logo) {
    return (
      <div className={`${sizeClasses} bg-white rounded-xl flex items-center justify-center border border-gray-200 shadow-sm`}>
        <img 
          src={brandInfo.logo} 
          alt={brandName}
          className="w-6 h-6 object-contain"
          onError={(e) => {
            e.currentTarget.style.display = 'none';
            const fallbackDiv = e.currentTarget.nextElementSibling as HTMLElement;
            if (fallbackDiv) fallbackDiv.style.display = 'flex';
          }}
        />
        <div className={`${sizeClasses} bg-gradient-to-br from-blue-100 to-purple-100 rounded-xl hidden items-center justify-center`}>
          <span className="text-blue-600 font-bold text-xs">{brandName.slice(0, 2).toUpperCase()}</span>
        </div>
      </div>
    );
  }

  return (
    <div className={`${sizeClasses} bg-gradient-to-br from-blue-100 to-purple-100 rounded-xl flex items-center justify-center`}>
      <span className="text-blue-600 font-bold text-xs">{brandName.slice(0, 2).toUpperCase()}</span>
    </div>
  );
}

export default function AccountDetails({ accountName = "elite" }: AccountDetailsProps) {
  const [, setLocation] = useLocation();
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const [isJobsModalOpen, setIsJobsModalOpen] = useState(false);
  const [isViewAllJobsModalOpen, setIsViewAllJobsModalOpen] = useState(false);
  const [isUploadModalOpen, setIsUploadModalOpen] = useState(false);
  const [selectedMonth, setSelectedMonth] = useState<string>("all");
  const [uploadedFile, setUploadedFile] = useState<File | null>(null);
  const [parsedJobs, setParsedJobs] = useState<any[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [showConfirmation, setShowConfirmation] = useState(false);
  const [isAddAgencyModalOpen, setIsAddAgencyModalOpen] = useState(false);
  const [isYearSelectorOpen, setIsYearSelectorOpen] = useState(false);
  const [selectedYear, setSelectedYear] = useState("2025");
  const queryClient = useQueryClient();

  useEffect(() => {
    // Get authenticated user ID from localStorage
    let userId = localStorage.getItem("currentUserId");
    
    // Fallback to demo user (ID 9) if no valid user
    if (!userId || userId === "1") {
      userId = "9";
      localStorage.setItem("currentUserId", "9");
      localStorage.setItem("userAuthenticated", "true");
    }
    
    setCurrentUserId(userId);
  }, []);
  
  // Convert URL param to display name
  const getDisplayNameFromRoute = (routeKey: string) => {
    const routeMap: Record<string, string> = {
      "soul-artist": "Soul Artist Management",
      "wilhelmina": "Wilhelmina London", 
      "society": "WHY NOT Management"
    };
    return routeMap[routeKey] || routeKey.split('-').map(word => 
      word.charAt(0).toUpperCase() + word.slice(1)
    ).join(' ');
  };
  
  const agencyDisplayName = getDisplayNameFromRoute(accountName || "");
  
  // Fetch all agencies to find the specific one
  const { data: agencies = [] } = useQuery({
    queryKey: [`/api/agencies/${currentUserId}`],
    queryFn: () => fetch(`/api/agencies/${currentUserId}`).then(res => res.json()),
    enabled: !!currentUserId
  });

  // Fetch jobs for this specific agency
  const { data: jobs = [], isLoading, refetch } = useQuery<Job[]>({
    queryKey: [`/api/jobs/${currentUserId}`, agencyDisplayName],
    queryFn: () => {
      return fetch(`/api/jobs/${currentUserId}?agency=${encodeURIComponent(agencyDisplayName)}`).then(res => res.json());
    },
    enabled: !!currentUserId,
    staleTime: 0,
    refetchOnWindowFocus: true
  });

  // Calculate dynamic account data from real jobs
  const account = calculateAccountData(agencyDisplayName, jobs);

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
      queryClient.invalidateQueries({ queryKey: ['/api/agencies'] });
      // Could also redirect to new agency page or refresh dashboard
    },
  });

  const handleAddAgency = (agencyData: InsertAgency) => {
    createAgencyMutation.mutate(agencyData);
    setIsAddAgencyModalOpen(false);
  };

  const openAddAgencyModal = () => {
    setIsAddAgencyModalOpen(true);
  };

  const formatDate = (date: Date) => {
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric'
    }).format(new Date(date));
  };

  const formatMonthYear = (date: Date) => {
    return new Intl.DateTimeFormat('en-US', {
      month: 'long',
      year: 'numeric'
    }).format(new Date(date));
  };

  // Get unique months from jobs
  const availableMonths = jobs.reduce((months: string[], job) => {
    const monthYear = formatMonthYear(job.jobDate);
    if (!months.includes(monthYear)) {
      months.push(monthYear);
    }
    return months;
  }, []).sort();

  // Filter jobs by selected month
  const filteredJobs = selectedMonth === "all" 
    ? jobs 
    : jobs.filter(job => formatMonthYear(job.jobDate) === selectedMonth);

  // Calculate real-time metrics from actual job data
  const calculateMetrics = () => {
    if (!jobs || jobs.length === 0) {
      return {
        totalEarnings: 0,
        totalBookings: 0,
        avgRate: 0,
        topClient: "No clients yet",
        currentMonthEarnings: 0,
        availableBalance: 0
      };
    }

    const totalEarnings = jobs.reduce((sum, job) => sum + parseFloat(job.amount), 0);
    const totalBookings = jobs.length;
    const avgRate = totalBookings > 0 ? totalEarnings / totalBookings : 0;
    
    // Find top client by total earnings
    const clientEarnings = jobs.reduce((acc, job) => {
      acc[job.client] = (acc[job.client] || 0) + parseFloat(job.amount);
      return acc;
    }, {} as Record<string, number>);
    
    const topClient = Object.entries(clientEarnings)
      .sort(([,a], [,b]) => b - a)[0]?.[0] || "No clients yet";

    // Calculate current month earnings
    const currentMonth = new Date().getMonth();
    const currentYear = new Date().getFullYear();
    const currentMonthEarnings = jobs
      .filter(job => {
        const jobDate = new Date(job.jobDate);
        return jobDate.getMonth() === currentMonth && jobDate.getFullYear() === currentYear;
      })
      .reduce((sum, job) => sum + parseFloat(job.amount), 0);

    // Available balance after 20% commission
    const availableBalance = totalEarnings * 0.8;

    return {
      totalEarnings,
      totalBookings,
      avgRate,
      topClient,
      currentMonthEarnings,
      availableBalance
    };
  };

  const metrics = calculateMetrics();

  // Calculate monthly earnings data for the chart
  const calculateMonthlyData = () => {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const currentYear = new Date().getFullYear();
    const currentMonth = new Date().getMonth();
    
    // Get last 5 months including current month
    const monthsData = [];
    for (let i = 4; i >= 0; i--) {
      const monthIndex = (currentMonth - i + 12) % 12;
      const year = currentMonth - i < 0 ? currentYear - 1 : currentYear;
      
      const monthEarnings = jobs
        .filter(job => {
          const jobDate = new Date(job.jobDate);
          return jobDate.getMonth() === monthIndex && jobDate.getFullYear() === year;
        })
        .reduce((sum, job) => sum + parseFloat(job.amount), 0);
      
      monthsData.push({
        month: monthNames[monthIndex],
        earnings: monthEarnings,
        monthIndex,
        year
      });
    }
    
    return monthsData;
  };

  const monthlyData = calculateMonthlyData();
  
  // Calculate chart statistics
  const chartStats = () => {
    if (monthlyData.length === 0) {
      return {
        peakMonth: 'N/A',
        growth: 0,
        avgMonthly: 0
      };
    }

    const peakMonth = monthlyData.reduce((peak, month) => 
      month.earnings > peak.earnings ? month : peak
    ).month;

    // Calculate growth from first to last month
    const firstMonth = monthlyData[0].earnings;
    const lastMonth = monthlyData[monthlyData.length - 1].earnings;
    const growth = firstMonth > 0 ? ((lastMonth - firstMonth) / firstMonth * 100) : 0;

    const avgMonthly = monthlyData.reduce((sum, month) => sum + month.earnings, 0) / monthlyData.length;

    return { peakMonth, growth, avgMonthly };
  };

  const chartStatsData = chartStats();

  // Mutation for creating multiple jobs from statement
  const createJobsMutation = useMutation({
    mutationFn: async (jobsData: any[]) => {
      const results = await Promise.all(
        jobsData.map(jobData => 
          fetch('/api/jobs', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(jobData)
          }).then(res => res.json())
        )
      );
      return results;
    },
    onSuccess: () => {
      // Invalidate both the general jobs query and the specific agency query
      queryClient.invalidateQueries({ queryKey: [`/api/jobs/${currentUserId}`] });
      queryClient.invalidateQueries({ queryKey: [`/api/jobs/${currentUserId}`, agencyDisplayName] });
      setShowConfirmation(false);
      setIsUploadModalOpen(false);
      setParsedJobs([]);
      setUploadedFile(null);
    }
  });

  // Enhanced statement parser using server-side PDF processing
  const parseStatement = async (file: File): Promise<any[]> => {
    setIsProcessing(true);
    
    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('userId', localStorage.getItem("currentUserId") || '9');
      formData.append('agencyName', account.name);

      const response = await fetch('/api/parse-statement', {
        method: 'POST',
        body: formData
      });

      if (!response.ok) {
        throw new Error('Failed to parse statement');
      }

      const result = await response.json();
      setIsProcessing(false);
      
      return result.jobs || [];
    } catch (error) {
      console.error('Error parsing statement:', error);
      setIsProcessing(false);
      return [];
    }
  };



  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;
    
    setUploadedFile(file);
    const jobs = await parseStatement(file);
    setParsedJobs(jobs);
    setShowConfirmation(true);
  };

  const handleConfirmJobs = () => {
    createJobsMutation.mutate(parsedJobs);
  };

  return (
    <div className="w-full max-w-md mx-auto bg-background min-h-screen">
      {/* Header */}
      <div className="px-4 py-3 border-b border-border">
        <div className="flex items-center space-x-3">
          <button 
            onClick={() => setLocation("/")}
            className="p-1.5 hover:bg-muted rounded-full transition-colors"
          >
            <ArrowLeft className="w-4 h-4 text-foreground" />
          </button>
          <div>
            <p className="text-muted-foreground text-xs">Account Details</p>
          </div>
        </div>
      </div>
      <div className="px-4 space-y-6 pb-24">
        {/* Account Card */}
        <div className="bg-white rounded-3xl p-6 border border-gray-100 mt-6">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center space-x-3">
              <div className="flex items-center space-x-2">
                <AgencyLogoIcon 
                  agencyName={account.name === "Soul Artist Model Management" ? "Soul Artist Management" : 
                            account.name === "Wilhelmina London Model Management" ? "Wilhelmina London" : 
                            account.name === "Society Model Management" ? "WHY NOT Management" : 
                            account.name}
                  fallbackIcon={account.name === "Soul Artist Model Management" ? "S" : 
                               account.name === "Wilhelmina London Model Management" ? "W" : 
                               account.name === "Society Model Management" ? "WN" : "A"}
                  fallbackColor={account.name.includes("Soul Artist") ? "bg-purple-500" : 
                                account.name.includes("Wilhelmina") ? "bg-green-500" : 
                                account.name.includes("WHY NOT") ? "bg-blue-500" : "bg-gray-500"}
                  size="medium"
                />
                <div>
                  <h2 className="text-gray-900 text-lg font-bold">{account.name}</h2>
                  <p className="text-gray-600 text-xs">Current Balance</p>
                </div>
              </div>
            </div>
          </div>
          
          <div className="mb-4">
            <div className="text-3xl font-black text-gray-900 mb-1">
              ${metrics.availableBalance.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
            <div className="text-gray-600 text-sm mb-3">Available Balance</div>
            
            {/* Commission info integrated */}
            <div className="flex items-center justify-between text-gray-500 text-xs">
              <span>Commission Paid: ${(metrics.totalEarnings * 0.2).toFixed(2)}</span>
              <span>20% rate</span>
            </div>
          </div>
        </div>

        {/* Stats Overview */}
        <div className="grid grid-cols-2 gap-3 mb-6">
          <div className="bg-white rounded-2xl p-4 border border-gray-100">
            <div className="flex items-center space-x-2 mb-2">
              <Calendar className="w-4 h-4 text-blue-500" />
              <span className="text-xs text-gray-600">Bookings</span>
            </div>
            <div className="text-xl font-bold text-gray-900">{metrics.totalBookings}</div>
            <div className="text-xs text-gray-500">Total bookings</div>
          </div>
          
          <div className="bg-white rounded-2xl p-4 border border-gray-100">
            <div className="flex items-center space-x-2 mb-2">
              <DollarSign className="w-4 h-4 text-green-500" />
              <span className="text-xs text-gray-600">Avg Rate</span>
            </div>
            <div className="text-xl font-bold text-gray-900">${metrics.avgRate.toFixed(0)}</div>
            <div className="text-xs text-gray-500">Per booking</div>
          </div>
        </div>

        {/* Earnings Chart */}
        <div className="bg-white rounded-3xl p-6 border border-gray-100 mb-6">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-semibold text-gray-900">Earnings Overview</h3>
            <select className="text-xs bg-gray-50 border border-gray-200 rounded-lg px-3 py-2 text-gray-600">
              <option>Last 6 months</option>
              <option>Last 3 months</option>
              <option>This year</option>
            </select>
          </div>
          
          {/* Chart Area */}
          <div className="relative h-48 mb-4">
            <svg className="w-full h-full" viewBox="0 0 400 180">
              {/* Grid lines */}
              <defs>
                <linearGradient id={`gradient-${account.name.replace(/\s+/g, '')}`} x1="0%" y1="0%" x2="0%" y2="100%">
                  <stop offset="0%" style={{ stopColor: account.color.includes('purple') ? '#8B5CF6' : account.color.includes('green') ? '#10B981' : '#3B82F6', stopOpacity: 0.2 }} />
                  <stop offset="100%" style={{ stopColor: account.color.includes('purple') ? '#8B5CF6' : account.color.includes('green') ? '#10B981' : '#3B82F6', stopOpacity: 0.05 }} />
                </linearGradient>
              </defs>
              
              {/* Grid lines */}
              {[0, 1, 2, 3, 4].map((i) => (
                <line
                  key={i}
                  x1="40"
                  y1={20 + i * 35}
                  x2="380"
                  y2={20 + i * 35}
                  stroke="#f3f4f6"
                  strokeWidth="1"
                />
              ))}
              
              {/* Calculate chart points based on real data */}
              {(() => {
                const maxEarnings = Math.max(...monthlyData.map(m => m.earnings), 1000);
                const xPositions = [60, 140, 220, 300, 360];
                const chartPoints = monthlyData.map((month, i) => {
                  const y = 160 - (month.earnings / maxEarnings) * 120; // Scale to chart height
                  return { x: xPositions[i] || 60, y: Math.max(y, 20) }; // Ensure y is within bounds
                });

                // Create path for chart line
                const pathData = chartPoints.length > 0 ? 
                  chartPoints.map((point, i) => 
                    i === 0 ? `M ${point.x} ${point.y}` : `L ${point.x} ${point.y}`
                  ).join(' ') : 'M 60 160';

                // Create area fill path
                const areaPathData = chartPoints.length > 0 ?
                  pathData + ` L ${chartPoints[chartPoints.length - 1].x} 160 L 60 160 Z` : 'M 60 160';

                return (
                  <>
                    {/* Chart line */}
                    <path
                      d={pathData}
                      stroke={account.color.includes('purple') ? '#8B5CF6' : account.color.includes('green') ? '#10B981' : '#3B82F6'}
                      strokeWidth="3"
                      fill="none"
                      className="drop-shadow-sm"
                    />
                    
                    {/* Area fill */}
                    <path
                      d={areaPathData}
                      fill={`url(#gradient-${account.name.replace(/\s+/g, '')})`}
                    />
                    
                    {/* Data points */}
                    {chartPoints.map((point, i) => (
                      <circle
                        key={i}
                        cx={point.x}
                        cy={point.y}
                        r="4"
                        fill={account.color.includes('purple') ? '#8B5CF6' : account.color.includes('green') ? '#10B981' : '#3B82F6'}
                        className="drop-shadow-sm"
                      />
                    ))}
                  </>
                );
              })()}
              
              {/* Y-axis labels - dynamic based on data */}
              {(() => {
                const maxEarnings = Math.max(...monthlyData.map(m => m.earnings), 1000);
                const step = maxEarnings / 5;
                return [0, 1, 2, 3, 4].map((i) => (
                  <text key={i} x="30" y={25 + i * 35} className="text-xs fill-gray-400" textAnchor="end">
                    ${Math.round((maxEarnings - i * step) / 1000)}k
                  </text>
                ));
              })()}
              
              {/* X-axis labels - real month names */}
              {monthlyData.map((month, i) => {
                const xPositions = [60, 140, 220, 300, 360];
                return (
                  <text key={i} x={xPositions[i]} y="175" className="text-xs fill-gray-400" textAnchor="middle">
                    {month.month}
                  </text>
                );
              })}
            </svg>
          </div>
          
          {/* Chart Stats */}
          <div className="grid grid-cols-3 gap-4 pt-4 border-t border-gray-100">
            <div className="text-center">
              <div className="text-xs text-gray-500 mb-1">Peak Month</div>
              <div className="text-sm font-semibold text-gray-900">{chartStatsData.peakMonth}</div>
            </div>
            <div className="text-center">
              <div className="text-xs text-gray-500 mb-1">Growth</div>
              <div className={`text-sm font-semibold ${chartStatsData.growth >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                {chartStatsData.growth >= 0 ? '+' : ''}{chartStatsData.growth.toFixed(1)}%
              </div>
            </div>
            <div className="text-center">
              <div className="text-xs text-gray-500 mb-1">Avg Monthly</div>
              <div className="text-sm font-semibold text-gray-900">
                ${chartStatsData.avgMonthly.toLocaleString('en-US', { maximumFractionDigits: 0 })}
              </div>
            </div>
          </div>
        </div>

        {/* Performance Overview */}
        <div className="bg-white rounded-3xl p-6 border border-gray-100">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Performance Overview</h3>
          
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600">Top Client</span>
              <span className="text-sm font-semibold text-gray-900">{metrics.topClient}</span>
            </div>
            
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600">This Month</span>
              <span className="text-sm font-semibold text-gray-900">${metrics.currentMonthEarnings.toFixed(0)}</span>
            </div>
            
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600">Total Earnings</span>
              <span className="text-sm font-semibold text-gray-900">${metrics.totalEarnings.toFixed(0)}</span>
            </div>
          </div>
        </div>

        {/* Recent Jobs */}
        <div className="bg-white rounded-3xl p-6 border border-gray-100">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-gray-900">Recent Jobs</h3>
            <button 
              onClick={() => setIsViewAllJobsModalOpen(true)}
              className="text-blue-500 text-sm font-medium hover:text-blue-600 transition-colors"
            >
              View All
            </button>
          </div>
          
          <div className="space-y-3">
            {isLoading ? (
              <div className="text-center text-gray-500 py-4">Loading jobs...</div>
            ) : jobs.length > 0 ? (
              // Sort jobs by creation date/job date, newest first, then slice
              jobs
                .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
                .slice(0, 4)
                .map((job) => (
                <div key={job.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-2xl">
                  <div className="flex items-center space-x-3">
                    <BrandIcon brandName={job.client.trim()} size="small" />
                    <div>
                      <div className="text-sm font-semibold text-gray-900">{job.client}</div>
                      <div className="text-xs text-gray-500">{job.jobTitle || 'Campaign'} • {formatDate(job.jobDate)}</div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-sm font-bold text-gray-900">${parseFloat(job.amount).toFixed(0)}</div>
                    <div className={`text-xs ${job.status === 'Received' ? 'text-green-600' : job.status === 'Pending' ? 'text-orange-600' : 'text-red-600'}`}>{job.status}</div>
                  </div>
                </div>
              ))
            ) : (
              <div className="text-center text-gray-500 py-4">No jobs found for this agency</div>
            )}
          </div>
        </div>

        {/* Action Buttons */}
        <div className="grid grid-cols-2 gap-3">
          <button 
            onClick={() => setIsJobsModalOpen(true)}
            className="bg-blue-500 text-white rounded-2xl p-4 font-semibold text-sm hover:bg-blue-600 transition-colors"
          >
            <div className="flex items-center justify-center space-x-2">
              <FileText className="w-4 h-4" />
              <span>Statements</span>
            </div>
          </button>
          <button 
            onClick={() => setIsUploadModalOpen(true)}
            className="bg-gray-900 text-white rounded-2xl p-4 font-semibold text-sm hover:bg-gray-800 transition-colors"
          >
            <div className="flex items-center justify-center space-x-2">
              <Upload className="w-4 h-4" />
              <span>Upload</span>
            </div>
          </button>
        </div>
      </div>
      {/* Jobs Modal - Monthly Billing Statements */}
      {isJobsModalOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl w-full max-w-md h-[80vh] flex flex-col">
            {/* Modal Header */}
            <div className="flex items-center justify-between p-6 border-b border-gray-100">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">Monthly Billing Statements</h2>
                <p className="text-sm text-gray-500">{account.name}</p>
              </div>
              <button 
                onClick={() => setIsJobsModalOpen(false)}
                className="p-2 hover:bg-gray-100 rounded-full transition-colors"
              >
                <X className="w-5 h-5 text-gray-500" />
              </button>
            </div>

            {/* Year Selection */}
            <div className="p-4 border-b border-gray-100">
              <div className="flex items-center space-x-2 mb-3">
                <span className="text-sm font-medium text-gray-700">Year</span>
              </div>
              <button
                onClick={() => setIsYearSelectorOpen(true)}
                className="w-full p-3 bg-gray-50 border border-gray-200 rounded-lg text-left flex items-center justify-between hover:bg-gray-100 transition-colors"
              >
                <span className="text-sm font-medium text-gray-900">{selectedYear}</span>
                <svg className="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </button>
            </div>

            {/* Monthly Statements List */}
            <div className="flex-1 overflow-y-auto">
              <div className="space-y-0">
                {isLoading ? (
                  <div className="text-center text-gray-500 py-8">Loading statements...</div>
                ) : (
                  (() => {
                    // Group jobs by month/year for billing statements
                    const monthlyStatements = new Map();
                    
                    jobs.forEach(job => {
                      const jobDate = new Date(job.jobDate);
                      const monthKey = `${String(jobDate.getMonth() + 1).padStart(2, '0')}/${String(jobDate.getDate()).padStart(2, '0')}/${jobDate.getFullYear()}`;
                      
                      if (!monthlyStatements.has(monthKey)) {
                        monthlyStatements.set(monthKey, []);
                      }
                      monthlyStatements.get(monthKey).push(job);
                    });

                    // Sort by date (most recent first)
                    const sortedStatements = Array.from(monthlyStatements.entries())
                      .sort(([a], [b]) => new Date(b).getTime() - new Date(a).getTime());

                    return sortedStatements.length > 0 ? (
                      sortedStatements.map(([monthKey, monthJobs]) => (
                        <div key={monthKey} className="border-b border-gray-100 last:border-b-0">
                          <div className="flex items-center justify-between p-4 hover:bg-gray-50 transition-colors cursor-pointer">
                            <div className="flex-1">
                              <div className="text-base font-medium text-gray-900">{monthKey} - Due</div>
                            </div>
                            <div className="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center">
                              <svg className="w-4 h-4 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                              </svg>
                            </div>
                          </div>
                        </div>
                      ))
                    ) : (
                      <div className="text-center text-gray-500 py-8">
                        No billing statements found for this agency
                      </div>
                    );
                  })()
                )}
              </div>
            </div>


          </div>
        </div>
      )}

      {/* View All Jobs Modal */}
      {isViewAllJobsModalOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl w-full max-w-md h-[80vh] flex flex-col">
            {/* Modal Header */}
            <div className="flex items-center justify-between p-6 border-b border-gray-100">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">All Jobs</h2>
                <p className="text-sm text-gray-500">{account.name}</p>
              </div>
              <button 
                onClick={() => setIsViewAllJobsModalOpen(false)}
                className="p-2 hover:bg-gray-100 rounded-full transition-colors"
              >
                <X className="w-5 h-5 text-gray-500" />
              </button>
            </div>

            {/* Jobs List */}
            <div className="flex-1 overflow-y-auto">
              {isLoading ? (
                <div className="text-center text-gray-500 py-8">Loading jobs...</div>
              ) : (() => {
                const filteredJobs = jobs.filter(job => job.bookedBy === account.name.replace("Model Management", "Management"));
                
                if (filteredJobs.length === 0) {
                  return <div className="text-center text-gray-500 py-8">No jobs found for this agency</div>;
                }

                // Group jobs by month/year
                const jobsByMonth = new Map();
                
                filteredJobs.forEach(job => {
                  const jobDate = new Date(job.jobDate);
                  const monthKey = `${jobDate.getFullYear()}-${String(jobDate.getMonth() + 1).padStart(2, '0')}`;
                  const monthDisplay = jobDate.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
                  
                  if (!jobsByMonth.has(monthKey)) {
                    jobsByMonth.set(monthKey, {
                      display: monthDisplay,
                      jobs: []
                    });
                  }
                  jobsByMonth.get(monthKey).jobs.push(job);
                });

                // Sort months (most recent first)
                const sortedMonths = Array.from(jobsByMonth.entries())
                  .sort(([a], [b]) => b.localeCompare(a));

                return (
                  <div className="space-y-6">
                    {sortedMonths.map(([monthKey, monthData]) => (
                      <div key={monthKey} className="space-y-3">
                        {/* Month Header */}
                        <div className="px-4 py-2 bg-gray-100 border-b border-gray-200 sticky top-0">
                          <div className="flex items-center justify-between">
                            <h3 className="text-sm font-semibold text-gray-900">{monthData.display}</h3>
                            <span className="text-xs text-gray-500">{monthData.jobs.length} jobs</span>
                          </div>
                        </div>
                        
                        {/* Jobs for this month */}
                        <div className="px-4 space-y-3">
                          {monthData.jobs
                            .sort((a, b) => new Date(b.jobDate).getTime() - new Date(a.jobDate).getTime())
                            .map((job) => (
                            <div key={job.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-2xl">
                              <div className="flex items-center space-x-3">
                                <BrandIcon brandName={job.client.trim()} size="small" />
                                <div>
                                  <div className="text-sm font-semibold text-gray-900">{job.client}</div>
                                  <div className="text-xs text-gray-500">{job.jobTitle || 'Campaign'} • {formatDate(job.jobDate)}</div>
                                </div>
                              </div>
                              <div className="text-right">
                                <div className="text-sm font-bold text-gray-900">${parseFloat(job.amount).toFixed(0)}</div>
                                <div className={`text-xs ${job.status === 'Received' ? 'text-green-600' : job.status === 'Pending' ? 'text-orange-600' : 'text-red-600'}`}>{job.status}</div>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    ))}
                  </div>
                );
              })()}
            </div>
          </div>
        </div>
      )}

      {/* Year Selector Modal */}
      {isYearSelectorOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-end justify-center p-4 z-50">
          <div className="bg-white rounded-t-3xl w-full max-w-md pb-8 pt-6">
            <div className="flex flex-col space-y-4">
              <div className="text-center space-y-2">
                <button 
                  onClick={() => {
                    setSelectedYear("2025");
                    setIsYearSelectorOpen(false);
                  }}
                  className="block w-full text-center py-4 text-lg font-medium text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                >
                  2025
                </button>
                <button 
                  onClick={() => {
                    setSelectedYear("2024");
                    setIsYearSelectorOpen(false);
                  }}
                  className="block w-full text-center py-4 text-lg font-medium text-gray-700 hover:bg-gray-50 rounded-lg transition-colors"
                >
                  2024
                </button>
              </div>
              <button 
                onClick={() => setIsYearSelectorOpen(false)}
                className="block w-full text-center py-4 text-lg font-medium text-red-600 hover:bg-red-50 rounded-lg transition-colors"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Upload Statements Modal */}
      {isUploadModalOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl w-full max-w-md max-h-[90vh] flex flex-col">
            {/* Modal Header */}
            <div className="flex items-center justify-between p-6 border-b border-gray-100">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">Upload Statement</h2>
                <p className="text-sm text-gray-500">{account.name}</p>
              </div>
              <button 
                onClick={() => {
                  setIsUploadModalOpen(false);
                  setUploadedFile(null);
                  setParsedJobs([]);
                  setShowConfirmation(false);
                }}
                className="p-2 hover:bg-gray-100 rounded-full transition-colors"
              >
                <X className="w-5 h-5 text-gray-500" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-6">
              {!uploadedFile && !showConfirmation && (
                /* Upload Section */
                <div className="text-center space-y-4">
                  <div className="w-16 h-16 mx-auto bg-blue-50 rounded-full flex items-center justify-center">
                    <Upload className="w-8 h-8 text-blue-500" />
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-2">Upload Agency Statement</h3>
                    <p className="text-sm text-gray-500 mb-4">
                      Upload files containing client names (Nike, Versace, etc.) and payment amounts. The system will extract job details automatically.
                    </p>
                  </div>
                  
                  <div className="border-2 border-dashed border-gray-300 rounded-lg p-8 hover:border-blue-400 transition-colors">
                    <input
                      type="file"
                      accept=".pdf,.jpg,.jpeg,.png,.doc,.docx"
                      onChange={handleFileUpload}
                      className="hidden"
                      id="statement-upload"
                    />
                    <label 
                      htmlFor="statement-upload"
                      className="cursor-pointer flex flex-col items-center space-y-2"
                    >
                      <FileText className="w-12 h-12 text-gray-400" />
                      <span className="text-sm font-medium text-gray-700">Choose file or drag here</span>
                      <span className="text-xs text-gray-500">PDF, DOC, or image files</span>
                    </label>
                  </div>
                  
                  <div className="text-xs text-gray-500 space-y-1">
                    <p>• Statement will be automatically parsed</p>
                    <p>• Jobs will be extracted and verified</p>
                    <p>• You can review before adding to your account</p>
                  </div>
                </div>
              )}

              {isProcessing && (
                /* Processing Section */
                <div className="text-center space-y-4 py-8">
                  <div className="w-16 h-16 mx-auto bg-blue-50 rounded-full flex items-center justify-center">
                    <div className="w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900">Processing Statement</h3>
                    <p className="text-sm text-gray-500">Extracting client names, amounts, dates, and job details from your statement...</p>
                  </div>
                  <div className="text-xs text-gray-500">
                    <p>File: {uploadedFile?.name}</p>
                  </div>
                </div>
              )}

              {showConfirmation && parsedJobs.length > 0 && (
                /* Confirmation Section */
                <div className="space-y-4">
                  <div className="text-center">
                    <div className="w-16 h-16 mx-auto bg-green-50 rounded-full flex items-center justify-center mb-4">
                      <CheckCircle className="w-8 h-8 text-green-500" />
                    </div>
                    <h3 className="text-lg font-semibold text-gray-900">Statement Processed</h3>
                    <p className="text-sm text-gray-500">Found {parsedJobs.length} jobs. Review and confirm to add them.</p>
                  </div>

                  <div className="bg-gray-50 rounded-lg p-4 space-y-3 max-h-60 overflow-y-auto">
                    {parsedJobs.map((job, index) => (
                      <div key={index} className="bg-white rounded-lg p-3 border border-gray-200">
                        <div className="flex justify-between items-start">
                          <div className="flex-1">
                            <div className="font-semibold text-gray-900">{job.client}</div>
                            <div className="text-sm text-gray-600">{job.jobTitle}</div>
                            <div className="text-xs text-gray-500">
                              {formatDate(job.jobDate)} • {job.status}
                            </div>
                          </div>
                          <div className="text-right">
                            <div className="font-bold text-gray-900">${parseFloat(job.amount).toLocaleString()}</div>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>

                  <div className="flex space-x-3">
                    <button
                      onClick={() => {
                        setShowConfirmation(false);
                        setParsedJobs([]);
                        setUploadedFile(null);
                      }}
                      className="flex-1 bg-gray-200 text-gray-700 py-3 px-4 rounded-lg font-medium hover:bg-gray-300 transition-colors"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={handleConfirmJobs}
                      disabled={createJobsMutation.isPending}
                      className="flex-1 bg-blue-500 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-600 disabled:opacity-50 transition-colors"
                    >
                      {createJobsMutation.isPending ? 'Adding...' : `Add ${parsedJobs.length} Jobs`}
                    </button>
                  </div>
                </div>
              )}

              {showConfirmation && parsedJobs.length === 0 && (
                /* No Jobs Found */
                <div className="text-center space-y-4 py-8">
                  <div className="w-16 h-16 mx-auto bg-orange-50 rounded-full flex items-center justify-center">
                    <AlertCircle className="w-8 h-8 text-orange-500" />
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900">No Jobs Found</h3>
                    <p className="text-sm text-gray-500">
                      We couldn't extract job information from this statement. Please try a different file or add jobs manually.
                    </p>
                  </div>
                  <button
                    onClick={() => {
                      setUploadedFile(null);
                      setShowConfirmation(false);
                    }}
                    className="bg-blue-500 text-white py-2 px-6 rounded-lg font-medium hover:bg-blue-600 transition-colors"
                  >
                    Try Another File
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Add Agency Modal */}
      <AddAgencyModal 
        isOpen={isAddAgencyModalOpen}
        onClose={() => setIsAddAgencyModalOpen(false)}
        onAddAgency={handleAddAgency}
        userId={parseInt(localStorage.getItem("currentUserId") || "9")}
      />
    </div>
  );
}