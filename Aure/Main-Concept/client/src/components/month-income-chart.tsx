import { useLocation } from "wouter";

interface MonthIncomeChartProps {
  currentIncome: number;
  percentageChange: number;
  upcomingIncome: number;
  overdueIncome: number;
}

export default function MonthIncomeChart({ 
  currentIncome, 
  percentageChange, 
  upcomingIncome, 
  overdueIncome 
}: MonthIncomeChartProps) {
  const [, setLocation] = useLocation();
  return (
    <div className="px-2 mb-4">
      <div className="bg-gradient-to-br from-card to-card/95 rounded-xl p-5 shadow-sm border border-border ml-[-10px] mr-[-10px] hover:shadow-md transition-shadow duration-300">
        {/* Header with Goal Progress */}
        <div className="mb-6">
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-base font-semibold text-foreground">This month</h3>
            <button className="text-blue-600 text-xs font-medium hover:text-blue-700 transition-colors px-2 py-1 rounded-md hover:bg-blue-50 dark:hover:bg-blue-900/20">
              View all
            </button>
          </div>
          
          {/* Goal Progress Integrated */}
          <div className="space-y-3">
            {/* Current and Target Amounts */}
            <div className="flex items-center justify-between">
              <div className="text-2xl font-bold text-foreground">
                ${currentIncome.toLocaleString()}
              </div>
              <div className="text-right">
                <div className="text-sm text-muted-foreground">Goal</div>
                <div className="text-lg font-semibold text-foreground">
                  ${(currentIncome * 1.5).toLocaleString()}
                </div>
              </div>
            </div>
            
            {/* Progress Bar */}
            <div className="relative">
              <div className="w-full bg-muted rounded-full h-2">
                <div 
                  className="bg-gradient-to-r from-blue-500 to-blue-600 h-2 rounded-full transition-all duration-1000 ease-out"
                  style={{ width: `${Math.min((currentIncome / (currentIncome * 1.5)) * 100, 100)}%` }}
                ></div>
              </div>
            </div>
            
            {/* Remaining Amount */}
            <div className="text-sm text-muted-foreground">
              ${((currentIncome * 1.5) - currentIncome).toLocaleString()} remaining to reach goal
            </div>
          </div>
        </div>
        
        {/* Modern stats cards */}
        <div className="grid grid-cols-2 gap-3">
          <button 
            onClick={() => setLocation("/upcoming-payments")}
            className="group relative bg-white rounded-2xl p-3 border border-gray-100 hover:border-blue-300 hover:shadow-lg transition-all duration-300 text-left overflow-hidden"
          >
            {/* Background gradient on hover */}
            <div className="absolute inset-0 bg-gradient-to-br from-blue-50 to-blue-100 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
            
            <div className="relative">
              {/* Header with icon */}
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center space-x-1.5">
                  <div className="w-6 h-6 bg-blue-100 rounded-full flex items-center justify-center group-hover:bg-blue-200 transition-colors">
                    <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                  </div>
                  <div className="text-xs text-gray-600 font-medium">Upcoming</div>
                </div>
                <svg className="w-3 h-3 text-gray-400 group-hover:text-blue-500 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </div>
              
              {/* Amount */}
              <div className="text-lg font-bold text-gray-900 mb-1">
                ${upcomingIncome.toLocaleString()}
              </div>
              
              {/* Description */}
              <div className="text-xs text-gray-500">
                Next 30 days
              </div>
            </div>
          </button>
          
          <button 
            onClick={() => setLocation("/overdue-payments")}
            className="group relative bg-white rounded-2xl p-3 border border-gray-100 hover:border-red-300 hover:shadow-lg transition-all duration-300 text-left overflow-hidden"
          >
            {/* Background gradient on hover */}
            <div className="absolute inset-0 bg-gradient-to-br from-red-50 to-red-100 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
            
            <div className="relative">
              {/* Header with icon */}
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center space-x-1.5">
                  <div className="w-6 h-6 bg-red-100 rounded-full flex items-center justify-center group-hover:bg-red-200 transition-colors">
                    <div className="w-2 h-2 bg-red-500 rounded-full"></div>
                  </div>
                  <div className="text-xs text-gray-600 font-medium">Overdue</div>
                </div>
                <svg className="w-3 h-3 text-gray-400 group-hover:text-red-500 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
                </svg>
              </div>
              
              {/* Amount */}
              <div className="text-lg font-bold text-gray-900 mb-1">
                ${overdueIncome.toLocaleString()}
              </div>
              
              {/* Description */}
              <div className="text-xs text-gray-500">
                Needs attention
              </div>
            </div>
          </button>
        </div>
      </div>
    </div>
  );
}