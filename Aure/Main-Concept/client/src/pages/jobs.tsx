import { useLocation } from "wouter";
import { ArrowLeft, Search, Filter, Plus, Calendar, DollarSign, TrendingUp, Eye, Edit, Trash2 } from "lucide-react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Job, type InsertJob } from "../../../shared/schema";
import { useState, useEffect } from "react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import AddJobModal, { type JobData } from "@/components/add-job-modal";
import EditJobModal from "@/components/edit-job-modal";

// Brand Icon Component for Fashion Clients
const BrandIcon = ({ brandName, size = "small" }: { brandName: string; size?: "small" | "medium" | "large" }) => {
  const sizeClasses = {
    small: "w-8 h-8",
    medium: "w-10 h-10", 
    large: "w-12 h-12"
  };

  return (
    <div className={`${sizeClasses[size]} bg-gradient-to-br from-blue-100 to-purple-100 rounded-xl flex items-center justify-center`}>
      <span className="text-blue-600 font-bold text-xs">{brandName.slice(0, 2).toUpperCase()}</span>
    </div>
  );
};

const formatDate = (date: Date) => {
  return new Intl.DateTimeFormat('en-US', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric'
  }).format(new Date(date));
};

const getStatusColor = (status: string) => {
  switch (status) {
    case 'Received':
      return 'text-green-600 bg-green-50';
    case 'Pending':
      return 'text-orange-600 bg-orange-50';
    case 'Invoiced':
      return 'text-blue-600 bg-blue-50';
    case 'Partially Paid':
      return 'text-yellow-600 bg-yellow-50';
    default:
      return 'text-gray-600 bg-gray-50';
  }
};

interface JobsPageProps {
  accountName?: string;
}

