import BottomNavigation from "@/components/bottom-navigation";
import { useLocation } from "wouter";
import { ArrowLeft, DollarSign, Clock, Bell, AlertTriangle, CheckCircle, Calendar } from "lucide-react";
import { useQuery } from "@tanstack/react-query";
import { useState, useEffect } from "react";
import type { Job } from "@shared/schema";

export default function Notifications() {
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

  // Generate notifications based on real job data
  const generateNotifications = () => {
    const notifications: any[] = [];
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    
    // Recent payments (Received status)
    const recentPayments = jobs.filter(job => job.status === 'Received')
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
      .slice(0, 3);

    recentPayments.forEach(job => {
      notifications.push({
        type: 'payment_received',
        client: job.client,
        agency: job.bookedBy,
        amount: parseFloat(job.amount),
        jobTitle: job.jobTitle,
        date: new Date(job.createdAt),
        icon: CheckCircle,
        color: 'green'
      });
    });

    // Overdue payments
    const overdueJobs = jobs.filter(job => {
      const dueDate = new Date(job.dueDate);
      return dueDate < today && ['Pending', 'Invoiced', 'Partially Paid'].includes(job.status);
    }).slice(0, 2);

    overdueJobs.forEach(job => {
      const daysOverdue = Math.floor((today.getTime() - new Date(job.dueDate).getTime()) / (1000 * 60 * 60 * 24));
      notifications.push({
        type: 'payment_overdue',
        client: job.client,
        agency: job.bookedBy,
        amount: parseFloat(job.amount),
        daysOverdue,
        date: new Date(job.dueDate),
        icon: AlertTriangle,
        color: 'red'
      });
    });

    // Upcoming due dates
    const upcomingJobs = jobs.filter(job => {
      const dueDate = new Date(job.dueDate);
      const nextWeek = new Date(today);
      nextWeek.setDate(nextWeek.getDate() + 7);
      return dueDate > today && dueDate <= nextWeek && ['Pending', 'Invoiced', 'Partially Paid'].includes(job.status);
    }).slice(0, 2);

    upcomingJobs.forEach(job => {
      const daysUntilDue = Math.ceil((new Date(job.dueDate).getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
      notifications.push({
        type: 'payment_due_soon',
        client: job.client,
        agency: job.bookedBy,
        amount: parseFloat(job.amount),
        daysUntilDue,
        date: new Date(job.dueDate),
        icon: Clock,
        color: 'orange'
      });
    });

    return notifications.sort((a, b) => b.date.getTime() - a.date.getTime());
  };

  const notifications = generateNotifications();
  
  // Group notifications by date
  const todayNotifications = notifications.filter(n => {
    const notifDate = new Date(n.date);
    return notifDate.toDateString() === new Date().toDateString();
  });

  const yesterdayNotifications = notifications.filter(n => {
    const notifDate = new Date(n.date);
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    return notifDate.toDateString() === yesterday.toDateString();
  });

  const olderNotifications = notifications.filter(n => {
    const notifDate = new Date(n.date);
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    return notifDate < yesterday;
  }).slice(0, 3);

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

  const getAgencyColor = (agency: string) => {
    switch (agency) {
      case "Soul Artist Management":
        return "from-purple-500 to-purple-600";
      case "Wilhelmina London":
        return "from-blue-500 to-blue-600";
      case "WHY NOT Management":
        return "from-green-500 to-green-600";
      default:
        return "from-gray-500 to-gray-600";
    }
  };

  const renderNotification = (notification: any) => {
    const Icon = notification.icon;
    
    return (
      <div key={`${notification.type}-${notification.client}-${notification.date.getTime()}`} className="bg-card border border-border rounded-2xl p-4 banking-shadow">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className={`w-12 h-12 rounded-full flex items-center justify-center text-white font-bold text-sm bg-gradient-to-br ${getAgencyColor(notification.agency)}`}>
              {getAgencyInitial(notification.agency)}
            </div>
            <div>
              <div className="text-foreground font-medium">{notification.client}</div>
              <div className="text-muted-foreground text-sm">
                {notification.type === 'payment_received' && `Payment received ✓`}
                {notification.type === 'payment_overdue' && `${notification.daysOverdue} days overdue ⚠️`}
                {notification.type === 'payment_due_soon' && `Due in ${notification.daysUntilDue} days ⏰`}
              </div>
              <div className="text-xs text-muted-foreground">{notification.agency}</div>
            </div>
          </div>
          <div className="text-right">
            <div className={`font-semibold text-lg ${
              notification.type === 'payment_received' ? 'text-green-600' : 
              notification.type === 'payment_overdue' ? 'text-red-600' : 
              'text-orange-600'
            }`}>
              ${notification.amount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
            <div className="flex items-center justify-end mt-1">
              <Icon className={`w-4 h-4 ${
                notification.color === 'green' ? 'text-green-500' :
                notification.color === 'red' ? 'text-red-500' :
                'text-orange-500'
              }`} />
            </div>
          </div>
        </div>
      </div>
    );
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
            <h1 className="text-xl font-semibold text-foreground">Notifications</h1>
            <p className="text-muted-foreground text-sm">Recent activity & updates</p>
          </div>
        </div>
      </div>

      {/* Today Section */}
      {todayNotifications.length > 0 && (
        <div className="px-6 mb-6">
          <h2 className="text-muted-foreground text-sm font-medium mb-4">Today</h2>
          <div className="space-y-3">
            {todayNotifications.map(renderNotification)}
          </div>
        </div>
      )}

      {/* Yesterday Section */}
      {yesterdayNotifications.length > 0 && (
        <div className="px-6 mb-6">
          <h2 className="text-muted-foreground text-sm font-medium mb-4">Yesterday</h2>
          <div className="space-y-3">
            {yesterdayNotifications.map(renderNotification)}
          </div>
        </div>
      )}

      {/* Recent Activity Section */}
      {olderNotifications.length > 0 && (
        <div className="px-6 mb-20">
          <h2 className="text-muted-foreground text-sm font-medium mb-4">Recent Activity</h2>
          <div className="space-y-3">
            {olderNotifications.map(renderNotification)}
          </div>
        </div>
      )}

      {/* Empty State */}
      {notifications.length === 0 && (
        <div className="px-6 mb-20 text-center py-8">
          <Bell className="w-12 h-12 text-muted-foreground mx-auto mb-3" />
          <h3 className="text-foreground font-medium mb-2">No notifications yet</h3>
          <p className="text-muted-foreground text-sm">
            We'll notify you about payments, due dates, and job updates
          </p>
        </div>
      )}

      <BottomNavigation />
    </div>
  );
}