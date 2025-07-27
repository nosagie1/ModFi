import { useState, useEffect } from "react";
import { useLocation } from "wouter";
import DiemPayLogo from "../components/diempay-logo";

export default function SplashPage() {
  const [, setLocation] = useLocation();
  const [showContent, setShowContent] = useState(false);

  useEffect(() => {
    // Show content with animation after component mounts
    const timer1 = setTimeout(() => {
      setShowContent(true);
    }, 300);

    // Auto-redirect to onboarding after 2.5 seconds
    const timer2 = setTimeout(() => {
      // Mark as visited and redirect
      localStorage.setItem("hasVisited", "true");
      setLocation("/onboarding");
    }, 2500);

    return () => {
      clearTimeout(timer1);
      clearTimeout(timer2);
    };
  }, [setLocation]);

  return (
    <div className="min-h-screen bg-white flex flex-col">
      {/* Status Bar */}
      <div className="flex items-center justify-between px-6 pt-4 pb-2">
        <div className="text-sm font-semibold text-black">09:41</div>
        <div className="flex items-center space-x-1">
          <div className="flex space-x-1">
            <div className="w-1 h-3 bg-black rounded-full"></div>
            <div className="w-1 h-3 bg-black rounded-full"></div>
            <div className="w-1 h-3 bg-black rounded-full"></div>
            <div className="w-1 h-3 bg-gray-300 rounded-full"></div>
          </div>
          <div className="ml-2 flex space-x-1">
            <div className="w-4 h-2 border border-black rounded-sm">
              <div className="w-full h-full bg-black rounded-sm"></div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col items-center justify-center px-8">
        <div className={`text-center transition-all duration-700 ease-out transform ${
          showContent ? 'translate-y-0 opacity-100' : 'translate-y-4 opacity-0'
        }`}>
          
          {/* App Logo */}
          <div className="mb-6">
            <DiemPayLogo size={120} />
          </div>
          
          {/* App Name */}
          <h1 className="text-5xl font-bold text-black mb-2 tracking-tight font-serif">
            DiemPay
          </h1>
          
        </div>
      </div>

      {/* Bottom Section */}
      <div className="pb-8">
        {/* Branding */}
        <div className="flex items-center justify-center space-x-3 mb-4">
          <div className="flex items-center space-x-2">
            <DiemPayLogo size={24} />
            <span className="text-sm font-medium text-black">DiemPay</span>
          </div>
          <span className="text-sm text-gray-500">curated by</span>
          <div className="text-sm font-bold text-black">Replit</div>
        </div>

        {/* Home indicator */}
        <div className="flex justify-center">
          <div className="w-32 h-1 bg-black rounded-full"></div>
        </div>
      </div>
    </div>
  );
}