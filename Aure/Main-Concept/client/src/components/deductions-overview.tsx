import { Building2, Percent } from "lucide-react";
import type { Job } from "@shared/schema";

interface DeductionsOverviewProps {
  jobs: Job[];
}

const formatCurrency = (amount: number): string => {
  return amount.toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
};

export default function DeductionsOverview({ jobs }: DeductionsOverviewProps) {
  // Calculate deduction metrics from actual job data
  const calculateDeductions = () => {
    if (!jobs || jobs.length === 0) {
      return {
        grossEarnings: 0,
        totalDeductions: 0,
        netEarnings: 0,
        agencyCommission: 0,
        taxWithholding: 0
      };
    }

    const grossEarnings = jobs.reduce((sum, job) => sum + parseFloat(job.amount), 0);
    
    // Calculate agency commission (20%)
    const agencyCommission = grossEarnings * 0.20;
    
    // Calculate tax withholding (15%)
    const taxWithholding = grossEarnings * 0.15;

    const totalDeductions = agencyCommission + taxWithholding;
    const netEarnings = grossEarnings - totalDeductions;

    return {
      grossEarnings,
      totalDeductions,
      netEarnings,
      agencyCommission,
      taxWithholding
    };
  };

  const deductions = calculateDeductions();

  return (
    <div className="bg-white rounded-2xl p-6 shadow-sm">
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-lg font-semibold text-gray-900">Deductions Overview</h2>
        <button className="text-gray-500 text-sm hover:text-gray-700 transition-colors">
          See breakdown
        </button>
      </div>
      
      {/* Financial Summary */}
      <div className="space-y-4 mb-6">
        {/* Gross Earnings */}
        <div className="flex justify-between items-center">
          <span className="text-gray-600">Gross Earnings</span>
          <span className="font-semibold text-gray-900">${formatCurrency(deductions.grossEarnings)}</span>
        </div>
        
        {/* Total Deductions */}
        <div className="flex justify-between items-center">
          <span className="text-gray-600">Total Deductions</span>
          <span className="font-semibold text-red-600">-${formatCurrency(deductions.totalDeductions)}</span>
        </div>
        
        {/* Net Earnings */}
        <div className="flex justify-between items-center pt-3 border-t border-gray-200">
          <span className="font-medium text-gray-900">Net Earnings</span>
          <span className="font-bold text-green-600">${formatCurrency(deductions.netEarnings)}</span>
        </div>
      </div>

      {/* Deduction Breakdown */}
      <div className="space-y-4">
        {/* Agency Commission */}
        <div className="flex items-center justify-between p-4 bg-gray-50 rounded-xl">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
              <Building2 className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <div className="font-medium text-gray-900">Agency Commission</div>
              <div className="text-sm text-gray-500">20% standard commission</div>
            </div>
          </div>
          <div className="text-right">
            <div className="font-semibold text-gray-900">-${formatCurrency(deductions.agencyCommission)}</div>
            <div className="text-sm text-gray-500">20%</div>
          </div>
        </div>

        {/* Tax Withholding */}
        <div className="flex items-center justify-between p-4 bg-gray-50 rounded-xl">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center">
              <Percent className="w-5 h-5 text-red-600" />
            </div>
            <div>
              <div className="font-medium text-gray-900">Tax Withholding</div>
              <div className="text-sm text-gray-500">Estimated federal & state</div>
            </div>
          </div>
          <div className="text-right">
            <div className="font-semibold text-gray-900">-${formatCurrency(deductions.taxWithholding)}</div>
            <div className="text-sm text-gray-500">15%</div>
          </div>
        </div>
      </div>
    </div>
  );
}