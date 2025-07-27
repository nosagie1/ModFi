import { useState, useEffect } from "react";
import { ChevronDown, ChevronUp } from "lucide-react";
import EditJobModal from "./edit-job-modal";
import { Job } from "@shared/schema";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import { useAgencyBrand } from "@/hooks/use-agency-brand";

interface JobItemProps {
  company: string;
  model: string;
  amount: string;
  date: string;
  status: 'Received' | 'Upcoming' | 'Overdue' | 'Pending' | 'Invoiced' | 'Partially Paid';
  icon?: React.ReactNode;
  initials?: string;
  bgColor?: string;
  jobTitle?: string;
  bookedBy?: string;
  jobDate?: string;
  dueDate?: string;
  job?: Job | undefined; // Add full job object for editing
}

// Brand Icon Component for Fashion Clients
function BrandIcon({ brandName, fallbackInitials, fallbackBgColor }: { 
  brandName: string; 
  fallbackInitials: string; 
  fallbackBgColor: string; 
}) {
  const { data: brandInfo, isLoading } = useAgencyBrand(brandName);

  if (isLoading) {
    return (
      <div className={`w-12 h-12 bg-gradient-to-br ${fallbackBgColor} rounded-xl flex items-center justify-center`}>
        <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (brandInfo?.logo) {
    return (
      <div className="w-12 h-12 bg-white rounded-xl flex items-center justify-center border border-gray-200 shadow-sm">
        <img 
          src={brandInfo.logo} 
          alt={brandName}
          className="w-8 h-8 object-contain"
          onError={(e) => {
            // Fallback to initials if logo fails to load
            e.currentTarget.style.display = 'none';
            const fallbackDiv = e.currentTarget.nextElementSibling as HTMLElement;
            if (fallbackDiv) fallbackDiv.style.display = 'flex';
          }}
        />
        <div className={`w-12 h-12 bg-gradient-to-br ${fallbackBgColor} rounded-xl hidden items-center justify-center`}>
          <span className="text-white font-bold text-sm">{fallbackInitials}</span>
        </div>
      </div>
    );
  }

  // Fallback to colored initials
  return (
    <div className={`w-12 h-12 bg-gradient-to-br ${fallbackBgColor} rounded-xl flex items-center justify-center`}>
      <span className="text-white font-bold text-sm">{fallbackInitials}</span>
    </div>
  );
}

export default function JobItem({ 
  company, 
  model, 
  amount, 
  date, 
  status, 
  icon, 
  initials, 
  bgColor = "from-gray-800 to-black",
  jobTitle,
  bookedBy,
  jobDate,
  dueDate,
  job
}: JobItemProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const { toast } = useToast();
  const queryClient = useQueryClient();

  useEffect(() => {
    // Get authenticated user ID from localStorage
    const userId = localStorage.getItem("currentUserId");
    setCurrentUserId(userId);
  }, []);

  // Update job mutation
  const updateJobMutation = useMutation({
    mutationFn: (data: { jobId: number; updates: Partial<Job> }) => {
      return apiRequest("PUT", `/api/jobs/${data.jobId}`, data.updates);
    },
    onSuccess: () => {
      // Invalidate all job-related queries to ensure data consistency
      queryClient.invalidateQueries({ queryKey: [`/api/jobs/${currentUserId}`] });
      queryClient.invalidateQueries({ queryKey: [`/api/dashboard/${currentUserId}`] });
      toast({
        title: "Job Updated",
        description: "Job details updated successfully"
      });
    },
    onError: (error: any) => {
      toast({
        title: "Error",
        description: `Failed to update job: ${error.message}`,
        variant: "destructive"
      });
    }
  });

  // Delete job mutation
  const deleteJobMutation = useMutation({
    mutationFn: (jobId: number) => {
      return apiRequest("DELETE", `/api/jobs/${jobId}`);
    },
    onSuccess: () => {
      // Invalidate all job-related queries to ensure data consistency
      queryClient.invalidateQueries({ queryKey: [`/api/jobs/${currentUserId}`] });
      queryClient.invalidateQueries({ queryKey: [`/api/dashboard/${currentUserId}`] });
      toast({
        title: "Job Deleted",
        description: "Job deleted successfully"
      });
    },
    onError: (error: any) => {
      toast({
        title: "Error",
        description: `Failed to delete job: ${error.message}`,
        variant: "destructive"
      });
    }
  });

  const handleUpdateJob = (jobId: number, updates: Partial<Job>) => {
    updateJobMutation.mutate({ jobId, updates });
  };

  const handleDeleteJob = () => {
    if (job?.id && window.confirm("Are you sure you want to delete this job?")) {
      deleteJobMutation.mutate(job.id);
    }
  };
  const getStatusStyles = (status: string) => {
    switch (status) {
      case 'Received':
        return 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300';
      case 'Upcoming':
        return 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-300';
      case 'Overdue':
        return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300';
      default:
        return 'bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-300';
    }
  };

  return (
    <div className="bg-white rounded-xl border border-gray-100 shadow-sm hover:shadow-md transition-all duration-200 overflow-hidden">
      {/* Main Card Content */}
      <div 
        className="p-4 cursor-pointer"
        onClick={() => setIsExpanded(!isExpanded)}
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <BrandIcon 
              brandName={company}
              fallbackInitials={initials || company.slice(0, 2).toUpperCase()}
              fallbackBgColor={bgColor}
            />
            <div>
              <div className="text-foreground font-semibold text-base">{company}</div>
              <div className="text-muted-foreground text-sm">{model}</div>
            </div>
          </div>
          <div className="flex items-center space-x-3">
            <div className="text-right">
              <div className="flex items-center justify-end mb-2">
                <span className={`text-xs px-3 py-1 rounded-full font-medium ${getStatusStyles(status)}`}>
                  {status}
                </span>
              </div>
              <div className="text-foreground font-bold text-base">{amount}</div>
              <div className="text-muted-foreground text-xs">{date}</div>
            </div>
            {/* Expand/Collapse Icon */}
            <div className="text-muted-foreground">
              {isExpanded ? (
                <ChevronUp className="w-5 h-5" />
              ) : (
                <ChevronDown className="w-5 h-5" />
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Expanded Details */}
      {isExpanded && (
        <div className="border-t border-gray-100 bg-gray-50/50 p-4 space-y-3">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <div className="text-xs text-muted-foreground mb-1">Job Title</div>
              <div className="text-sm font-medium text-foreground">{jobTitle || 'N/A'}</div>
            </div>
            <div>
              <div className="text-xs text-muted-foreground mb-1">Agency</div>
              <div className="text-sm font-medium text-foreground">{bookedBy || 'N/A'}</div>
            </div>
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <div>
              <div className="text-xs text-muted-foreground mb-1">Job Date</div>
              <div className="text-sm font-medium text-foreground">{jobDate || date}</div>
            </div>
            <div>
              <div className="text-xs text-muted-foreground mb-1">Due Date</div>
              <div className="text-sm font-medium text-foreground">{dueDate || 'N/A'}</div>
            </div>
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <div>
              <div className="text-xs text-muted-foreground mb-1">Client</div>
              <div className="text-sm font-medium text-foreground">{company}</div>
            </div>
            <div>
              <div className="text-xs text-muted-foreground mb-1">Status</div>
              <div className="text-sm font-medium text-foreground">{status}</div>
            </div>
          </div>
          
          {/* Action Buttons */}
          <div className="flex space-x-2 pt-2">
            <button className="flex-1 bg-blue-500 hover:bg-blue-600 text-white text-sm py-2 px-3 rounded-lg transition-colors">
              View Details
            </button>
            <button 
              onClick={() => setIsEditModalOpen(true)}
              disabled={!job}
              className="flex-1 bg-gray-200 hover:bg-gray-300 text-gray-700 text-sm py-2 px-3 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Edit Job
            </button>
            <button 
              onClick={handleDeleteJob}
              disabled={!job || deleteJobMutation.isPending}
              className="flex-1 bg-red-500 hover:bg-red-600 text-white text-sm py-2 px-3 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {deleteJobMutation.isPending ? 'Deleting...' : 'Delete'}
            </button>
          </div>
        </div>
      )}
      
      {/* Edit Job Modal */}
      <EditJobModal
        isOpen={isEditModalOpen}
        onClose={() => setIsEditModalOpen(false)}
        onUpdateJob={handleUpdateJob}
        job={job}
      />
    </div>
  );
}