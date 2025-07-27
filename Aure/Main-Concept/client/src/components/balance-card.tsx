import { SiApple } from "react-icons/si";
import { CreditCard, Building, Plus, TrendingUp, TrendingDown, Receipt, FileText, ArrowDown, Folder, Edit3, Trash2, GripVertical, X } from "lucide-react";
import { useState, useEffect, useRef } from "react";
import { useLocation } from "wouter";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import type { Account, Card, Job, Agency } from "@shared/schema";
import AgencyLogoIcon from "./agency-logo-icon";
import { apiRequest } from "../lib/queryClient";
import { useToast } from "../hooks/use-toast";

interface BalanceCardProps {
  account: Account;
  cards: Card[];
  onAddAgency?: () => void;
}

const formatCurrency = (amount: string): string => {
  const numAmount = parseFloat(amount);
  return numAmount.toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
};

const getCardIcon = (cardType: string) => {
  switch (cardType) {
    case "Apple Card":
      return <SiApple className="text-black text-2xl" />;
    case "Business Card":
      return <Building className="text-black text-2xl" />;
    case "Debit Card":
      return <CreditCard className="text-black text-2xl" />;
    default:
      return <CreditCard className="text-black text-2xl" />;
  }
};

const getCardColor = (cardType: string) => {
  switch (cardType) {
    case "Apple Card":
      return "banking-lime-accent";
    case "Business Card":
      return "bg-gradient-to-br from-rose-400 to-pink-600";
    case "Debit Card":
      return "bg-gradient-to-br from-slate-800 to-slate-900";
    default:
      return "banking-lime-accent";
  }
};

