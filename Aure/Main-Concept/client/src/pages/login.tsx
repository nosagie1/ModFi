import { useState } from "react";
import { useLocation } from "wouter";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";
import { Eye, EyeOff, Mail, Lock, ArrowLeft, User } from "lucide-react";

export default function LoginPage() {
  const [, setLocation] = useLocation();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const loginMutation = useMutation({
    mutationFn: async (credentials: { email: string; password: string }) => {
      const response = await fetch(`/api/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(credentials),
      });
      
      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Login failed');
      }
      
      return response.json();
    },
    onSuccess: (data) => {
      // Clear any existing auth data first
      localStorage.clear();
      
      // Clear React Query cache to ensure fresh data
      queryClient.clear();
      
      // Store user session
      localStorage.setItem("currentUserId", data.user.id.toString());
      localStorage.setItem("userAuthenticated", "true");
      
      // Trigger auth state change event
      window.dispatchEvent(new Event('authStateChange'));
      
      toast({
        title: "Login Successful",
        description: `Welcome back, ${data.user.name}!`,
      });
      
      // Redirect to dashboard after successful login
      setTimeout(() => {
        setLocation("/");
      }, 500);
    },
    onError: (error: any) => {
      toast({
        title: "Login Failed",
        description: error.message || "Invalid username or password",
        variant: "destructive",
      });
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || !password.trim()) {
      toast({
        title: "Missing Information",
        description: "Please enter both email and password",
        variant: "destructive",
      });
      return;
    }
    loginMutation.mutate({ email, password });
  };

  const goBack = () => {
    setLocation("/");
  };

  const goToSignup = () => {
    setLocation("/signup");
  };

  return (
    <div className="min-h-screen bg-white flex flex-col">
      {/* Status Bar */}
      <div className="flex items-center justify-between px-6 pt-4 pb-2">
        <div className="text-sm font-semibold">09:41</div>
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

      {/* Header with Back Button */}
      <div className="flex items-center px-6 py-4">
        <button onClick={goBack} className="mr-4">
          <ArrowLeft className="w-6 h-6 text-gray-600" />
        </button>
        <h1 className="text-xl font-semibold text-gray-900">Log in</h1>
      </div>

      {/* Main Content */}
      <div className="flex-1 px-6">
        <Card className="border-0 shadow-none">
          <CardHeader className="text-center space-y-2 px-0">
            <div className="mx-auto mb-8">
              <h1 className="text-4xl font-bold text-gray-900 tracking-tight mb-3">
                DiemPay
              </h1>
              <div className="w-16 h-0.5 bg-gray-900 mx-auto mb-4"></div>
              <CardDescription className="text-gray-600 text-base">
                Sign in to continue managing your career
              </CardDescription>
            </div>
          </CardHeader>
          
          <CardContent className="px-0">
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="email" className="text-sm font-medium text-gray-700">
                  Email
                </Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                  <Input
                    id="email"
                    type="email"
                    placeholder="Enter your email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="pl-10"
                    disabled={loginMutation.isPending}
                  />
                </div>
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="password" className="text-sm font-medium text-gray-700">
                  Password
                </Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                  <Input
                    id="password"
                    type={showPassword ? "text" : "password"}
                    placeholder="Enter your password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="pl-10 pr-10"
                    disabled={loginMutation.isPending}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-3 text-gray-400 hover:text-gray-600"
                    disabled={loginMutation.isPending}
                  >
                    {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </button>
                </div>
              </div>

              <Button
                type="submit"
                disabled={loginMutation.isPending}
                className="w-full bg-gray-900 hover:bg-gray-800 text-white font-semibold py-4 rounded-full mt-8"
              >
                {loginMutation.isPending ? (
                  <div className="flex items-center space-x-2">
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                    <span>Signing in...</span>
                  </div>
                ) : (
                  "Log in"
                )}
              </Button>

              {/* Signup Link */}
              <div className="text-center mt-6">
                <span className="text-gray-600">Don't have an account? </span>
                <button
                  type="button"
                  onClick={goToSignup}
                  className="text-gray-900 font-semibold hover:underline"
                  disabled={loginMutation.isPending}
                >
                  Sign up
                </button>
              </div>
            </form>
            
            <div className="mt-8 p-4 bg-gray-50 rounded-lg">
              <p className="text-sm text-gray-800 font-medium mb-2">Demo Credentials:</p>
              <div className="text-xs text-gray-500 mt-1">
                Email: <span className="font-mono">kwaku@example.com</span>
              </div>
              <div className="text-xs text-gray-500">
                Password: <span className="font-mono">Test123</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Home Indicator */}
      <div className="flex justify-center mb-4">
        <div className="w-32 h-1 bg-black rounded-full"></div>
      </div>
    </div>
  );
}