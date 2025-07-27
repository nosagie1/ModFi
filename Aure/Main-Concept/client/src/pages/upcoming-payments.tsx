import { ArrowLeft, Calendar, DollarSign, AlertCircle } from "lucide-react";
import { useLocation } from "wouter";
import { useQuery } from "@tanstack/react-query";
import { useState, useEffect } from "react";
import type { Job } from "@shared/schema";

export default function UpcomingPayments() {
  const [, setLocation] = useLocation();
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);

  useEffect(() => {
    // Get authenticated user ID from localStorage
    const userId = localStorage.getItem("currentUserId");
    setCurrentUserId(userId);
  }, []);

  // Fetch real job data
  const { data: jobs = [] } = useQuery<Job[]>({
    queryKey: [`/api/jobs/${currentUserId}`],
    enabled: !!currentUserId,
    staleTime: 0, // Always fetch fresh data
  });

  // Filter for upcoming jobs (not yet received and due in the future)
  const upcomingJobs = jobs.filter(job => {
    const dueDate = new Date(job.dueDate);
    const today = new Date();
    return dueDate >= today && ['Pending', 'Invoiced', 'Partially Paid'].includes(job.status);
  });

  // Convert jobs to payment format
  const upcomingPayments = upcomingJobs.map(job => {
    const getAgencyColor = (agency: string) => {
      switch (agency) {
        case "Soul Artist Management":
          return "purple";
        case "Wilhelmina London":
          return "blue";
        case "Society Management":
          return "green";
        default:
          return "gray";
      }
    };

    const getAgencyInitial = (agency: string) => {
      switch (agency) {
        case "Soul Artist Management":
          return "S";
        case "Wilhelmina London":
          return "W";
        case "WHY NOT Management":
          return "WN";
        default:
          return agency.charAt(0);
      }
    };

    const formatDate = (dateStr: string) => {
      const date = new Date(dateStr);
      return date.toLocaleDateString('en-US', { month: '2-digit', day: '2-digit' });
    };

    return {
      id: job.id,
      name: job.client,
      amount: parseFloat(job.amount),
      date: formatDate(job.dueDate.toString()),
      type: job.jobTitle || "Modeling Job",
      status: job.status.toLowerCase(),
      icon: getAgencyInitial(job.bookedBy),
      color: getAgencyColor(job.bookedBy),
      category: job.bookedBy,
      job: job
    };
  });

  // Calculate total upcoming from real job data
  const totalUpcomingAmount = upcomingPayments.reduce((total, payment) => total + payment.amount, 0);

  const getStatusColor = (status: string) => {
    switch (status) {
      case "upcoming":
        return "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300";
      case "pending":
        return "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-300";
      case "invoiced":
        return "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-300";
      case "partially paid":
        return "bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300";
      default:
        return "bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-300";
    }
  };

  const getIconBackground = (color: string) => {
    switch (color) {
      case "purple":
        return "bg-gradient-to-br from-purple-500 to-purple-600";
      case "blue":
        return "bg-gradient-to-br from-blue-500 to-blue-600";
      case "green":
        return "bg-gradient-to-br from-green-500 to-green-600";
      default:
        return "bg-gradient-to-br from-gray-500 to-gray-600";
    }
  };

  return (
    <div className="w-full max-w-md mx-auto bg-background min-h-screen">
      {/* Header */}
      <div className="bg-white dark:bg-gray-900 border-b border-gray-100 dark:border-gray-800 px-4 py-4">
        <div className="flex items-center space-x-3">
          <button 
            onClick={() => setLocation("/")}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full transition-colors"
          >
            <ArrowLeft className="w-5 h-5 text-foreground" />
          </button>
          <div>
            <h1 className="text-lg font-semibold text-foreground">Upcoming Payments</h1>
            <p className="text-sm text-muted-foreground">Next 30 days</p>
          </div>
        </div>
      </div>

      {/* Summary Card */}
      <div className="p-4">
        <div className="bg-gradient-to-br from-blue-50 to-blue-100/80 dark:from-blue-900/20 dark:to-blue-800/30 rounded-xl p-4 border border-blue-100 dark:border-blue-800/30 mb-6">
          <div className="flex justify-between items-center mb-3">
            <div className="flex items-center space-x-2">
              <Calendar className="w-5 h-5 text-blue-600 dark:text-blue-400" />
              <span className="text-sm font-medium text-foreground">Total Expected</span>
            </div>
            <AlertCircle className="w-4 h-4 text-blue-500" />
          </div>
          <div className="text-2xl font-bold text-foreground mb-1">
            ${totalUpcomingAmount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </div>
          <div className="text-xs text-muted-foreground">
            {upcomingPayments.length} upcoming {upcomingPayments.length === 1 ? 'payment' : 'payments'}
          </div>
        </div>

        {/* Payments List */}
        <div className="space-y-3">
          {upcomingPayments.length === 0 ? (
            <div className="text-center py-8">
              <Calendar className="w-12 h-12 text-muted-foreground mx-auto mb-3" />
              <h3 className="text-foreground font-medium mb-2">No upcoming payments</h3>
              <p className="text-muted-foreground text-sm">All your jobs are either completed or overdue.</p>
            </div>
          ) : (
            upcomingPayments.map((payment) => (
              <div
                key={payment.id}
                className="bg-white dark:bg-gray-900 rounded-xl p-4 border border-gray-100 dark:border-gray-800 shadow-sm hover:shadow-md transition-shadow"
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <div className={`w-10 h-10 rounded-full flex items-center justify-center text-white text-xs font-bold ${getIconBackground(payment.color)}`}>
                      {payment.icon}
                    </div>
                    <div>
                      <h3 className="font-medium text-foreground">{payment.name}</h3>
                      <div className="flex items-center space-x-2">
                        <span className="text-xs text-muted-foreground">{payment.type}</span>
                        <span className="text-xs text-muted-foreground">•</span>
                        <span className="text-xs text-muted-foreground">{payment.category}</span>
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="font-semibold text-foreground">
                      ${payment.amount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </div>
                    <div className="flex items-center space-x-2">
                      <span className="text-xs text-muted-foreground">Due {payment.date}</span>
                      <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${getStatusColor(payment.status)}`}>
                        {payment.status}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}