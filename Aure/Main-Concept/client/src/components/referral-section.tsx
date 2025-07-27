import { Brain, TrendingUp, ChevronLeft, ChevronRight, Target, Calendar, DollarSign, Briefcase } from "lucide-react";
import { useState } from "react";

const aiInsights = [
  {
    id: 1,
    icon: Brain,
    title: "Peak Performance Analysis",
    gradient: "from-purple-50 to-blue-50 dark:from-purple-900/20 dark:to-blue-900/20",
    borderColor: "border-purple-100 dark:border-purple-800/30",
    iconGradient: "from-purple-500 to-blue-500",
    accentColor: "text-purple-600 dark:text-purple-400",
    description: "Your ELITE bookings generate 32% higher rates than industry average. This exceptional performance places you in the top 5% of models.",
    recommendations: [
      "Focus on fashion week campaigns",
      "Target luxury brand collaborations", 
      "Negotiate premium rates for editorial work"
    ],
    trend: "+18% this quarter",
    trendColor: "text-emerald-600"
  },
  {
    id: 2,
    icon: Target,
    title: "Market Opportunity Insights",
    gradient: "from-emerald-50 to-teal-50 dark:from-emerald-900/20 dark:to-teal-900/20",
    borderColor: "border-emerald-100 dark:border-emerald-800/30",
    iconGradient: "from-emerald-500 to-teal-500",
    accentColor: "text-emerald-600 dark:text-emerald-400",
    description: "Wilhelmina London shows 45% increase in demand for commercial work. Your profile matches 87% of their current casting requirements.",
    recommendations: [
      "Submit for commercial campaigns",
      "Update portfolio with lifestyle shots",
      "Connect with commercial casting directors"
    ],
    trend: "+45% demand growth",
    trendColor: "text-blue-600"
  },
  {
    id: 3,
    icon: Calendar,
    title: "Seasonal Strategy",
    gradient: "from-orange-50 to-amber-50 dark:from-orange-900/20 dark:to-amber-900/20",
    borderColor: "border-orange-100 dark:border-orange-800/30",
    iconGradient: "from-orange-500 to-amber-500",
    accentColor: "text-orange-600 dark:text-orange-400",
    description: "Fashion Week season approaching in 6 weeks. Historical data shows 65% booking rate increase during this period for your category.",
    recommendations: [
      "Prepare casting materials early",
      "Book grooming appointments",
      "Review contract terms for runway shows"
    ],
    trend: "6 weeks remaining",
    trendColor: "text-amber-600"
  },
  {
    id: 4,
    icon: DollarSign,
    title: "Rate Optimization",
    gradient: "from-pink-50 to-rose-50 dark:from-pink-900/20 dark:to-rose-900/20",
    borderColor: "border-pink-100 dark:border-pink-800/30",
    iconGradient: "from-pink-500 to-rose-500",
    accentColor: "text-pink-600 dark:text-pink-400",
    description: "Your day rates are 15% below market average for editorial work. Society Management models with similar experience earn 23% more.",
    recommendations: [
      "Research current market rates",
      "Negotiate rate increases with agencies",
      "Document portfolio achievements"
    ],
    trend: "+23% potential increase",
    trendColor: "text-green-600"
  }
];

export default function AIInsightsCard() {
  const [currentIndex, setCurrentIndex] = useState(0);

  const nextInsight = () => {
    setCurrentIndex((prev) => (prev + 1) % aiInsights.length);
  };

  const prevInsight = () => {
    setCurrentIndex((prev) => (prev - 1 + aiInsights.length) % aiInsights.length);
  };

  const currentInsight = aiInsights[currentIndex];
  const IconComponent = currentInsight.icon;

  return (
    <div className="px-6 mb-3">
      <div className="bg-gradient-to-b from-card to-card/95 border border-border rounded-2xl p-4 shadow-[0_4px_16px_rgba(0,0,0,0.08)] hover:shadow-[0_6px_20px_rgba(0,0,0,0.12)] transition-all duration-500 backdrop-blur-sm ml-[-15px] mr-[-15px]">
        
        <div className="space-y-2">
          {/* Main insight with smooth transitions */}
          <div className={`bg-gradient-to-br ${currentInsight.gradient} rounded-xl p-4 border ${currentInsight.borderColor} hover:shadow-md transition-all duration-500 hover:scale-[1.005] transform`}>
            <div className="flex items-center space-x-2 mb-3">
              <div className={`w-3 h-3 bg-gradient-to-r ${currentInsight.iconGradient} rounded-full shadow-sm`}></div>
              <span className="text-sm font-semibold text-foreground">{currentInsight.title}</span>
            </div>
            <p className="text-sm text-muted-foreground leading-relaxed mb-3">
              {currentInsight.description}
            </p>
            <div className="space-y-2">
              <div className="bg-white/50 dark:bg-black/20 rounded-lg p-2">
                <div className={`text-xs font-medium ${currentInsight.accentColor} mb-1`}>
                  Recommended Actions
                </div>
                <div className="text-xs text-muted-foreground space-y-0.5">
                  {currentInsight.recommendations.map((rec, index) => (
                    <div key={index}>• {rec}</div>
                  ))}
                </div>
              </div>
              <div className="flex items-center justify-between text-xs">
                <span className="text-muted-foreground">Performance Trend</span>
                <div className={`flex items-center space-x-1 ${currentInsight.trendColor}`}>
                  <svg className="w-2.5 h-2.5" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M5.293 7.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 5.414V17a1 1 0 11-2 0V5.414L6.707 7.707a1 1 0 01-1.414 0z" clipRule="evenodd" />
                  </svg>
                  <span className="font-medium">{currentInsight.trend}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        {/* Navigation controls moved to bottom */}
        <div className="flex items-center justify-center mt-3">
          <div className="flex items-center space-x-1.5">
            <button
              onClick={prevInsight}
              className="w-6 h-6 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
            >
              <ChevronLeft className="w-3 h-3 text-gray-600 dark:text-gray-400" />
            </button>
            <div className="flex space-x-0.5">
              {aiInsights.map((_, index) => (
                <div
                  key={index}
                  className={`w-1.5 h-1.5 rounded-full transition-all duration-300 ${
                    index === currentIndex ? 'bg-purple-500' : 'bg-gray-300 dark:bg-gray-600'
                  }`}
                />
              ))}
            </div>
            <button
              onClick={nextInsight}
              className="w-6 h-6 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
            >
              <ChevronRight className="w-3 h-3 text-gray-600 dark:text-gray-400" />
            </button>
          </div>
        </div>
        
        
      </div>
    </div>
  );
}
