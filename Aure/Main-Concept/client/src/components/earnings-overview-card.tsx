import { TrendingUp } from "lucide-react";

interface EarningsOverviewCardProps {
  earned: number;
  fees: number;
  upcoming: number;
  pending: number;
  pendingIncrease: number;
  overdue: number;
  overdueIncrease: number;
}

export default function EarningsOverviewCard({
  earned = 115246,
  fees = 6175,
  upcoming = 8700,
  pending = 5700,
  pendingIncrease = 4,
  overdue = 3000,
  overdueIncrease = 2
}: EarningsOverviewCardProps) {
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  return null;
}