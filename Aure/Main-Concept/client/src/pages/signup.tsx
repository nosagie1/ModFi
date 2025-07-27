import { useState } from "react";
import { useLocation } from "wouter";
import { useMutation } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useToast } from "@/hooks/use-toast";
import { Eye, EyeOff, ArrowLeft, Copy } from "lucide-react";
import { z } from "zod";

const emailSchema = z.object({
  email: z.string().email("Please enter a valid email address"),
});

const passwordSchema = z.object({
  password: z.string().min(8, "Minimum 8 characters"),
});

const phoneSchema = z.object({
  phone: z.string().min(10, "Please enter a valid phone number"),
});

type Step = "email" | "password" | "phone" | "verification" | "permissions";

interface SignupData {
  email: string;
  password: string;
  phone: string;
  verificationCode: string;
  faceId: boolean;
  notifications: boolean;
}

export default function SignupPage() {
  const [, setLocation] = useLocation();
  const [currentStep, setCurrentStep] = useState<Step>("email");
  const [signupData, setSignupData] = useState<SignupData>({
    email: "",
    password: "",
    phone: "",
    verificationCode: "",
    faceId: true,
    notifications: false,
  });
  const [showPassword, setShowPassword] = useState(false);
  const [errors, setErrors] = useState<string>("");
  const { toast } = useToast();

  const signupMutation = useMutation({
    mutationFn: async (userData: { name: string; username: string; email: string; password: string }) => {
      const response = await fetch("/api/auth/signup", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(userData),
      });
      
      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Signup failed');
      }
      
      return response.json();
    },
    onSuccess: (data) => {
      localStorage.setItem("userAuthenticated", "true");
      localStorage.setItem("currentUserId", data.user.id.toString());
      window.dispatchEvent(new Event('authStateChange'));
      
      toast({
        title: "Account created successfully!",
        description: "Welcome to Model Finance Manager",
      });
      
      setLocation("/get-started");
    },
    onError: (error: any) => {
      toast({
        title: "Signup failed",
        description: error.message || "An error occurred during signup",
        variant: "destructive",
      });
    }
  });

  const handleInputChange = (field: keyof SignupData, value: string | boolean) => {
    setSignupData(prev => ({ ...prev, [field]: value }));
    setErrors("");
  };

  const validateCurrentStep = (): boolean => {
    try {
      switch (currentStep) {
        case "email":
          emailSchema.parse({ email: signupData.email });
          break;
        case "password":
          passwordSchema.parse({ password: signupData.password });
          break;
        case "phone":
          phoneSchema.parse({ phone: signupData.phone });
          break;
        case "verification":
          if (signupData.verificationCode.length !== 6) {
            throw new Error("Please enter the 6-digit code");
          }
          break;
      }
      setErrors("");
      return true;
    } catch (error) {
      if (error instanceof z.ZodError) {
        setErrors(error.errors[0].message);
      } else if (error instanceof Error) {
        setErrors(error.message);
      }
      return false;
    }
  };

  const handleNext = () => {
    if (!validateCurrentStep()) return;

    switch (currentStep) {
      case "email":
        setCurrentStep("password");
        break;
      case "password":
        setCurrentStep("phone");
        break;
      case "phone":
        // Simulate sending verification code
        toast({
          title: "Verification code sent",
          description: `We sent a code to ${signupData.phone}`,
        });
        setCurrentStep("verification");
        break;
      case "verification":
        setCurrentStep("permissions");
        break;
      case "permissions":
        // Complete signup
        const userData = {
          name: signupData.email.split('@')[0], // Use email prefix as name
          username: signupData.email.split('@')[0],
          email: signupData.email,
          password: signupData.password,
        };
        signupMutation.mutate(userData);
        break;
    }
  };

  const handleBack = () => {
    switch (currentStep) {
      case "email":
        setLocation("/");
        break;
      case "password":
        setCurrentStep("email");
        break;
      case "phone":
        setCurrentStep("password");
        break;
      case "verification":
        setCurrentStep("phone");
        break;
      case "permissions":
        setCurrentStep("verification");
        break;
    }
  };

  const renderStepContent = () => {
    switch (currentStep) {
      case "email":
        return (
          <div className="space-y-6">
            <Input
              type="email"
              placeholder="Email"
              value={signupData.email}
              onChange={(e) => handleInputChange("email", e.target.value)}
              className="h-14 text-base border-gray-300 rounded-xl bg-gray-50"
            />
            <div className="mt-auto pt-32">
              <div className="text-xs text-gray-500 mb-4 space-y-1">
                <p>By signing up, you agree to Wealthsimple's <span className="underline">Terms of Use</span> and</p>
                <p><span className="underline">Privacy Policy</span>. By providing your email, you consent to receive</p>
                <p>communications from Wealthsimple. You can opt-out anytime.</p>
              </div>
              <Button 
                onClick={handleNext}
                disabled={!signupData.email || signupMutation.isPending}
                className={`w-full h-14 rounded-xl font-medium ${
                  signupData.email && !signupMutation.isPending
                    ? "bg-black text-white hover:bg-gray-800"
                    : "bg-gray-300 text-gray-500"
                }`}
              >
                Next
              </Button>
            </div>
          </div>
        );

      case "password":
        return (
          <div className="space-y-6">
            <div className="relative">
              <Input
                type={showPassword ? "text" : "password"}
                placeholder="Password"
                value={signupData.password}
                onChange={(e) => handleInputChange("password", e.target.value)}
                className="h-14 text-base border-gray-300 rounded-xl bg-gray-50 pr-12"
              />
              <Button
                type="button"
                variant="ghost"
                size="sm"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 h-auto p-1"
              >
                {showPassword ? (
                  <EyeOff className="h-5 w-5 text-gray-400" />
                ) : (
                  <Eye className="h-5 w-5 text-gray-400" />
                )}
              </Button>
            </div>
            <p className="text-sm text-gray-500">Minimum 8 characters.</p>
            <div className="mt-auto pt-32">
              <Button 
                onClick={handleNext}
                disabled={signupData.password.length < 8 || signupMutation.isPending}
                className={`w-full h-14 rounded-xl font-medium ${
                  signupData.password.length >= 8 && !signupMutation.isPending
                    ? "bg-black text-white hover:bg-gray-800"
                    : "bg-gray-300 text-gray-500"
                }`}
              >
                Next
              </Button>
            </div>
          </div>
        );

      case "phone":
        return (
          <div className="space-y-6">
            <Input
              type="tel"
              placeholder="Phone number"
              value={signupData.phone}
              onChange={(e) => handleInputChange("phone", e.target.value)}
              className="h-14 text-base border-gray-300 rounded-xl bg-gray-50"
            />
            <div className="text-sm text-gray-500 space-y-2">
              <p>Your phone number will help us keep your account safe.</p>
              <p>There can only be one Wealthsimple account per phone number.</p>
            </div>
            <div className="mt-auto pt-24">
              <Button 
                onClick={handleNext}
                disabled={!signupData.phone || signupMutation.isPending}
                className={`w-full h-14 rounded-xl font-medium ${
                  signupData.phone && !signupMutation.isPending
                    ? "bg-black text-white hover:bg-gray-800"
                    : "bg-gray-300 text-gray-500"
                }`}
              >
                Continue
              </Button>
            </div>
          </div>
        );

      case "verification":
        return (
          <div className="space-y-6">
            <div className="text-sm text-gray-500 mb-6">
              Enter the code we sent to <span className="text-gray-400">{signupData.phone}</span>
            </div>
            <div className="flex gap-2 justify-center mb-6">
              {Array.from({ length: 6 }).map((_, index) => (
                <Input
                  key={index}
                  type="text"
                  maxLength={1}
                  value={signupData.verificationCode[index] || ""}
                  onChange={(e) => {
                    const newCode = signupData.verificationCode.split("");
                    newCode[index] = e.target.value;
                    handleInputChange("verificationCode", newCode.join(""));
                    // Auto-focus next input
                    if (e.target.value && index < 5) {
                      const nextInput = e.target.parentElement?.nextElementSibling?.querySelector('input');
                      nextInput?.focus();
                    }
                  }}
                  className="w-12 h-12 text-center border-2 border-gray-300 rounded-lg text-lg font-medium"
                />
              ))}
            </div>
            <Button
              variant="outline"
              className="w-full h-12 rounded-xl border-gray-300"
              onClick={() => {
                // Simulate pasting from clipboard
                handleInputChange("verificationCode", "555532");
                toast({
                  title: "Code pasted",
                  description: "Verification code has been filled in",
                });
              }}
            >
              <Copy className="w-4 h-4 mr-2" />
              Paste from clipboard
            </Button>
            <div className="flex gap-3 mt-8">
              <Button
                variant="default"
                className="w-full h-12 bg-black text-white rounded-xl"
                onClick={() => {
                  toast({
                    title: "Code resent",
                    description: "A new verification code has been sent",
                  });
                }}
              >
                Resend code
              </Button>
            </div>
            
            {/* Phone Keyboard UI */}
            <div className="mt-8 bg-gray-100 rounded-lg p-4">
              <div className="text-center text-sm text-gray-600 mb-2">From Messages</div>
              <div className="text-center text-lg font-bold mb-4">555532</div>
              <div className="grid grid-cols-3 gap-3">
                {[
                  { number: "1", letters: "" },
                  { number: "2", letters: "ABC" },
                  { number: "3", letters: "DEF" },
                  { number: "4", letters: "GHI" },
                  { number: "5", letters: "JKL" },
                  { number: "6", letters: "MNO" },
                  { number: "7", letters: "PQRS" },
                  { number: "8", letters: "TUV" },
                  { number: "9", letters: "WXYZ" },
                  { number: "*", letters: "" },
                  { number: "0", letters: "" },
                  { number: "⌫", letters: "" },
                ].map((key) => (
                  <Button
                    key={key.number}
                    variant="ghost"
                    className="h-12 bg-white rounded-lg flex flex-col items-center justify-center text-black hover:bg-gray-50"
                    onClick={() => {
                      if (key.number === "⌫") {
                        handleInputChange("verificationCode", signupData.verificationCode.slice(0, -1));
                      } else if (key.number !== "*" && signupData.verificationCode.length < 6) {
                        handleInputChange("verificationCode", signupData.verificationCode + key.number);
                      }
                    }}
                  >
                    <span className="text-xl font-medium">{key.number}</span>
                    {key.letters && <span className="text-xs text-gray-500">{key.letters}</span>}
                  </Button>
                ))}
              </div>
            </div>

            <div className="mt-8">
              <Button 
                onClick={handleNext}
                disabled={signupData.verificationCode.length !== 6 || signupMutation.isPending}
                className={`w-full h-14 rounded-xl font-medium ${
                  signupData.verificationCode.length === 6 && !signupMutation.isPending
                    ? "bg-black text-white hover:bg-gray-800"
                    : "bg-gray-300 text-gray-500"
                }`}
              >
                Next
              </Button>
            </div>
          </div>
        );

      case "permissions":
        return (
          <div className="space-y-8">
            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-medium text-lg">Log in with Face ID</h3>
                  <p className="text-sm text-gray-500">Access your account quickly and securely.</p>
                </div>
                <Button
                  variant="ghost"
                  onClick={() => handleInputChange("faceId", !signupData.faceId)}
                  className="p-0 h-auto"
                >
                  <div className={`w-12 h-6 rounded-full transition-colors relative ${
                    signupData.faceId ? "bg-green-500" : "bg-gray-300"
                  }`}>
                    <div className={`w-6 h-6 bg-white rounded-full transition-transform absolute top-0 ${
                      signupData.faceId ? "translate-x-6" : "translate-x-0"
                    }`} />
                  </div>
                </Button>
              </div>
              
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-medium text-lg">Get notifications</h3>
                  <p className="text-sm text-gray-500">Don't miss important updates regarding your account, new features and more.</p>
                </div>
                <Button
                  variant="ghost"
                  onClick={() => handleInputChange("notifications", !signupData.notifications)}
                  className="p-0 h-auto"
                >
                  <div className={`w-12 h-6 rounded-full transition-colors relative ${
                    signupData.notifications ? "bg-green-500" : "bg-gray-300"
                  }`}>
                    <div className={`w-6 h-6 bg-white rounded-full transition-transform absolute top-0 ${
                      signupData.notifications ? "translate-x-6" : "translate-x-0"
                    }`} />
                  </div>
                </Button>
              </div>
            </div>
            
            <div className="mt-auto pt-16">
              <Button 
                onClick={handleNext}
                disabled={signupMutation.isPending}
                className="w-full h-14 bg-black text-white rounded-xl font-medium hover:bg-gray-800"
              >
                {signupMutation.isPending ? "Creating Account..." : "Continue"}
              </Button>
            </div>
          </div>
        );

      default:
        return null;
    }
  };

  const getStepTitle = () => {
    switch (currentStep) {
      case "email":
      case "password":
      case "phone":
        return "Sign up";
      case "verification":
        return "Confirm it's you";
      case "permissions":
        return "Let's set up some permissions";
      default:
        return "Sign up";
    }
  };

  return (
    <div className="min-h-screen bg-white flex flex-col">
      {/* Status Bar */}
      <div className="bg-white h-11 flex items-center justify-between px-6 text-sm font-medium">
        <span>9:41</span>
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
        <div className="flex items-center justify-between mb-8">
          <Button
            variant="ghost"
            size="sm"
            onClick={currentStep === "email" ? () => setLocation("/") : handleBack}
            className="p-0 h-auto"
          >
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <h1 className="text-lg font-medium">{getStepTitle()}</h1>
          <div className="w-5"></div>
        </div>

        <div className="flex-1">
          {renderStepContent()}
          {errors && (
            <p className="text-sm text-red-600 mt-2">{errors}</p>
          )}
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