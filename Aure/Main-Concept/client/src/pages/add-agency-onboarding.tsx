import { useState } from "react";
import { useLocation } from "wouter";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ArrowRight, ArrowLeft, CheckCircle } from "lucide-react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import type { InsertAgency } from "@shared/schema";

interface AgencyFormData {
  name: string;
  commissionRate: number;
  currency: string;
}

export default function AddAgencyOnboardingPage() {
  const [currentStep, setCurrentStep] = useState(0);
  const [formData, setFormData] = useState<AgencyFormData>({
    name: "",
    commissionRate: 20,
    currency: "USD"
  });
  const [, setLocation] = useLocation();
  const queryClient = useQueryClient();

  const steps = [
    {
      title: "What's your modeling agency?",
      subtitle: "Enter the name of the agency you work with",
      field: "name",
      type: "text",
      placeholder: "e.g. Soul Artist Management"
    },
    {
      title: "What's your commission rate?",
      subtitle: "Enter the percentage your agency takes",
      field: "commissionRate",
      type: "number",
      placeholder: "20",
      suffix: "%"
    },
    {
      title: "What currency do you use?",
      subtitle: "Select your preferred currency",
      field: "currency",
      type: "select",
      options: [
        { value: "USD", label: "USD - US Dollar" },
        { value: "EUR", label: "EUR - Euro" },
        { value: "GBP", label: "GBP - British Pound" },
        { value: "CAD", label: "CAD - Canadian Dollar" },
        { value: "AUD", label: "AUD - Australian Dollar" }
      ]
    }
  ];

  // Mutation for creating new agencies
  const createAgencyMutation = useMutation({
    mutationFn: async (agencyData: InsertAgency) => {
      const response = await fetch('/api/agencies', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(agencyData)
      });
      
      if (!response.ok) {
        throw new Error('Failed to create agency');
      }
      
      return response.json();
    },
    onSuccess: () => {
      // Invalidate and refetch agencies and dashboard data
      const currentUserId = localStorage.getItem("currentUserId");
      queryClient.invalidateQueries({ queryKey: [`/api/agencies/${currentUserId}`] });
      queryClient.invalidateQueries({ queryKey: [`/api/dashboard/${currentUserId}`] });
      
      // Navigate to job creation page
      setLocation("/add-first-job");
    },
  });

  const handleNext = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      // Submit form
      handleSubmit();
    }
  };

  const handleBack = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    } else {
      setLocation("/");
    }
  };

  const handleSubmit = () => {
    const currentUserId = localStorage.getItem("currentUserId");
    if (!currentUserId) return;

    const agencyData: InsertAgency = {
      userId: parseInt(currentUserId),
      name: formData.name,
      commissionRate: (formData.commissionRate / 100).toString(), // Convert percentage to decimal string
      currency: formData.currency
    };

    createAgencyMutation.mutate(agencyData);
  };

  const updateFormData = (field: string, value: string | number) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const isStepValid = () => {
    const step = steps[currentStep];
    const value = formData[step.field as keyof AgencyFormData];
    
    if (step.field === "name") {
      return typeof value === "string" && value.trim().length > 0;
    }
    if (step.field === "commissionRate") {
      return typeof value === "number" && value > 0 && value <= 100;
    }
    if (step.field === "currency") {
      return typeof value === "string" && value.length > 0;
    }
    return false;
  };

  const currentStepData = steps[currentStep];

  return (
    <div className="min-h-screen bg-white flex flex-col">
      {/* Status Bar */}
      <div className="bg-white h-11 flex items-center justify-between px-6 text-sm font-medium">
        <div className="flex items-center gap-4">
          <button 
            onClick={handleBack}
            className="flex items-center gap-2 text-gray-600 hover:text-gray-900"
          >
            <ArrowLeft className="h-4 w-4" />
          </button>
          <div className="text-black">9:41 AM</div>
        </div>
        <div className="flex items-center space-x-1">
          <div className="flex space-x-1">
            <div className="w-1 h-3 bg-black rounded-full"></div>
            <div className="w-1 h-3 bg-black rounded-full"></div>
            <div className="w-1 h-3 bg-black rounded-full"></div>
            <div className="w-1 h-3 bg-gray-300 rounded-full"></div>
          </div>
          <span className="ml-2 text-black">100%</span>
          <div className="ml-2 w-6 h-3 bg-green-500 rounded-sm"></div>
        </div>
      </div>

      {/* Progress Bar */}
      <div className="px-6 pt-4">
        <div className="w-full bg-gray-200 rounded-full h-1">
          <div 
            className="bg-black h-1 rounded-full transition-all duration-300"
            style={{ width: `${((currentStep + 1) / steps.length) * 100}%` }}
          ></div>
        </div>
        <div className="text-right text-xs text-gray-500 mt-1">
          {currentStep + 1} of {steps.length}
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 flex flex-col justify-between px-6 py-8">
        <div className="space-y-8">
          {/* Title and Subtitle */}
          <div className="space-y-3">
            <h1 className="text-2xl font-semibold text-black leading-tight">
              {currentStepData.title}
            </h1>
            <p className="text-gray-600 text-base leading-relaxed">
              {currentStepData.subtitle}
            </p>
          </div>

          {/* Input Field */}
          <div className="space-y-4">
            {currentStepData.type === "text" && (
              <div className="relative">
                <Input
                  type="text"
                  placeholder={currentStepData.placeholder}
                  value={formData[currentStepData.field as keyof AgencyFormData] as string}
                  onChange={(e) => updateFormData(currentStepData.field, e.target.value)}
                  className="w-full h-14 text-lg border-2 border-gray-200 rounded-xl focus:border-black focus:ring-0 px-4"
                  autoFocus
                />
              </div>
            )}

            {currentStepData.type === "number" && (
              <div className="relative">
                <Input
                  type="number"
                  placeholder={currentStepData.placeholder}
                  value={formData[currentStepData.field as keyof AgencyFormData] as number}
                  onChange={(e) => updateFormData(currentStepData.field, parseInt(e.target.value) || 0)}
                  className="w-full h-14 text-lg border-2 border-gray-200 rounded-xl focus:border-black focus:ring-0 px-4 pr-12"
                  min="0"
                  max="100"
                  autoFocus
                />
                {currentStepData.suffix && (
                  <span className="absolute right-4 top-1/2 transform -translate-y-1/2 text-lg text-gray-500">
                    {currentStepData.suffix}
                  </span>
                )}
              </div>
            )}

            {currentStepData.type === "select" && (
              <div className="space-y-3">
                {currentStepData.options?.map((option) => (
                  <button
                    key={option.value}
                    onClick={() => updateFormData(currentStepData.field, option.value)}
                    className={`w-full h-14 text-left px-4 border-2 rounded-xl transition-all ${
                      formData[currentStepData.field as keyof AgencyFormData] === option.value
                        ? 'border-black bg-black text-white'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-lg">{option.label}</span>
                      {formData[currentStepData.field as keyof AgencyFormData] === option.value && (
                        <CheckCircle className="h-5 w-5" />
                      )}
                    </div>
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Action Button */}
        <div className="space-y-4">
          <Button
            onClick={handleNext}
            disabled={!isStepValid() || createAgencyMutation.isPending}
            className="w-full h-14 bg-black hover:bg-gray-800 disabled:bg-gray-300 disabled:text-gray-500 text-white rounded-xl text-lg font-semibold transition-all"
          >
            <div className="flex items-center justify-center space-x-2">
              <span>
                {createAgencyMutation.isPending 
                  ? "Creating..." 
                  : currentStep === steps.length - 1 
                    ? "Complete Setup" 
                    : "Continue"
                }
              </span>
              {!createAgencyMutation.isPending && <ArrowRight className="ml-2 h-5 w-5" />}
            </div>
          </Button>
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