export default function BalanceCard({ account, cards, onAddAgency }: BalanceCardProps) {
  const [currentCardIndex, setCurrentCardIndex] = useState(0);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const [isEditMode, setIsEditMode] = useState(false);
  const [, setLocation] = useLocation();
  const queryClient = useQueryClient();
  const { toast } = useToast();

  useEffect(() => {
    // Get authenticated user ID from localStorage
    const userId = localStorage.getItem("currentUserId");
    setCurrentUserId(userId);
  }, []);

  // Fetch jobs for all agencies to calculate real-time balances
  const { data: allJobs = [] } = useQuery<Job[]>({
    queryKey: [`/api/jobs/${currentUserId}`],
    enabled: !!currentUserId,
    staleTime: 0, // Always fetch fresh data
  });

  // Fetch user's agencies
  const { data: agencies = [] } = useQuery<Agency[]>({
    queryKey: [`/api/agencies/${currentUserId}`],
    enabled: !!currentUserId,
    staleTime: 0, // Always fetch fresh data
  });

  // Delete agency mutation
  const deleteAgencyMutation = useMutation({
    mutationFn: async (agencyId: number) => {
      const response = await apiRequest("DELETE", `/api/agencies/${agencyId}`);
      return await response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [`/api/agencies/${currentUserId}`] });
      queryClient.invalidateQueries({ queryKey: [`/api/jobs/${currentUserId}`] });
      toast({
        title: "Success",
        description: "Agency deleted successfully",
      });
    },
    onError: (error) => {
      toast({
        title: "Error",
        description: "Failed to delete agency",
        variant: "destructive",
      });
    }
  });

  // Calculate real-time balances for any agency
  const calculateAgencyBalance = (agencyName: string) => {
    const agencyJobs = allJobs.filter(job => job.bookedBy === agencyName);
    const totalEarnings = agencyJobs.reduce((sum, job) => sum + parseFloat(job.amount), 0);
    // Available balance after 20% commission
    const availableBalance = totalEarnings * 0.8;
    
    return {
      balance: availableBalance,
      totalEarnings,
      jobCount: agencyJobs.length
    };
  };

  // Generate agency card data from agencies and jobs
  const getAgencyCardData = () => {
    // If we have user agencies from API, show them
    if (agencies.length > 0) {
      // Add custom agencies from API
      const customAgencies = agencies.map(agency => {
        const metrics = calculateAgencyBalance(agency.name);
        const routeKey = agency.name.toLowerCase().replace(/\s+/g, "-").replace(/[^\w-]/g, "");
        
        return {
          name: agency.name,
          routeKey,
          color: getAgencyColor(agency.name),
          metrics,
          isCustom: true,
          id: agency.id
        };
      });

      return customAgencies;
    }

    // For new users with no agencies, return empty array - only Add Account button will show
    return [];
  };

  // Get color based on agency name
  const getAgencyColor = (agencyName: string) => {
    const colors = ["purple", "green", "blue", "orange", "indigo", "pink", "teal", "red"];
    const hash = agencyName.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    return colors[hash % colors.length];
  };

  const agencyCards = getAgencyCardData();

  // Helper function to get color classes for agency cards
  const getColorClasses = (color: string) => {
    const colorMap: Record<string, { bg: string; stroke: string; fallback: string }> = {
      purple: { bg: "bg-purple-200", stroke: "#8B5CF6", fallback: "bg-purple-500" },
      green: { bg: "bg-green-200", stroke: "#22c55e", fallback: "bg-green-500" },
      blue: { bg: "bg-blue-200", stroke: "#3b82f6", fallback: "bg-blue-500" },
      orange: { bg: "bg-orange-200", stroke: "#f97316", fallback: "bg-orange-500" },
      indigo: { bg: "bg-indigo-200", stroke: "#6366f1", fallback: "bg-indigo-500" },
      pink: { bg: "bg-pink-200", stroke: "#ec4899", fallback: "bg-pink-500" },
      teal: { bg: "bg-teal-200", stroke: "#14b8a6", fallback: "bg-teal-500" },
      red: { bg: "bg-red-200", stroke: "#ef4444", fallback: "bg-red-500" }
    };
    return colorMap[color] || colorMap.purple;
  };

  // Helper function to render agency card
  const renderAgencyCard = (agency: any) => {
    const colors = getColorClasses(agency.color);
    const displayName = agency.name.length > 20 ? 
      agency.name.substring(0, 20) + "..." : 
      agency.name;
    
    const nameParts = displayName.split(' ');
    const firstPart = nameParts[0];
    const secondPart = nameParts.slice(1).join(' ');
    
    return (
      <div 
        key={`agency-${agency.id}`}
        className="relative group cursor-pointer flex-shrink-0 w-44"
        onClick={!isEditMode ? () => setLocation(`/account/${agency.routeKey}`) : undefined}
      >
        {/* Delete button in edit mode */}
        {isEditMode && (
          <button
            className="absolute top-1 right-1 z-10 w-6 h-6 bg-red-500 hover:bg-red-600 text-white rounded-full flex items-center justify-center transition-colors"
            onClick={(e) => {
              e.stopPropagation();
              if (window.confirm(`Are you sure you want to delete ${agency.name}? This will also delete all associated jobs.`)) {
                deleteAgencyMutation.mutate(agency.id);
              }
            }}
          >
            <X className="w-3 h-3" />
          </button>
        )}
        
        {/* Folder background */}
        <div className={`absolute inset-0 ${colors.bg} rounded-t-2xl h-5 w-full transform translate-y-2`}></div>
        {/* Main folder card */}
        <div className={`relative rounded-2xl p-3 border border-gray-100 transition-all duration-300 bg-white ${
          !isEditMode ? 'hover:shadow-lg hover:scale-[1.02] hover:-translate-y-1' : ''
        } ${isEditMode ? 'opacity-75' : ''}`}>
          {/* Agency Logo/Icon in top right */}
          <AgencyLogoIcon 
            agencyName={agency.name} 
            fallbackIcon={agency.name.charAt(0)} 
            fallbackColor={colors.fallback} 
          />
          
          <div className="mb-6">
            <h4 className="text-gray-800 font-semibold text-sm mb-1">{firstPart}</h4>
            <p className="text-gray-600 text-xs">{secondPart || ""}</p>
          </div>
          
          {/* Chart area */}
          <div className="mb-3 h-10 flex items-end">
            <svg className="w-full h-full" viewBox="0 0 100 40">
              <path
                d="M 5 35 Q 20 25 35 28 Q 50 22 65 20 Q 80 15 95 12"
                stroke={colors.stroke}
                strokeWidth="2.5"
                fill="none"
                className="drop-shadow-sm"
              />
              <circle cx="95" cy="12" r="2" fill={colors.stroke} />
            </svg>
          </div>
          
          <div className="flex justify-between items-end">
            <div className="text-lg font-bold text-gray-900">${formatCurrency(agency.metrics.balance.toString())}</div>
            <span className="text-xs text-gray-500 font-medium">{agency.metrics.jobCount} jobs</span>
          </div>
        </div>
      </div>
    );
  };

  // Calculate overall financial metrics from all jobs
  const calculateOverallMetrics = () => {
    if (!allJobs || allJobs.length === 0) {
      return {
        totalInvoiceIncome: 0,
        totalExpenses: 0,
        netProfit: 0,
        profitMargin: 0,
        totalAvailableBalance: 0,
        growthPercentage: 0
      };
    }

    // Total invoice income (gross earnings from all jobs)
    const totalInvoiceIncome = allJobs.reduce((sum, job) => sum + parseFloat(job.amount), 0);
    
    // Expenses are calculated as 20% commission (what agencies take)
    const totalExpenses = totalInvoiceIncome * 0.2;
    
    // Net profit is what the model actually receives (80% after commission)
    const netProfit = totalInvoiceIncome * 0.8;
    
    // Profit margin calculation
    const profitMargin = totalInvoiceIncome > 0 ? (netProfit / totalInvoiceIncome * 100) : 0;
    
    // Total available balance is same as net profit
    const totalAvailableBalance = netProfit;

    // Calculate growth percentage (comparing current month to last month)
    const currentDate = new Date();
    const currentMonth = currentDate.getMonth();
    const currentYear = currentDate.getFullYear();
    const lastMonth = new Date(currentYear, currentMonth - 1);

    const currentMonthIncome = allJobs
      .filter(job => {
        const jobDate = new Date(job.jobDate);
        return jobDate.getMonth() === currentMonth && jobDate.getFullYear() === currentYear;
      })
      .reduce((sum, job) => sum + parseFloat(job.amount), 0);

    const lastMonthIncome = allJobs
      .filter(job => {
        const jobDate = new Date(job.jobDate);
        return jobDate.getMonth() === lastMonth.getMonth() && jobDate.getFullYear() === lastMonth.getFullYear();
      })
      .reduce((sum, job) => sum + parseFloat(job.amount), 0);

    const growthPercentage = lastMonthIncome > 0 ? 
      ((currentMonthIncome - lastMonthIncome) / lastMonthIncome * 100) : 0;

    return {
      totalInvoiceIncome,
      totalExpenses,
      netProfit,
      profitMargin,
      totalAvailableBalance,
      growthPercentage
    };
  };

  const overallMetrics = calculateOverallMetrics();

  
  
  if (!cards || cards.length === 0) {
    return null;
  }

  const currentCard = cards[currentCardIndex];

  const handleCardSwipe = () => {
    setCurrentCardIndex((prev) => (prev + 1) % cards.length);
  };

  const handleViewDetails = (e: React.MouseEvent) => {
    e.stopPropagation();
    const agencyRoutes: { [key: string]: string } = {
      "ELITE Model Management": "/agency/elite",
      "Wilhelmina London": "/agency/wilhelmina",
      "Society Management": "/agency/society"
    };
    
    const route = agencyRoutes[currentCard.holderName];
    if (route) {
      setLocation(route);
    }
  };

  

  return (
    <div className="px-2 mb-4">
      {/* Total Income Section */}
      <div className="mb-4">
        <div className="text-gray-600 text-sm font-medium mb-2">Total Income (USD)</div>
        <div className="flex items-center space-x-3 mb-4">
          {overallMetrics.totalInvoiceIncome > 0 ? (
            <>
              <div className="text-gray-900 text-[40px] font-semibold">${formatCurrency(overallMetrics.totalInvoiceIncome.toString())}</div>
              <span className="bg-emerald-50 text-emerald-700 text-sm px-3 py-1 rounded-full font-medium">
                +100%
              </span>
            </>
          ) : (
            <div className="text-gray-400 text-[40px] font-semibold">—</div>
          )}
        </div>
      </div>
      {/* Current Value Section */}
      <div className="mb-4">
        <div className="text-gray-600 text-sm font-medium mb-2">Net Value (USD)</div>
        <div className="flex items-center space-x-3 mb-4">
          {overallMetrics.totalAvailableBalance > 0 ? (
            <>
              <div className="text-gray-900 text-2xl font-semibold">${formatCurrency(overallMetrics.totalAvailableBalance.toString())}</div>
              <span className={`${overallMetrics.growthPercentage >= 0 ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'} text-sm px-3 py-1 rounded-full font-medium`}>
                {overallMetrics.growthPercentage >= 0 ? '+' : ''}{overallMetrics.growthPercentage.toFixed(2)}%
              </span>
            </>
          ) : (
            <div className="text-gray-400 text-2xl font-semibold">—</div>
          )}
        </div>
      </div>
      {/* Accounts Section */}
      <div className="mb-3">
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-lg font-semibold text-gray-900">Accounts</h3>
          <button
            onClick={() => setIsEditMode(!isEditMode)}
            className="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-full transition-colors"
            title={isEditMode ? "Exit edit mode" : "Edit accounts"}
          >
            {isEditMode ? <X className="w-4 h-4" /> : <Edit3 className="w-4 h-4" />}
          </button>
        </div>
        
        {isEditMode && (
          <div className="mb-2 p-2 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-sm text-red-700 flex items-center">
              <Edit3 className="w-4 h-4 mr-2" />
              Edit mode: Click the X button to delete agencies
            </p>
          </div>
        )}
        
        <div className="flex space-x-2 overflow-x-auto pb-2 scrollbar-hide">
          {agencyCards.length > 0 && agencyCards.map(agency => renderAgencyCard(agency))}

          {/* Add Account Button - only show when not in edit mode */}
          {!isEditMode && (
            <div className="relative group cursor-pointer flex-shrink-0 w-44">
            <div 
              className="relative bg-gray-50 border-2 border-dashed border-gray-300 rounded-2xl p-3 hover:border-gray-400 hover:bg-gray-100 transition-all duration-300 hover:scale-[1.02] hover:-translate-y-1"
              onClick={() => {
                onAddAgency?.();
              }}
            >
              <div className="flex flex-col items-center justify-center h-full min-h-[120px]">
                <div className="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center mb-2 group-hover:bg-gray-300 transition-colors">
                  <Plus className="w-5 h-5 text-gray-500 group-hover:text-gray-600" />
                </div>
                
                <div className="text-center">
                  <h4 className="text-gray-700 font-semibold text-sm mb-1">Add Account</h4>
                  <p className="text-gray-500 text-xs">Connect new agency</p>
                </div>
              </div>
            </div>
          </div>
          )}
        </div>
      </div>
    </div>
  );
}