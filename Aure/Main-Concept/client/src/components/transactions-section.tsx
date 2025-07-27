import { Percent, CreditCard, Building2, TrendingDown } from "lucide-react";
import type { Job } from "@shared/schema";

interface DeductionsOverviewProps {
  jobs: Job[];
}

interface DeductionItem {
  id: string;
  title: string;
  description: string;
  amount: number;
  percentage?: number;
  icon: string;
  iconColor: string;
  category: 'agency' | 'tax' | 'professional' | 'other';
}

const getDeductionIcon = (iconName: string, iconColor: string) => {
  const className = `text-lg ${iconColor}`;
  
  switch (iconName) {
    case "percent":
      return <Percent className={className} />;
    case "building":
      return <Building2 className={className} />;
    case "credit-card":
      return <CreditCard className={className} />;
    case "trending-down":
      return <TrendingDown className={className} />;
    default:
      return <div className={`w-4 h-4 ${iconColor}`} />;
  }
};

export default function DeductionsOverview({ jobs }: DeductionsOverviewProps) {
  // Calculate total gross earnings from all jobs
  const totalGrossEarnings = jobs?.reduce((sum, job) => sum + parseFloat(job.amount), 0) || 0;
  
  // Calculate deductions
  const calculateDeductions = (): DeductionItem[] => {
    const agencyCommission = totalGrossEarnings * 0.20; // 20% agency commission
    const taxWithholding = totalGrossEarnings * 0.15; // 15% estimated tax withholding
    const professionalFees = 2500; // Fixed professional fees (photographers, makeup, etc.)
    const marketingExpenses = 1200; // Marketing and portfolio expenses
    
    return [
      {
        id: "agency-commission",
        title: "Agency Commission",
        description: "20% standard commission",
        amount: agencyCommission,
        percentage: 20,
        icon: "building",
        iconColor: "text-blue-600",
        category: 'agency'
      },
      {
        id: "tax-withholding",
        title: "Tax Withholding",
        description: "Estimated federal & state",
        amount: taxWithholding,
        percentage: 15,
        icon: "percent",
        iconColor: "text-red-600",
        category: 'tax'
      },
      {
        id: "professional-fees",
        title: "Professional Fees",
        description: "Photography, makeup, styling",
        amount: professionalFees,
        icon: "credit-card",
        iconColor: "text-purple-600",
        category: 'professional'
      },
      {
        id: "marketing-expenses",
        title: "Marketing & Portfolio",
        description: "Comp cards, website, promotion",
        amount: marketingExpenses,
        icon: "trending-down",
        iconColor: "text-orange-600",
        category: 'other'
      }
    ];
  };

  const deductions = calculateDeductions();
  const totalDeductions = deductions.reduce((sum, deduction) => sum + deduction.amount, 0);
  const netEarnings = totalGrossEarnings - totalDeductions;

  const formatAmount = (amount: number) => {
    return `$${amount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  };

  return (
    <div className="px-6 mb-20">
      <div className="bg-gradient-to-b from-card to-card/95 border border-border rounded-[24px] p-6 shadow-[0_8px_32px_rgba(0,0,0,0.12)] hover:shadow-[0_12px_40px_rgba(0,0,0,0.16)] transition-all duration-500 backdrop-blur-sm ml-[-25px] mr-[-25px]">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-foreground text-lg font-semibold">Deductions Overview</h2>
          <button className="text-muted-foreground text-sm hover:text-foreground transition-colors">
            See breakdown
          </button>
        </div>
        
        {/* Summary Section */}
        <div className="mb-6 p-4 bg-muted/30 rounded-lg">
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm text-muted-foreground">Gross Earnings</span>
            <span className="font-semibold text-foreground">{formatAmount(totalGrossEarnings)}</span>
          </div>
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm text-muted-foreground">Total Deductions</span>
            <span className="font-semibold text-red-600">-{formatAmount(totalDeductions)}</span>
          </div>
          <div className="border-t border-border pt-2 mt-2">
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium text-foreground">Net Earnings</span>
              <span className="font-bold text-lg text-green-600">{formatAmount(netEarnings)}</span>
            </div>
          </div>
        </div>
        
        {/* Deductions List */}
        <div className="space-y-4">
          {deductions.map((deduction) => (
            <div
              key={deduction.id}
              className="flex items-center justify-between hover:bg-muted p-2 rounded-lg transition-colors"
            >
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center">
                  {getDeductionIcon(deduction.icon, deduction.iconColor)}
                </div>
                <div>
                  <div className="text-foreground font-medium">{deduction.title}</div>
                  <div className="text-muted-foreground text-sm">
                    {deduction.description}
                  </div>
                </div>
              </div>
              <div className="text-right">
                <div className="text-foreground font-medium">
                  -{formatAmount(deduction.amount)}
                </div>
                <div className="text-muted-foreground text-sm">
                  {deduction.percentage ? `${deduction.percentage}%` : 'Fixed fee'}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
