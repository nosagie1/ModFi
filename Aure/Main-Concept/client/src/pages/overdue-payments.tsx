import { ArrowLeft, Calendar, DollarSign, AlertTriangle, Clock } from "lucide-react";
import { useLocation } from "wouter";
import { useQuery } from "@tanstack/react-query";
import { useState, useEffect } from "react";
import type { Job } from "@shared/schema";

export default function OverduePayments() {
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

  // Filter for overdue jobs (due date passed and not received)
  const overdueJobs = jobs.filter(job => {
    const dueDate = new Date(job.dueDate);
    const today = new Date();
    return dueDate < today && ['Pending', 'Invoiced', 'Partially Paid'].includes(job.status);
  });

  // Convert jobs to overdue payment format
  const overduePayments = overdueJobs.map(job => {
    const getAgencyColor = (agency: string) => {
      switch (agency) {
        case "Soul Artist Management":
          return "purple";
        case "Wilhelmina London":
          return "blue";
        case "WHY NOT Management":
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

    const calculateDaysOverdue = (dueDateStr: string) => {
      const dueDate = new Date(dueDateStr);
      const today = new Date();
      const diffTime = today.getTime() - dueDate.getTime();
      return Math.floor(diffTime / (1000 * 60 * 60 * 24));
    };

    const formatDate = (dateStr: string) => {
      const date = new Date(dateStr);
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    };

    const daysOverdue = calculateDaysOverdue(job.dueDate.toString());
    const status = daysOverdue > 7 ? "critical" : "overdue";

    return {
      id: job.id,
      name: job.client,
      amount: parseFloat(job.amount),
      daysOverdue,
      originalDate: formatDate(job.dueDate.toString()),
      type: job.jobTitle || "Modeling Job",
      status,
      icon: getAgencyInitial(job.bookedBy),
      color: status === "critical" ? "red" : "orange",
      category: job.bookedBy,
      description: `${job.jobTitle || 'Modeling job'} payment`,
      job: job
    };
  });

  // Calculate total overdue amount
  const totalOverdueAmount = overduePayments.reduce((total, payment) => total + payment.amount, 0);

  const getStatusIcon = (status: string) => {
    return status === "critical" ? AlertTriangle : Clock;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "critical":
        return "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300";
      case "overdue":
        return "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-300";
      default:
        return "bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-300";
    }
  };

  const getIconBackground = (color: string) => {
    switch (color) {
      case "red":
        return "bg-gradient-to-br from-red-500 to-red-600";
      case "orange":
        return "bg-gradient-to-br from-orange-500 to-orange-600";
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

  const criticalPayments = overduePayments.filter(p => p.status === "critical");
  const regularOverdue = overduePayments.filter(p => p.status === "overdue");

  return (
    <div className="w-full max-w-md mx-auto bg-background min-h-screen">
      {/* Header */}
      <div className="bg-red-600 text-white px-4 py-4">
        <div className="flex items-center space-x-3">
          <button 
            onClick={() => setLocation("/")}
            className="p-2 hover:bg-red-700 rounded-full transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <h1 className="text-lg font-semibold">Overdue Payments</h1>
            <p className="text-sm text-red-100">Payments past due date</p>
          </div>
        </div>
      </div>

      {/* Critical Alert Banner */}
      {criticalPayments.length > 0 && (
        <div className="bg-red-50 dark:bg-red-900/20 border-l-4 border-red-500 p-4 m-4 rounded-r-lg">
          <div className="flex items-center">
            <AlertTriangle className="w-5 h-5 text-red-500 mr-2" />
            <div>
              <h3 className="text-sm font-medium text-red-800 dark:text-red-200">
                Critical Alert
              </h3>
              <p className="text-xs text-red-700 dark:text-red-300">
                {criticalPayments.length} payment{criticalPayments.length > 1 ? 's' : ''} overdue by more than 7 days
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Summary Card */}
      <div className="p-4">
        <div className="bg-gradient-to-br from-red-50 to-red-100/80 dark:from-red-900/20 dark:to-red-800/30 rounded-xl p-4 border border-red-100 dark:border-red-800/30 mb-6">
          <div className="flex justify-between items-center mb-3">
            <div className="flex items-center space-x-2">
              <DollarSign className="w-5 h-5 text-red-600 dark:text-red-400" />
              <span className="text-sm font-medium text-foreground">Total Overdue</span>
            </div>
            <AlertTriangle className="w-4 h-4 text-red-500" />
          </div>
          <div className="text-2xl font-bold text-foreground mb-1">
            ${totalOverdueAmount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </div>
          <div className="text-xs text-muted-foreground">
            {overduePayments.length} overdue {overduePayments.length === 1 ? 'payment' : 'payments'}
          </div>
        </div>

        {/* Payments List */}
        <div className="space-y-3">
          {overduePayments.length === 0 ? (
            <div className="text-center py-8">
              <Clock className="w-12 h-12 text-muted-foreground mx-auto mb-3" />
              <h3 className="text-foreground font-medium mb-2">No overdue payments</h3>
              <p className="text-muted-foreground text-sm">All your payments are up to date!</p>
            </div>
          ) : (
            overduePayments
              .sort((a, b) => b.daysOverdue - a.daysOverdue) // Most overdue first
              .map((payment) => {
                const StatusIcon = getStatusIcon(payment.status);
                return (
                  <div
                    key={payment.id}
                    className="bg-white dark:bg-gray-900 rounded-xl p-4 border border-red-200 dark:border-red-800/30 shadow-sm"
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
                          <p className="text-xs text-muted-foreground mt-1">{payment.description}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="font-semibold text-foreground">
                          ${payment.amount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                        </div>
                        <div className="flex items-center space-x-2 mt-1">
                          <StatusIcon className={`w-3 h-3 ${payment.status === 'critical' ? 'text-red-500' : 'text-orange-500'}`} />
                          <span className="text-xs text-muted-foreground">
                            {payment.daysOverdue} day{payment.daysOverdue > 1 ? 's' : ''} overdue
                          </span>
                        </div>
                        <div className="flex items-center space-x-2 mt-1">
                          <span className="text-xs text-muted-foreground">Due {payment.originalDate}</span>
                          <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${getStatusColor(payment.status)}`}>
                            {payment.status}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })
          )}
        </div>
      </div>
    </div>
  );
}