import React, { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Calendar } from "@/components/ui/calendar";
import { cn } from "@/lib/utils";
import { format } from "date-fns";
import { CalendarIcon } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { Job } from "@shared/schema";

interface EditJobModalProps {
  isOpen: boolean;
  onClose: () => void;
  onUpdateJob: (jobId: number, jobData: Partial<Job>) => void;
  job: Job | null | undefined;
}

const agencies = [
  "Soul Artist Management",
  "Wilhelmina London", 
  "Society Management",
  "IMG Models",
  "Next Models",
  "Ford Models",
  "Independent"
];

export default function EditJobModal({ isOpen, onClose, onUpdateJob, job }: EditJobModalProps) {
  const { toast } = useToast();
  const [formData, setFormData] = useState<Partial<Job>>({});
  const [errors, setErrors] = useState<Record<string, string>>({});

  // Reset form data when job changes
  useEffect(() => {
    if (job) {
      setFormData({
        client: job.client,
        jobTitle: job.jobTitle,
        bookedBy: job.bookedBy,
        status: job.status,
        jobDate: new Date(job.jobDate),
        dueDate: new Date(job.dueDate),
        amount: job.amount
      });
    }
  }, [job]);

  const handleJobDateChange = (date: Date | undefined) => {
    if (date) {
      setFormData(prev => ({
        ...prev,
        jobDate: date,
        // Auto-update due date to 30 days after job date
        dueDate: new Date(date.getTime() + 30 * 24 * 60 * 60 * 1000)
      }));
      setErrors(prev => ({ ...prev, jobDate: "", dueDate: "" }));
    }
  };

  const handleDueDateChange = (date: Date | undefined) => {
    if (date) {
      setFormData(prev => ({ ...prev, dueDate: date }));
      setErrors(prev => ({ ...prev, dueDate: "" }));
    }
  };

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.client?.trim()) {
      newErrors.client = "Client name is required";
    }

    if (!formData.bookedBy) {
      newErrors.bookedBy = "Agency is required";
    }

    if (!formData.status) {
      newErrors.status = "Status is required";
    }

    if (!formData.jobDate) {
      newErrors.jobDate = "Job date is required";
    }

    if (!formData.dueDate) {
      newErrors.dueDate = "Due date is required";
    }

    if (!formData.amount || parseFloat(formData.amount) <= 0) {
      newErrors.amount = "Valid amount is required";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = () => {
    if (!validateForm() || !job) {
      toast({
        title: "Validation Error",
        description: "Please fill in all required fields",
        variant: "destructive"
      });
      return;
    }

    const updatedJobData = {
      client: formData.client!,
      jobTitle: formData.jobTitle || null,
      bookedBy: formData.bookedBy!,
      status: formData.status!,
      jobDate: formData.jobDate!,
      dueDate: formData.dueDate!,
      amount: formData.amount!
    };

    onUpdateJob(job.id, updatedJobData);
    
    toast({
      title: "Job Updated",
      description: `Successfully updated job for ${updatedJobData.client}`,
    });

    onClose();
  };

  const handleCancel = () => {
    setFormData({});
    setErrors({});
    onClose();
  };

  if (!job) return null;

  return (
    <Dialog open={isOpen} onOpenChange={handleCancel}>
      <DialogContent className="sm:max-w-[500px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Edit Job</DialogTitle>
        </DialogHeader>
        
        <div className="space-y-6 py-4">
          {/* Client */}
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="client" className="text-right">
              Client *
            </Label>
            <div className="col-span-3">
              <Input
                id="client"
                placeholder="e.g., Tommy Hilfiger"
                value={formData.client || ""}
                onChange={(e) => setFormData(prev => ({ ...prev, client: e.target.value }))}
                className={errors.client ? "border-red-500" : ""}
              />
              {errors.client && <p className="text-red-500 text-xs mt-1">{errors.client}</p>}
            </div>
          </div>

          {/* Job Title */}
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="jobTitle" className="text-right">
              Job Title
            </Label>
            <div className="col-span-3">
              <Input
                id="jobTitle"
                placeholder="e.g., Spring Campaign Shoot"
                value={formData.jobTitle || ""}
                onChange={(e) => setFormData(prev => ({ ...prev, jobTitle: e.target.value }))}
              />
            </div>
          </div>

          {/* Booked By (Agency) */}
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="bookedBy" className="text-right">
              Agency *
            </Label>
            <div className="col-span-3">
              <Select value={formData.bookedBy || ""} onValueChange={(value) => setFormData(prev => ({ ...prev, bookedBy: value }))}>
                <SelectTrigger className={errors.bookedBy ? "border-red-500" : ""}>
                  <SelectValue placeholder="Select agency" />
                </SelectTrigger>
                <SelectContent>
                  {agencies.map((agency) => (
                    <SelectItem key={agency} value={agency}>
                      {agency}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors.bookedBy && <p className="text-red-500 text-xs mt-1">{errors.bookedBy}</p>}
            </div>
          </div>

          {/* Status */}
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="status" className="text-right">
              Status *
            </Label>
            <div className="col-span-3">
              <Select value={formData.status || ""} onValueChange={(value) => setFormData(prev => ({ ...prev, status: value as any }))}>
                <SelectTrigger className={errors.status ? "border-red-500" : ""}>
                  <SelectValue placeholder="Select status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Pending">Pending</SelectItem>
                  <SelectItem value="Invoiced">Invoiced</SelectItem>
                  <SelectItem value="Partially Paid">Partially Paid</SelectItem>
                  <SelectItem value="Received">Received</SelectItem>
                </SelectContent>
              </Select>
              {errors.status && <p className="text-red-500 text-xs mt-1">{errors.status}</p>}
            </div>
          </div>

          {/* Job Date */}
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="jobDate" className="text-right">
              Job Date *
            </Label>
            <div className="col-span-3">
              <Popover>
                <PopoverTrigger asChild>
                  <Button
                    variant={"outline"}
                    className={cn(
                      "w-full justify-start text-left font-normal",
                      !formData.jobDate && "text-muted-foreground",
                      errors.jobDate && "border-red-500"
                    )}
                  >
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {formData.jobDate ? format(formData.jobDate, "PPP") : <span>Pick a date</span>}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0">
                  <Calendar
                    mode="single"
                    selected={formData.jobDate}
                    onSelect={handleJobDateChange}
                    initialFocus
                  />
                </PopoverContent>
              </Popover>
              {errors.jobDate && <p className="text-red-500 text-xs mt-1">{errors.jobDate}</p>}
            </div>
          </div>

          {/* Due Date */}
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="dueDate" className="text-right">
              Due Date *
            </Label>
            <div className="col-span-3">
              <Popover>
                <PopoverTrigger asChild>
                  <Button
                    variant={"outline"}
                    className={cn(
                      "w-full justify-start text-left font-normal",
                      !formData.dueDate && "text-muted-foreground",
                      errors.dueDate && "border-red-500"
                    )}
                  >
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {formData.dueDate ? format(formData.dueDate, "PPP") : <span>Pick a date</span>}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0">
                  <Calendar
                    mode="single"
                    selected={formData.dueDate}
                    onSelect={handleDueDateChange}
                    initialFocus
                  />
                </PopoverContent>
              </Popover>
              {errors.dueDate && <p className="text-red-500 text-xs mt-1">{errors.dueDate}</p>}
            </div>
          </div>

          {/* Amount */}
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="amount" className="text-right">
              Amount *
            </Label>
            <div className="col-span-3">
              <div className="relative">
                <span className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500">$</span>
                <Input
                  id="amount"
                  type="number"
                  placeholder="0.00"
                  className={`pl-8 ${errors.amount ? "border-red-500" : ""}`}
                  value={formData.amount || ""}
                  onChange={(e) => setFormData(prev => ({ ...prev, amount: e.target.value }))}
                />
              </div>
              {errors.amount && <p className="text-red-500 text-xs mt-1">{errors.amount}</p>}
            </div>
          </div>
        </div>

        <div className="flex justify-end space-x-2 pt-4">
          <Button variant="outline" onClick={handleCancel}>
            Cancel
          </Button>
          <Button onClick={handleSubmit}>
            Update Job
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}