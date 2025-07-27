import { useState } from "react";
import { useLocation } from "wouter";
import { Button } from "@/components/ui/button";
import { ArrowRight, ArrowLeft } from "lucide-react";

export default function GetStartedPage() {
  const [, setLocation] = useLocation();

  const handleOpenAccount = () => {
    // Navigate to 3-step agency onboarding flow
    setLocation("/add-agency-onboarding");
  };

  const handleTransferAccount = () => {
    // Handle transfer account functionality
    setLocation("/");
  };

  const handleSkip = () => {
    // Skip onboarding and go to dashboard
    setLocation("/");
  };

  return (
    <div className="min-h-screen bg-white flex flex-col">
      {/* Status Bar with Back Button */}
      <div className="bg-white h-11 flex items-center justify-between px-6 text-sm font-medium">
        <div className="flex items-center gap-4">
          <button 
            onClick={() => setLocation("/onboarding")}
            className="p-1 hover:bg-gray-100 rounded-full transition-colors"
          >
            <ArrowLeft className="h-5 w-5 text-gray-600" />
          </button>
          <span>9:41</span>
        </div>
        <div className="flex items-center gap-1">
          <div className="flex gap-1">
            <div className="w-1 h-1 bg-black rounded-full"></div>
            <div className="w-1 h-1 bg-black rounded-full"></div>
            <div className="w-1 h-1 bg-black rounded-full"></div>
            <div className="w-1 h-1 bg-gray-300 rounded-full"></div>
          </div>
          <svg className="w-4 h-4 ml-1" viewBox="0 0 24 24" fill="none">
            <path d="M2 17h20v2H2zm1.15-4.05L4 11.47l.85 1.48L7.3 12C10.3 12 13 9.3 13 6.5S10.3 1 7.3 1 1.6 3.7 1.6 6.5c0 .85.2 1.64.55 2.35L3 10.33zm.25 2.6L2.65 14l.75 1.3L5.3 14.5c1.85 0 3.35-1.5 3.35-3.35S7.15 7.8 5.3 7.8 1.95 9.3 1.95 11.15c0 .55.125 1.06.375 1.5L3 13.4z" fill="currentColor"/>
          </svg>
          <div className="w-6 h-3 border border-black rounded-sm">
            <div className="w-4 h-1.5 bg-black rounded-xs m-0.5"></div>
          </div>
        </div>
      </div>
      <div className="flex-1 flex flex-col p-6">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-2xl font-medium text-gray-900">Let's get started</h1>
        </div>

        {/* Options */}
        <div className="space-y-4 flex-1">
          {/* Add Agency Option */}
          <Button
            variant="outline"
            onClick={handleOpenAccount}
            className="w-full h-auto p-6 border-gray-200 bg-white hover:bg-gray-50 text-left flex items-center justify-between rounded-2xl"
          >
            <div className="flex-1">
              <h3 className="text-lg font-medium text-gray-900 mb-1">Add a Modeling Agency</h3>
              <p className="text-sm text-gray-600">Connect with agencies you work with to track bookings, payments, and commissions automatically.</p>
            </div>
            <div className="ml-4 flex-shrink-0">
              {/* Dollar coin icon */}
              <div className="w-16 h-16 bg-gradient-to-br from-yellow-400 to-yellow-500 rounded-full flex items-center justify-center">
                <span className="text-2xl font-bold text-white">$</span>
              </div>
            </div>
          </Button>

          {/* Transfer Account Option */}
          <Button
            variant="outline"
            onClick={handleTransferAccount}
            className="w-full h-auto p-6 border-gray-200 bg-white hover:bg-gray-50 text-left flex items-center justify-between rounded-2xl"
          >
            <div className="flex-1">
              <h3 className="text-lg font-medium text-gray-900 mb-1">Import Your Modeling History</h3>
              <p className="text-sm text-gray-600">Upload past statements and contracts to see your complete earnings history.</p>
            </div>
            <div className="ml-4 flex-shrink-0">
              {/* Trophy/award icon */}
              <div className="w-16 h-16 bg-gradient-to-br from-gray-300 to-gray-400 rounded-full flex items-center justify-center relative">
                <div className="w-8 h-8 bg-white rounded flex items-center justify-center">
                  <span className="text-lg font-bold text-yellow-500">W</span>
                </div>
                <div className="absolute -top-1 -right-1 w-6 h-6 bg-gray-500 rounded-full flex items-center justify-center">
                  <div className="w-3 h-3 bg-white rounded-full"></div>
                </div>
              </div>
            </div>
          </Button>

          {/* Skip Option */}
          <div className="pt-8">
            <Button
              variant="ghost"
              onClick={handleSkip}
              className="text-gray-700 hover:text-gray-900 p-0 h-auto font-medium"
            >
              Skip for now <ArrowRight className="ml-2 h-4 w-4" />
            </Button>
          </div>
        </div>
      </div>
      {/* Bottom Branding */}
      <div className="flex items-center justify-center p-4 space-x-2">
        <div className="flex items-center space-x-1">
          <div className="w-5 h-5 bg-black rounded text-white flex items-center justify-center text-xs font-bold">W</div>
          <span className="text-sm font-medium">Wealthsimple</span>
        </div>
        <span className="text-xs text-gray-400">curated by</span>
        <span className="text-sm font-medium">Mobbin</span>
      </div>
      {/* Home Indicator */}
      <div className="h-8 flex items-center justify-center">
        <div className="w-32 h-1 bg-black rounded-full"></div>
      </div>
    </div>
  );
}