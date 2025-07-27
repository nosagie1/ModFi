import BottomNavigation from "@/components/bottom-navigation";
import JobItem from "@/components/job-item";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Crown, Star, Diamond, Search, Filter, Plus, X, ArrowLeft } from "lucide-react";
import type { Transaction, Job } from "@shared/schema";
import AddJobModal, { type JobData } from "@/components/add-job-modal";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import { useState, useEffect } from "react";
import { useLocation } from "wouter";

const getTransactionIcon = (iconName: string, iconColor: string) => {
  const className = `w-6 h-6 ${iconColor}`;
  
  switch (iconName) {
    case "crown":
      return <Crown className={className} />;
    case "star":
      return <Star className={className} />;
    case "diamond":
      return <Diamond className={className} />;
    default:
      return <div className={`w-6 h-6 ${iconColor}`} />;
  }
};

const formatDate = (date: Date) => {
  return new Intl.DateTimeFormat('en-US', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric'
  }).format(new Date(date));
};

const formatAmount = (amount: string) => {
  const numAmount = parseFloat(amount);
  return numAmount < 0 ? `-$${Math.abs(numAmount).toFixed(0)}` : `$${numAmount.toFixed(0)}`;
};

export default function Reports() {
  const [, setLocation] = useLocation();
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const [isAddJobModalOpen, setIsAddJobModalOpen] = useState(false);
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [filterAgency, setFilterAgency] = useState("all");
  const [filterStatus, setFilterStatus] = useState("all");
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [selectedSuggestionIndex, setSelectedSuggestionIndex] = useState(-1);
  const { toast } = useToast();
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

  const { data: dashboardData, isLoading } = useQuery({
    queryKey: [`/api/dashboard/${currentUserId}`],
    enabled: !!currentUserId,
  });

  const { data: jobs = [] } = useQuery<Job[]>({
    queryKey: [`/api/jobs/${currentUserId}`],
    enabled: !!currentUserId,
  });

  const { data: agencies = [] } = useQuery({
    queryKey: [`/api/agencies/${currentUserId}`],
    enabled: !!currentUserId,
  });

  // Generate search suggestions
  const getSearchSuggestions = () => {
    if (!searchTerm || searchTerm.length < 2) return [];
    
    const suggestions = new Set<string>();
    const searchLower = searchTerm.toLowerCase();
    
    jobs.forEach(job => {
      // Add client names that match (trim spaces and normalize)
      const clientName = job.client.trim();
      if (clientName.toLowerCase().includes(searchLower)) {
        suggestions.add(clientName);
      }
      // Add job titles that match (trim spaces and normalize)
      if (job.jobTitle) {
        const jobTitle = job.jobTitle.trim();
        if (jobTitle.toLowerCase().includes(searchLower)) {
          suggestions.add(jobTitle);
        }
      }
      // Add agency names that match
      if (job.bookedBy.toLowerCase().includes(searchLower)) {
        suggestions.add(job.bookedBy);
      }
    });
    
    return Array.from(suggestions).slice(0, 5); // Limit to 5 suggestions
  };

  const suggestions = getSearchSuggestions();

  // Handle keyboard navigation
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (!showSuggestions || suggestions.length === 0) return;
    
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        setSelectedSuggestionIndex(prev => 
          prev < suggestions.length - 1 ? prev + 1 : 0
        );
        break;
      case 'ArrowUp':
        e.preventDefault();
        setSelectedSuggestionIndex(prev => 
          prev > 0 ? prev - 1 : suggestions.length - 1
        );
        break;
      case 'Enter':
        e.preventDefault();
        if (selectedSuggestionIndex >= 0) {
          setSearchTerm(suggestions[selectedSuggestionIndex]);
          setShowSuggestions(false);
          setSelectedSuggestionIndex(-1);
        }
        break;
      case 'Escape':
        setShowSuggestions(false);
        setSelectedSuggestionIndex(-1);
        break;
    }
  };

  const handleSearchChange = (value: string) => {
    setSearchTerm(value);
    setShowSuggestions(value.length >= 2);
    setSelectedSuggestionIndex(-1);
  };

  const selectSuggestion = (suggestion: string) => {
    setSearchTerm(suggestion);
    setShowSuggestions(false);
    setSelectedSuggestionIndex(-1);
  };

  // Calculate real metrics from job data
  const totalGrossEarnings = jobs.reduce((sum, job) => sum + parseFloat(job.amount), 0);
  const totalFees = totalGrossEarnings * 0.2; // 20% commission
  const totalNetEarnings = totalGrossEarnings - totalFees;

  // Calculate overdue amounts
  const overdueJobs = jobs.filter(job => {
    const dueDate = new Date(job.dueDate);
    return dueDate < new Date() && ['Pending', 'Invoiced', 'Partially Paid'].includes(job.status);
  });
  const overdueAmount = overdueJobs.reduce((sum, job) => sum + parseFloat(job.amount), 0);

  // Calculate agency-specific earnings
  const soulArtistJobs = jobs.filter(job => job.bookedBy === "Soul Artist Management");
  const wilhelminaJobs = jobs.filter(job => job.bookedBy === "Wilhelmina London");
  const societyJobs = jobs.filter(job => job.bookedBy === "WHY NOT Management");

  const soulArtistEarnings = soulArtistJobs.reduce((sum, job) => sum + parseFloat(job.amount), 0);
  const wilhelminaEarnings = wilhelminaJobs.reduce((sum, job) => sum + parseFloat(job.amount), 0);
  const societyEarnings = societyJobs.reduce((sum, job) => sum + parseFloat(job.amount), 0);

  const soulArtistPercentage = totalGrossEarnings > 0 ? (soulArtistEarnings / totalGrossEarnings * 100) : 0;
  const wilhelminaPercentage = totalGrossEarnings > 0 ? (wilhelminaEarnings / totalGrossEarnings * 100) : 0;
  const societyPercentage = totalGrossEarnings > 0 ? (societyEarnings / totalGrossEarnings * 100) : 0;

  const addJobMutation = useMutation({
    mutationFn: (jobData: JobData) => {
      const payload = {
        ...jobData,
        userId: parseInt(currentUserId || "9"), // Current user ID
        amount: jobData.amount.toString(),
        jobDate: jobData.jobDate.toISOString(),
        dueDate: jobData.dueDate.toISOString()
      };
      return apiRequest("POST", "/api/jobs", payload);
    },
    onSuccess: () => {
      // Invalidate all job-related queries to ensure data consistency across pages
      queryClient.invalidateQueries({ queryKey: [`/api/jobs/${currentUserId}`] });
      // Also invalidate dashboard data to update all metrics
      queryClient.invalidateQueries({ queryKey: [`/api/dashboard/${currentUserId}`] });
      toast({
        title: "Success",
        description: "Job added successfully"
      });
    },
    onError: (error) => {
      console.error("Job creation error:", error);
      toast({
        title: "Error",
        description: `Failed to add job: ${error.message || 'Unknown error'}`,
        variant: "destructive"
      });
    }
  });

  const handleAddJob = (jobData: JobData) => {
    addJobMutation.mutate(jobData);
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
        <div className="text-foreground">Error loading data</div>
      </div>
    );
  }

  const { transactions } = dashboardData as any;

  return (
    <div className="w-full max-w-md mx-auto bg-background min-h-screen relative overflow-x-hidden">
      {/* Header */}
      <div className="px-4 py-3">
        <div className="flex justify-between items-start">
          <div className="flex items-center space-x-3">
            <button 
              onClick={() => setLocation("/")}
              className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-full transition-colors"
            >
              <ArrowLeft className="h-5 w-5 text-gray-600 dark:text-gray-400" />
            </button>
            <div>
              <h1 className="text-lg font-semibold text-foreground">Reports</h1>
              <p className="text-muted-foreground text-xs">Track your agency earnings</p>
            </div>
          </div>
        </div>
      </div>
      {/* Project Overview Section */}
      <div className="px-2 mb-4">
        {/* Total Earnings and Projects - Side by Side */}
        <div className="flex justify-between items-start gap-4 mb-3">
          <div className="flex-1">
            <div className="text-xs text-muted-foreground mb-1">Total Earnings</div>
            <div className="text-2xl font-bold text-foreground">
              ${totalGrossEarnings.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
          </div>
          <div className="flex-1 text-right">
            <div className="text-xs text-muted-foreground mb-1">Total Projects</div>
            <div className="text-2xl font-bold text-foreground">{jobs.length} jobs</div>
          </div>
        </div>
          
        {/* Fees & Overdue */}
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3 border border-blue-100 dark:border-blue-800/30">
            <div className="text-xs text-muted-foreground mb-1">Fees</div>
            <div className="text-sm font-semibold text-foreground">
              ${totalFees.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
          </div>
          <div className="bg-red-50 dark:bg-red-900/20 rounded-lg p-3 border border-red-100 dark:border-red-800/30">
            <div className="flex items-center space-x-2 mb-1">
              <div className="text-xs text-muted-foreground">Overdue</div>
              {overdueJobs.length > 0 && (
                <div className="bg-red-500 text-white text-xs px-1 rounded">{overdueJobs.length}x</div>
              )}
            </div>
            <div className="text-sm font-semibold text-foreground">
              ${overdueAmount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
          </div>
        </div>
      </div>
      {/* Agency Breakdown */}
      <div className="px-2 mb-4">
        <h2 className="text-foreground text-base font-semibold mb-4">Top Agency</h2>
        
        <div className="space-y-3">
          {soulArtistJobs.length > 0 && (
            <div className="bg-gradient-to-br from-purple-50 to-purple-100/80 dark:from-purple-900/20 dark:to-purple-800/30 rounded-lg p-3 border border-purple-100 dark:border-purple-800/30">
              <div className="flex justify-between items-center">
                <div>
                  <div className="text-foreground font-medium text-sm">Soul Artist Management</div>
                  <div className="text-muted-foreground text-xs">{soulArtistPercentage.toFixed(1)}% of total earnings</div>
                </div>
                <div className="text-foreground font-bold text-sm">
                  ${soulArtistEarnings.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </div>
              </div>
            </div>
          )}
          
          {wilhelminaJobs.length > 0 && (
            <div className="bg-gradient-to-br from-blue-50 to-blue-100/80 dark:from-blue-900/20 dark:to-blue-800/30 rounded-lg p-3 border border-blue-100 dark:border-blue-800/30">
              <div className="flex justify-between items-center">
                <div>
                  <div className="text-foreground font-medium text-sm">Wilhelmina London</div>
                  <div className="text-muted-foreground text-xs">{wilhelminaPercentage.toFixed(1)}% of total earnings</div>
                </div>
                <div className="text-foreground font-bold text-sm">
                  ${wilhelminaEarnings.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </div>
              </div>
            </div>
          )}
          
          {societyJobs.length > 0 && (
            <div className="bg-gradient-to-br from-gray-50 to-gray-100/80 dark:from-gray-900/20 dark:to-gray-800/30 rounded-lg p-3 border border-gray-100 dark:border-gray-800/30">
              <div className="flex justify-between items-center">
                <div>
                  <div className="text-foreground font-medium text-sm">WHY NOT Management</div>
                  <div className="text-muted-foreground text-xs">{societyPercentage.toFixed(1)}% of total earnings</div>
                </div>
                <div className="text-foreground font-bold text-sm">
                  ${societyEarnings.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
      {/* Jobs Section */}
      <div className="px-2 mb-4">
        <div className="bg-white rounded-2xl p-4 border border-gray-100 shadow-sm mt-[-10px] mb-[-10px]">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-foreground text-lg font-semibold">Jobs</h2>
            <button 
              onClick={() => setIsFilterOpen(!isFilterOpen)}
              className={`w-8 h-8 rounded-full flex items-center justify-center transition-all duration-200 ${
                isFilterOpen || filterAgency !== "all" || filterStatus !== "all" 
                  ? "bg-gradient-to-br from-blue-500 to-blue-600 shadow-md" 
                  : "bg-gray-100 hover:bg-gray-200"
              }`}
            >
              <Filter className={`w-4 h-4 ${
                isFilterOpen || filterAgency !== "all" || filterStatus !== "all" 
                  ? "text-white" 
                  : "text-gray-500"
              }`} />
            </button>
          </div>
          
          {/* Filter Panel */}
          {isFilterOpen && (
            <div className="mb-4 p-4 bg-gray-50 rounded-lg border border-gray-200">
              <div className="flex items-center justify-between mb-3">
                <h3 className="text-sm font-semibold text-gray-700">Filter Jobs</h3>
                <button 
                  onClick={() => {
                    setFilterAgency("all");
                    setFilterStatus("all");
                    setSearchTerm("");
                  }}
                  className="text-xs text-blue-500 hover:text-blue-600 font-medium"
                >
                  Clear All
                </button>
              </div>
              
              <div className="grid grid-cols-2 gap-3 mb-3">
                <div>
                  <label className="text-xs text-gray-600 mb-1 block">Agency</label>
                  <select
                    value={filterAgency}
                    onChange={(e) => setFilterAgency(e.target.value)}
                    className="w-full text-xs p-2 border border-gray-200 rounded-md bg-white focus:outline-none focus:ring-1 focus:ring-blue-500"
                  >
                    <option value="all">All Agencies</option>
                    {agencies.map((agency: any) => (
                      <option key={agency.id} value={agency.name}>
                        {agency.name}
                      </option>
                    ))}
                  </select>
                </div>
                
                <div>
                  <label className="text-xs text-gray-600 mb-1 block">Status</label>
                  <select
                    value={filterStatus}
                    onChange={(e) => setFilterStatus(e.target.value)}
                    className="w-full text-xs p-2 border border-gray-200 rounded-md bg-white focus:outline-none focus:ring-1 focus:ring-blue-500"
                  >
                    <option value="all">All Status</option>
                    <option value="Received">Received</option>
                    <option value="Pending">Pending</option>
                    <option value="Invoiced">Invoiced</option>
                    <option value="Partially Paid">Partially Paid</option>
                  </select>
                </div>
              </div>
            </div>
          )}

          {/* Search Bar with Autocomplete */}
          <div className="relative mb-6">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <Search className="h-4 w-4 text-muted-foreground" />
            </div>
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => handleSearchChange(e.target.value)}
              onKeyDown={handleKeyDown}
              onFocus={() => setShowSuggestions(searchTerm.length >= 2)}
              onBlur={() => setTimeout(() => setShowSuggestions(false), 200)} // Delay to allow suggestion clicks
              className="w-full pl-10 pr-4 py-3 bg-muted/50 border border-border rounded-lg text-foreground placeholder-muted-foreground focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
              placeholder="Search jobs, clients, or agencies..."
              autoComplete="off"
            />
            
            {/* Clear search button */}
            {searchTerm && (
              <button
                onClick={() => handleSearchChange("")}
                className="absolute inset-y-0 right-0 pr-3 flex items-center text-muted-foreground hover:text-foreground transition-colors"
              >
                <X className="h-4 w-4" />
              </button>
            )}

            {/* Autocomplete Suggestions */}
            {showSuggestions && suggestions.length > 0 && (
              <div className="absolute top-full left-0 right-0 mt-1 bg-white border border-gray-200 rounded-lg shadow-lg z-50 max-h-60 overflow-y-auto">
                <div className="p-2">
                  <div className="text-xs text-gray-500 mb-2 px-2">Suggestions</div>
                  {suggestions.map((suggestion, index) => (
                    <button
                      key={suggestion}
                      onClick={() => selectSuggestion(suggestion)}
                      className={`w-full text-left px-3 py-2 rounded-md text-sm transition-colors ${
                        index === selectedSuggestionIndex 
                          ? 'bg-blue-50 text-blue-700' 
                          : 'hover:bg-gray-50 text-gray-700'
                      }`}
                    >
                      <div className="flex items-center space-x-2">
                        <Search className="w-3 h-3 text-gray-400" />
                        <span>{suggestion}</span>
                      </div>
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>
          
          {/* Results Counter */}
          {(searchTerm || filterAgency !== "all" || filterStatus !== "all") && (
            <div className="mb-3 text-xs text-gray-500 flex items-center justify-between">
              <span>
                {jobs.filter((job: Job) => {
                  const searchLower = searchTerm.toLowerCase();
                  const matchesSearch = searchTerm === "" || 
                    job.client.trim().toLowerCase().includes(searchLower) ||
                    job.bookedBy.toLowerCase().includes(searchLower) ||
                    (job.jobTitle && job.jobTitle.trim().toLowerCase().includes(searchLower));
                  const matchesAgency = filterAgency === "all" || job.bookedBy === filterAgency;
                  const matchesStatus = filterStatus === "all" || job.status === filterStatus;
                  return matchesSearch && matchesAgency && matchesStatus;
                }).length} of {jobs.length} jobs
              </span>
              {(searchTerm || filterAgency !== "all" || filterStatus !== "all") && (
                <button 
                  onClick={() => {
                    setSearchTerm("");
                    setFilterAgency("all");
                    setFilterStatus("all");
                  }}
                  className="text-blue-500 hover:text-blue-600 underline"
                >
                  Clear filters
                </button>
              )}
            </div>
          )}

          {/* Job List - Scrollable */}
          <div className="relative">
            {jobs.length === 0 ? (
              <div className="text-center py-8">
                <div className="text-gray-400 mb-2">
                  <div className="w-12 h-12 mx-auto mb-3 bg-gray-100 rounded-full flex items-center justify-center">
                    <div className="w-6 h-6 border-2 border-gray-300 rounded border-dashed"></div>
                  </div>
                </div>
                <div className="text-gray-500 text-sm font-medium mb-1">No jobs have been added yet</div>
                <div className="text-gray-400 text-xs">Add your first job to start tracking</div>
              </div>
            ) : (
              <>
                <div className="max-h-96 overflow-y-auto scrollbar-thin scrollbar-thumb-gray-300 scrollbar-track-gray-100 hover:scrollbar-thumb-gray-400 transition-colors">
                  <div className="space-y-3 pr-2">
                    {jobs
                      .filter((job: Job) => {
                        // Search filter (handle spaces and normalize)
                        const searchLower = searchTerm.toLowerCase();
                        const matchesSearch = searchTerm === "" || 
                          job.client.trim().toLowerCase().includes(searchLower) ||
                          job.bookedBy.toLowerCase().includes(searchLower) ||
                          (job.jobTitle && job.jobTitle.trim().toLowerCase().includes(searchLower));
                        
                        // Agency filter
                        const matchesAgency = filterAgency === "all" || job.bookedBy === filterAgency;
                        
                        // Status filter
                        const matchesStatus = filterStatus === "all" || job.status === filterStatus;
                        
                        return matchesSearch && matchesAgency && matchesStatus;
                      })
                      .sort((a, b) => new Date(b.jobDate).getTime() - new Date(a.jobDate).getTime())
                      .map((job: Job) => {
                    const getBgColorFromAgency = (agency: string) => {
                      switch (agency) {
                        case "Soul Artist Management":
                        case "Soul Artist Model Management":
                          return "from-purple-500 to-purple-600";
                        case "Wilhelmina London":
                          return "from-green-500 to-green-600";
                        case "WHY NOT Management":
                          return "from-blue-500 to-blue-600";
                        case "IMG":
                          return "from-orange-500 to-orange-600";
                        default:
                          return "from-gray-500 to-gray-600";
                      }
                    };

                    const getAgencyInitials = (agency: string) => {
                      switch (agency) {
                        case "Soul Artist Management":
                        case "Soul Artist Model Management":
                          return "S";
                        case "Wilhelmina London":
                          return "W";
                        case "WHY NOT Management":
                          return "WN";
                        case "IMG":
                          return "I";
                        default:
                          return agency.charAt(0);
                      }
                    };

                    return (
                      <JobItem
                        key={job.id}
                        company={job.client.trim()}
                        model={job.jobTitle || job.bookedBy}
                        amount={`$${parseFloat(job.amount).toFixed(0)}`}
                        date={formatDate(job.jobDate)}
                        status={job.status as any}
                        initials={getAgencyInitials(job.bookedBy)}
                        bgColor={getBgColorFromAgency(job.bookedBy)}
                        jobTitle={job.jobTitle ?? undefined}
                        bookedBy={job.bookedBy}
                        jobDate={formatDate(job.jobDate)}
                        dueDate={formatDate(job.dueDate)}
                        job={job}
                      />
                    );
                    })}
                  </div>
                </div>
                {/* Fade indicator for scrollable content */}
                <div className="absolute bottom-0 left-0 right-0 h-6 bg-gradient-to-t from-white to-transparent pointer-events-none"></div>
              </>
            )}
          </div>
          
          {/* Add Job Button */}
          <div className="mt-4">
            <button 
              onClick={() => setIsAddJobModalOpen(true)}
              className="w-full from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 rounded-xl p-3 flex items-center justify-center space-x-2 transition-all duration-200 shadow-sm hover:shadow-md bg-[#ffffff00] text-[#0d0c0c]"
            >
              <div className="flex items-center space-x-2">
                <Plus className="w-4 h-4" />
                <span className="font-medium text-sm">Add Job</span>
              </div>
            </button>
          </div>
        </div>
      </div>
      
      {/* Bottom spacing to prevent navigation overlap */}
      <div className="h-20"></div>
      
      <BottomNavigation />
      
      {/* Add Job Modal */}
      <AddJobModal
        isOpen={isAddJobModalOpen}
        onClose={() => setIsAddJobModalOpen(false)}
        onAddJob={handleAddJob}
        userId={parseInt(currentUserId || "9")}
      />
    </div>
  );
}