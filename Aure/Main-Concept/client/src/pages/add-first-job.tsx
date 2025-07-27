import { useState } from "react";
import { useLocation } from "wouter";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { useToast } from "@/hooks/use-toast";
import { CalendarIcon, Building2, Briefcase, DollarSign, ArrowRight } from "lucide-react";
import { format } from "date-fns";
import { cn } from "@/lib/utils";

interface AddFirstJobProps {
  userId?: string;
}

export default function AddFirstJob({ userId }: AddFirstJobProps) {
  const [, setLocation] = useLocation();
  const [client, setClient] = useState("");
  const [jobTitle, setJobTitle] = useState("");
  const [bookedBy, setBookedBy] = useState("");
  const [status, setStatus] = useState<"Pending" | "Invoiced" | "Partially Paid" | "Received">("Pending");
  const [jobDate, setJobDate] = useState<Date>();
  const [dueDate, setDueDate] = useState<Date>();
  const [amount, setAmount] = useState("");
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const currentUserId = userId || localStorage.getItem("currentUserId");

  const createJobMutation = useMutation({
    mutationFn: async (jobData: any) => {
      try {
        const response = await apiRequest("POST", `/api/jobs`, jobData);
        return await response.json();
      } catch (error) {
        console.error('Job creation error:', error);
        throw error;
      }
    },
    onSuccess: () => {
      toast({
        title: "Success!",
        description: "Your first job has been added to your profile.",
      });
      
      // Clear the cache to ensure fresh data
      try {
        queryClient.invalidateQueries();
      } catch (error) {
        console.error('Error invalidating queries:', error);
      }
      
      // Redirect to dashboard
      setLocation("/");
    },
    onError: (error: any) => {
      toast({
        title: "Error",
        description: error.message || "Failed to add job. Please try again.",
        variant: "destructive",
      });
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!client || !bookedBy || !jobDate || !dueDate || !amount) {
      toast({
        title: "Missing Information",
        description: "Please fill in all required fields.",
        variant: "destructive",
      });
      return;
    }

    // Validate userId
    if (!currentUserId || isNaN(parseInt(currentUserId))) {
      toast({
        title: "Authentication Error",
        description: "Please log in again to continue.",
        variant: "destructive",
      });
      setLocation("/login");
      return;
    }

    // Validate amount
    const parsedAmount = parseFloat(amount);
    if (isNaN(parsedAmount) || parsedAmount <= 0) {
      toast({
        title: "Invalid Amount",
        description: "Please enter a valid amount greater than 0.",
        variant: "destructive",
      });
      return;
    }

    try {
      const jobData = {
        userId: parseInt(currentUserId),
        client: client.trim(),
        jobTitle: jobTitle?.trim() || undefined,
        bookedBy: bookedBy.trim(),
        status,
        jobDate: jobDate.toISOString(),
        dueDate: dueDate.toISOString(),
        amount: parsedAmount,
      };

      createJobMutation.mutate(jobData);
    } catch (error) {
      console.error('Error preparing job data:', error);
      toast({
        title: "Error",
        description: "Failed to prepare job data. Please try again.",
        variant: "destructive",
      });
    }
  };

  const skipForNow = () => {
    setLocation("/");
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

      {/* Header */}
      <div className="px-6 py-4">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Almost done!</h1>
          <p className="text-gray-600">Add your first job to see your earnings in action</p>
        </div>
      </div>

      {/* Progress Indicator */}
      <div className="px-6 mb-6">
        <div className="flex items-center space-x-2">
          <div className="w-6 h-6 bg-gray-900 rounded-full flex items-center justify-center">
            <span className="text-white text-xs font-bold">✓</span>
          </div>
          <div className="flex-1 h-0.5 bg-gray-900"></div>
          <div className="w-6 h-6 bg-gray-900 rounded-full flex items-center justify-center">
            <span className="text-white text-xs font-bold">2</span>
          </div>
          <div className="flex-1 h-0.5 bg-gray-300"></div>
          <div className="w-6 h-6 bg-gray-300 rounded-full flex items-center justify-center">
            <span className="text-gray-500 text-xs font-bold">3</span>
          </div>
        </div>
        <div className="flex justify-between mt-2 text-xs text-gray-600">
          <span>Agency</span>
          <span className="font-semibold">First Job</span>
          <span>Dashboard</span>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 px-6">
        <Card className="border-0 shadow-none">
          <CardHeader className="px-0 pb-4">
            <div className="flex items-center space-x-3 mb-2">
              <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                <Briefcase className="w-5 h-5 text-gray-600" />
              </div>
              <div>
                <CardTitle className="text-lg font-semibold text-gray-900">Add Your First Job</CardTitle>
                <CardDescription className="text-sm text-gray-600">
                  This helps us show your actual earnings data
                </CardDescription>
              </div>
            </div>
          </CardHeader>
          
          <CardContent className="px-0">
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="client" className="text-sm font-medium text-gray-700">
                    Client/Brand *
                  </Label>
                  <div className="relative">
                    <Building2 className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                    <Input
                      id="client"
                      placeholder="e.g. Calvin Klein"
                      value={client}
                      onChange={(e) => setClient(e.target.value)}
                      className="pl-10"
                      disabled={createJobMutation.isPending}
                    />
                  </div>
                </div>
                
                <div className="space-y-2">
                  <Label htmlFor="amount" className="text-sm font-medium text-gray-700">
                    Amount *
                  </Label>
                  <div className="relative">
                    <DollarSign className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                    <Input
                      id="amount"
                      type="number"
                      step="0.01"
                      placeholder="5000"
                      value={amount}
                      onChange={(e) => setAmount(e.target.value)}
                      className="pl-10"
                      disabled={createJobMutation.isPending}
                    />
                  </div>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="jobTitle" className="text-sm font-medium text-gray-700">
                  Job Title
                </Label>
                <Input
                  id="jobTitle"
                  placeholder="e.g. Fashion Campaign, Runway Show"
                  value={jobTitle}
                  onChange={(e) => setJobTitle(e.target.value)}
                  disabled={createJobMutation.isPending}
                />
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="bookedBy" className="text-sm font-medium text-gray-700">
                  Booked By *
                </Label>
                <Input
                  id="bookedBy"
                  placeholder="Agency or casting director name"
                  value={bookedBy}
                  onChange={(e) => setBookedBy(e.target.value)}
                  disabled={createJobMutation.isPending}
                />
              </div>

              <div className="space-y-2">
                <Label className="text-sm font-medium text-gray-700">Status</Label>
                <Select value={status} onValueChange={(value: any) => setStatus(value)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Pending">Pending</SelectItem>
                    <SelectItem value="Invoiced">Invoiced</SelectItem>
                    <SelectItem value="Partially Paid">Partially Paid</SelectItem>
                    <SelectItem value="Received">Received</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label className="text-sm font-medium text-gray-700">Job Date *</Label>
                  <Popover>
                    <PopoverTrigger asChild>
                      <Button
                        variant="outline"
                        className={cn(
                          "w-full justify-start text-left font-normal",
                          !jobDate && "text-muted-foreground"
                        )}
                      >
                        <CalendarIcon className="mr-2 h-4 w-4" />
                        {jobDate ? format(jobDate, "MMM dd, yyyy") : "Select date"}
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-auto p-0" align="start">
                      <Calendar
                        mode="single"
                        selected={jobDate}
                        onSelect={setJobDate}
                        initialFocus
                      />
                    </PopoverContent>
                  </Popover>
                </div>

                <div className="space-y-2">
                  <Label className="text-sm font-medium text-gray-700">Due Date *</Label>
                  <Popover>
                    <PopoverTrigger asChild>
                      <Button
                        variant="outline"
                        className={cn(
                          "w-full justify-start text-left font-normal",
                          !dueDate && "text-muted-foreground"
                        )}
                      >
                        <CalendarIcon className="mr-2 h-4 w-4" />
                        {dueDate ? format(dueDate, "MMM dd, yyyy") : "Select date"}
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-auto p-0" align="start">
                      <Calendar
                        mode="single"
                        selected={dueDate}
                        onSelect={setDueDate}
                        initialFocus
                      />
                    </PopoverContent>
                  </Popover>
                </div>
              </div>

              <div className="flex space-x-3 pt-4">
                <Button
                  type="submit"
                  disabled={createJobMutation.isPending}
                  className="flex-1 bg-gray-900 hover:bg-gray-800 text-white font-semibold py-4 rounded-full"
                >
                  {createJobMutation.isPending ? (
                    <div className="flex items-center space-x-2">
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                      <span>Adding...</span>
                    </div>
                  ) : (
                    <div className="flex items-center space-x-2">
                      <span>Add Job</span>
                      <ArrowRight className="w-4 h-4" />
                    </div>
                  )}
                </Button>
              </div>

              <div className="text-center mt-4">
                <button
                  type="button"
                  onClick={skipForNow}
                  className="text-gray-600 hover:text-gray-800 font-medium text-sm"
                  disabled={createJobMutation.isPending}
                >
                  Skip for now
                </button>
              </div>
            </form>
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