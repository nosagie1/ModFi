import { useState } from "react";
import { X } from "lucide-react";
import { insertAgencySchema, type InsertAgency } from "@shared/schema";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

// Form schema with percentage input (will be converted to decimal)
const agencyFormSchema = z.object({
  name: z.string().min(1, "Agency name is required"),
  commissionRate: z.number().min(0, "Commission rate must be positive").max(100, "Commission rate cannot exceed 100%"),
  currency: z.string().default("USD")
});

type AgencyFormData = z.infer<typeof agencyFormSchema>;

interface AddAgencyModalProps {
  isOpen: boolean;
  onClose: () => void;
  onAddAgency: (agency: InsertAgency) => void;
  userId: number;
}

// Known agencies for autocomplete
const KNOWN_AGENCIES = [
  "IMG Models",
  "Elite Model Management", 
  "Ford Models",
  "Next Management",
  "Women Management",
  "Storm Models",
  "Premier Model Management",
  "The Lions",
  "Select Model Management",
  "Models 1",
  "Why Not Model Management",
  "Metropolitan Models",
  "Viva Model Management",
  "Red Model Management",
  "Nass Management"
];

const CURRENCIES = [
  { code: "USD", name: "US Dollar", symbol: "$" },
  { code: "EUR", name: "Euro", symbol: "€" },
  { code: "GBP", name: "British Pound", symbol: "£" },
  { code: "JPY", name: "Japanese Yen", symbol: "¥" },
  { code: "CAD", name: "Canadian Dollar", symbol: "C$" }
];

export default function AddAgencyModal({ isOpen, onClose, onAddAgency, userId }: AddAgencyModalProps) {
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [suggestions, setSuggestions] = useState<string[]>([]);

  const {
    register,
    handleSubmit,
    watch,
    setValue,
    reset,
    formState: { errors, isSubmitting }
  } = useForm<AgencyFormData>({
    resolver: zodResolver(agencyFormSchema),
    defaultValues: {
      name: "",
      commissionRate: 20, // Default 20%
      currency: "USD"
    }
  });

  const watchedName = watch("name");

  const handleNameChange = (value: string) => {
    setValue("name", value);
    
    if (value.length >= 2) {
      const filtered = KNOWN_AGENCIES.filter(agency =>
        agency.toLowerCase().includes(value.toLowerCase())
      );
      setSuggestions(filtered);
      setShowSuggestions(filtered.length > 0);
    } else {
      setShowSuggestions(false);
    }
  };

  const selectSuggestion = (suggestion: string) => {
    setValue("name", suggestion);
    setShowSuggestions(false);
  };

  const onSubmit = (data: AgencyFormData) => {
    const agencyData: InsertAgency = {
      ...data,
      commissionRate: (data.commissionRate / 100).toString(), // Convert percentage to decimal string
      userId
    };
    
    onAddAgency(agencyData);
    reset();
    onClose();
  };

  const handleClose = () => {
    reset();
    setShowSuggestions(false);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl w-full max-w-md mx-auto shadow-2xl">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-100">
          <h2 className="text-xl font-semibold text-gray-900">Add New Agency</h2>
          <button
            onClick={handleClose}
            className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-gray-100 transition-colors"
          >
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-6">
          {/* Agency Name */}
          <div className="relative">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Agency Name
            </label>
            <input
              type="text"
              {...register("name")}
              onChange={(e) => handleNameChange(e.target.value)}
              onFocus={() => watchedName.length >= 2 && setShowSuggestions(suggestions.length > 0)}
              onBlur={() => setTimeout(() => setShowSuggestions(false), 200)}
              className="w-full px-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
              placeholder="e.g., IMG Models"
            />
            
            {/* Autocomplete Suggestions */}
            {showSuggestions && (
              <div className="absolute top-full left-0 right-0 mt-1 bg-white border border-gray-200 rounded-lg shadow-lg z-50 max-h-40 overflow-y-auto">
                {suggestions.map((suggestion) => (
                  <button
                    key={suggestion}
                    type="button"
                    onClick={() => selectSuggestion(suggestion)}
                    className="w-full text-left px-4 py-2 hover:bg-gray-50 transition-colors text-sm"
                  >
                    {suggestion}
                  </button>
                ))}
              </div>
            )}
            
            {errors.name && (
              <p className="mt-1 text-sm text-red-600">{errors.name.message}</p>
            )}
          </div>

          {/* Commission Rate */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Commission Rate (%)
            </label>
            <div className="relative">
              <input
                type="number"
                step="0.1"
                min="0"
                max="100"
                {...register("commissionRate", { valueAsNumber: true })}
                className="w-full px-4 py-3 pr-8 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                placeholder="20"
              />
              <span className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500 text-sm">%</span>
            </div>
            {errors.commissionRate && (
              <p className="mt-1 text-sm text-red-600">{errors.commissionRate.message}</p>
            )}
          </div>

          {/* Currency */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Currency
            </label>
            <select
              {...register("currency")}
              className="w-full px-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
            >
              {CURRENCIES.map((currency) => (
                <option key={currency.code} value={currency.code}>
                  {currency.symbol} {currency.name} ({currency.code})
                </option>
              ))}
            </select>
            {errors.currency && (
              <p className="mt-1 text-sm text-red-600">{errors.currency.message}</p>
            )}
          </div>

          {/* Actions */}
          <div className="flex space-x-3 pt-4">
            <button
              type="button"
              onClick={handleClose}
              className="flex-1 px-4 py-3 border border-gray-200 rounded-lg text-gray-700 font-medium hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="flex-1 px-4 py-3 bg-blue-500 text-white rounded-lg font-medium hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {isSubmitting ? "Adding..." : "Add Agency"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}