export default function JobsPage({ accountName }: JobsPageProps) {
  const [, setLocation] = useLocation();
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [filterStatus, setFilterStatus] = useState("all");
  const [filterAgency, setFilterAgency] = useState("all");
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [isAddJobModalOpen, setIsAddJobModalOpen] = useState(false);
  const [isEditJobModalOpen, setIsEditJobModalOpen] = useState(false);
  const [selectedJob, setSelectedJob] = useState<Job | null>(null);
  const [sortBy, setSortBy] = useState<"date" | "amount" | "client">("date");
  const [sortOrder, setSortOrder] = useState<"asc" | "desc">("desc");
  const { toast } = useToast();
  const queryClient = useQueryClient();

  useEffect(() => {
    const userId = localStorage.getItem("currentUserId");
    if (!userId || userId === "1") {
      const fallbackUserId = "9";
      localStorage.setItem("currentUserId", fallbackUserId);
      localStorage.setItem("userAuthenticated", "true");
      setCurrentUserId(fallbackUserId);
    } else {
      setCurrentUserId(userId);
    }
  }, []);

  const { data: jobs = [], isLoading } = useQuery<Job[]>({
    queryKey: [`/api/jobs/${currentUserId}`],
    enabled: !!currentUserId,
  });

  const { data: agencies = [] } = useQuery({
    queryKey: [`/api/agencies/${currentUserId}`],
    enabled: !!currentUserId,
  });

  // Map account name to agency name for filtering
  const getAgencyNameFromAccount = (accountName: string) => {
    const accountToAgencyMap: Record<string, string> = {
      "Soul Artist Model Management": "Soul Artist Management",
      "Wilhelmina London Model Management": "Wilhelmina London", 
      "Society Model Management": "WHY NOT Management",
      // Handle encoded names
      "Soul%20Artist%20Model%20Management": "Soul Artist Management",
      "Wilhelmina%20London%20Model%20Management": "Wilhelmina London",
      "Society%20Model%20Management": "WHY NOT Management"
    };
    return accountToAgencyMap[accountName] || accountName;
  };

  // Filter jobs by account if accountName is provided
  const accountFilteredJobs = accountName 
    ? jobs.filter(job => {
        const targetAgency = getAgencyNameFromAccount(decodeURIComponent(accountName));
        return job.bookedBy === targetAgency;
      })
    : jobs;

  // Filter and sort jobs
  const filteredJobs = accountFilteredJobs
    .filter(job => {
      const matchesSearch = searchTerm === "" || 
        job.client.toLowerCase().includes(searchTerm.toLowerCase()) ||
        job.bookedBy.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (job.jobTitle && job.jobTitle.toLowerCase().includes(searchTerm.toLowerCase()));
      
      const matchesStatus = filterStatus === "all" || job.status === filterStatus;
      const matchesAgency = filterAgency === "all" || job.bookedBy === filterAgency;
      
      return matchesSearch && matchesStatus && matchesAgency;
    })
    .sort((a, b) => {
      let compareValue = 0;
      
      switch (sortBy) {
        case "date":
          compareValue = new Date(a.jobDate).getTime() - new Date(b.jobDate).getTime();
          break;
        case "amount":
          compareValue = parseFloat(a.amount) - parseFloat(b.amount);
          break;
        case "client":
          compareValue = a.client.localeCompare(b.client);
          break;
      }
      
      return sortOrder === "desc" ? -compareValue : compareValue;
    });

  // Add Job Mutation
  const addJobMutation = useMutation({
    mutationFn: (jobData: JobData) => {
      const payload = {
        ...jobData,
        userId: parseInt(currentUserId || "9"),
        amount: jobData.amount.toString(),
        jobDate: jobData.jobDate.toISOString(),
        dueDate: jobData.dueDate.toISOString()
      };
      return apiRequest("POST", "/api/jobs", payload);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [`/api/jobs/${currentUserId}`] });
      queryClient.invalidateQueries({ queryKey: [`/api/dashboard/${currentUserId}`] });
      toast({
        title: "Success",
        description: "Job added successfully"
      });
    },
    onError: (error) => {
      toast({
        title: "Error",
        description: `Failed to add job: ${error.message || 'Unknown error'}`,
        variant: "destructive"
      });
    }
  });

  // Update Job Mutation
  const updateJobMutation = useMutation({
    mutationFn: ({ jobId, jobData }: { jobId: number; jobData: Partial<Job> }) => {
      return apiRequest("PATCH", `/api/jobs/${jobId}`, jobData);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [`/api/jobs/${currentUserId}`] });
      queryClient.invalidateQueries({ queryKey: [`/api/dashboard/${currentUserId}`] });
      toast({
        title: "Success",
        description: "Job updated successfully"
      });
    },
    onError: (error) => {
      toast({
        title: "Error",
        description: `Failed to update job: ${error.message || 'Unknown error'}`,
        variant: "destructive"
      });
    }
  });

  // Delete Job Mutation
  const deleteJobMutation = useMutation({
    mutationFn: (jobId: number) => {
      return apiRequest("DELETE", `/api/jobs/${jobId}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [`/api/jobs/${currentUserId}`] });
      queryClient.invalidateQueries({ queryKey: [`/api/dashboard/${currentUserId}`] });
      toast({
        title: "Success",
        description: "Job deleted successfully"
      });
    },
    onError: (error) => {
      toast({
        title: "Error",
        description: `Failed to delete job: ${error.message || 'Unknown error'}`,
        variant: "destructive"
      });
    }
  });

  const handleAddJob = (jobData: JobData) => {
    addJobMutation.mutate(jobData);
  };

  const handleEditJob = (job: Job) => {
    setSelectedJob(job);
    setIsEditJobModalOpen(true);
  };

  const handleUpdateJob = (jobId: number, jobData: Partial<Job>) => {
    updateJobMutation.mutate({ jobId, jobData });
    setIsEditJobModalOpen(false);
    setSelectedJob(null);
  };

  const handleDeleteJob = (jobId: number) => {
    if (confirm("Are you sure you want to delete this job?")) {
      deleteJobMutation.mutate(jobId);
    }
  };

  // Calculate statistics based on account-filtered jobs
  const totalEarnings = accountFilteredJobs.reduce((sum, job) => sum + parseFloat(job.amount), 0);
  const averageJobValue = accountFilteredJobs.length > 0 ? totalEarnings / accountFilteredJobs.length : 0;
  const pendingJobs = accountFilteredJobs.filter(job => job.status === 'Pending').length;
  const completedJobs = accountFilteredJobs.filter(job => job.status === 'Received').length;

  if (isLoading) {
    return (
      <div className="max-w-sm mx-auto bg-background min-h-screen flex items-center justify-center">
        <div className="text-foreground">Loading jobs...</div>
      </div>
    );
  }

  return (
    <div className="w-full max-w-md mx-auto bg-background min-h-screen">
      {/* Header */}
      <div className="px-4 py-3 border-b border-border sticky top-0 bg-background z-10">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <button 
              onClick={() => setLocation(accountName ? `/account/${encodeURIComponent(accountName)}` : "/")}
              className="p-1.5 hover:bg-muted rounded-full transition-colors"
            >
              <ArrowLeft className="w-4 h-4 text-foreground" />
            </button>
            <div>
              <h1 className="text-lg font-semibold text-foreground">
                {accountName ? `${getAgencyNameFromAccount(decodeURIComponent(accountName))} Jobs` : 'All Jobs'}
              </h1>
              <p className="text-muted-foreground text-xs">{filteredJobs.length} jobs found</p>
            </div>
          </div>
          <button 
            onClick={() => setIsAddJobModalOpen(true)}
            className="p-2 bg-blue-500 hover:bg-blue-600 rounded-full transition-colors"
          >
            <Plus className="w-4 h-4 text-white" />
          </button>
        </div>
      </div>

      {/* Statistics Cards */}
      <div className="px-4 py-4">
        <div className="grid grid-cols-2 gap-3 mb-4">
          <div className="bg-white rounded-xl p-3 border border-gray-100">
            <div className="text-xs text-gray-500 mb-1">Total Earnings</div>
            <div className="text-lg font-bold text-gray-900">
              ${totalEarnings.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
          </div>
          <div className="bg-white rounded-xl p-3 border border-gray-100">
            <div className="text-xs text-gray-500 mb-1">Average Job</div>
            <div className="text-lg font-bold text-gray-900">
              ${averageJobValue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
          </div>
          <div className="bg-white rounded-xl p-3 border border-gray-100">
            <div className="text-xs text-gray-500 mb-1">Pending</div>
            <div className="text-lg font-bold text-orange-600">{pendingJobs}</div>
          </div>
          <div className="bg-white rounded-xl p-3 border border-gray-100">
            <div className="text-xs text-gray-500 mb-1">Completed</div>
            <div className="text-lg font-bold text-green-600">{completedJobs}</div>
          </div>
        </div>

        {/* Search and Filter */}
        <div className="bg-white rounded-xl p-4 border border-gray-100 mb-4">
          <div className="flex items-center space-x-2 mb-3">
            <div className="relative flex-1">
              <Search className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search jobs, clients, agencies..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            <button 
              onClick={() => setIsFilterOpen(!isFilterOpen)}
              className={`p-2 rounded-lg transition-colors ${
                isFilterOpen || filterStatus !== "all" || filterAgency !== "all" 
                  ? "bg-blue-500 text-white" 
                  : "bg-gray-100 text-gray-500 hover:bg-gray-200"
              }`}
            >
              <Filter className="w-4 h-4" />
            </button>
          </div>

          {/* Filter Panel */}
          {isFilterOpen && (
            <div className="border-t border-gray-100 pt-3 space-y-3">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs text-gray-600 mb-1 block">Status</label>
                  <select
                    value={filterStatus}
                    onChange={(e) => setFilterStatus(e.target.value)}
                    className="w-full text-xs p-2 border border-gray-200 rounded-md bg-white focus:outline-none focus:ring-1 focus:ring-blue-500"
                  >
                    <option value="all">All Status</option>
                    <option value="Pending">Pending</option>
                    <option value="Invoiced">Invoiced</option>
                    <option value="Partially Paid">Partially Paid</option>
                    <option value="Received">Received</option>
                  </select>
                </div>
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
              </div>
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <label className="text-xs text-gray-600">Sort by:</label>
                  <select
                    value={sortBy}
                    onChange={(e) => setSortBy(e.target.value as "date" | "amount" | "client")}
                    className="text-xs p-1 border border-gray-200 rounded bg-white focus:outline-none focus:ring-1 focus:ring-blue-500"
                  >
                    <option value="date">Date</option>
                    <option value="amount">Amount</option>
                    <option value="client">Client</option>
                  </select>
                  <button
                    onClick={() => setSortOrder(sortOrder === "asc" ? "desc" : "asc")}
                    className="text-xs px-2 py-1 bg-gray-100 rounded hover:bg-gray-200 transition-colors"
                  >
                    {sortOrder === "asc" ? "↑" : "↓"}
                  </button>
                </div>
                <button
                  onClick={() => {
                    setFilterStatus("all");
                    setFilterAgency("all");
                    setSearchTerm("");
                    setSortBy("date");
                    setSortOrder("desc");
                  }}
                  className="text-xs text-blue-500 hover:text-blue-600 font-medium"
                >
                  Clear All
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Jobs List */}
      <div className="px-4 pb-24">
        {filteredJobs.length === 0 ? (
          <div className="text-center py-12">
            <div className="w-16 h-16 mx-auto mb-4 bg-gray-100 rounded-full flex items-center justify-center">
              <Calendar className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">No jobs found</h3>
            <p className="text-gray-500 text-sm mb-4">
              {searchTerm || filterStatus !== "all" || filterAgency !== "all" 
                ? "Try adjusting your search or filters"
                : "Add your first job to get started"
              }
            </p>
            <button 
              onClick={() => setIsAddJobModalOpen(true)}
              className="bg-blue-500 text-white px-6 py-2 rounded-lg font-medium hover:bg-blue-600 transition-colors"
            >
              Add Job
            </button>
          </div>
        ) : (
          <div className="space-y-3">
            {filteredJobs.map((job) => (
              <div key={job.id} className="bg-white rounded-xl p-4 border border-gray-100">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center space-x-3 flex-1">
                    <BrandIcon brandName={job.client.trim()} size="medium" />
                    <div className="flex-1">
                      <div className="text-sm font-semibold text-gray-900">{job.client}</div>
                      <div className="text-xs text-gray-500">
                        {job.jobTitle || 'Campaign'} • {job.bookedBy}
                      </div>
                      <div className="text-xs text-gray-500 mt-1">
                        {formatDate(job.jobDate)} • Due: {formatDate(job.dueDate)}
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-lg font-bold text-gray-900">
                      ${parseFloat(job.amount).toLocaleString()}
                    </div>
                    <div className={`text-xs px-2 py-1 rounded-full ${getStatusColor(job.status)}`}>
                      {job.status}
                    </div>
                  </div>
                </div>
                
                {/* Action Buttons */}
                <div className="flex space-x-2 pt-2 border-t border-gray-100">
                  <button 
                    onClick={() => handleEditJob(job)}
                    className="flex-1 bg-blue-500 hover:bg-blue-600 text-white text-xs py-2 px-3 rounded-lg transition-colors flex items-center justify-center space-x-1"
                  >
                    <Edit className="w-3 h-3" />
                    <span>Edit</span>
                  </button>
                  <button 
                    onClick={() => handleDeleteJob(job.id)}
                    disabled={deleteJobMutation.isPending}
                    className="flex-1 bg-red-500 hover:bg-red-600 text-white text-xs py-2 px-3 rounded-lg transition-colors disabled:opacity-50 flex items-center justify-center space-x-1"
                  >
                    <Trash2 className="w-3 h-3" />
                    <span>{deleteJobMutation.isPending ? 'Deleting...' : 'Delete'}</span>
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Add Job Modal */}
      <AddJobModal
        isOpen={isAddJobModalOpen}
        onClose={() => setIsAddJobModalOpen(false)}
        onAddJob={handleAddJob}
        userId={parseInt(currentUserId || "9")}
      />

      {/* Edit Job Modal */}
      <EditJobModal
        isOpen={isEditJobModalOpen}
        onClose={() => {
          setIsEditJobModalOpen(false);
          setSelectedJob(null);
        }}
        onUpdateJob={handleUpdateJob}
        job={selectedJob}
      />
    </div>
  );
}