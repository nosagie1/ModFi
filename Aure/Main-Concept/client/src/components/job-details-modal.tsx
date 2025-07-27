import { X } from "lucide-react";

interface JobDetailsModalProps {
  isOpen: boolean;
  onClose: () => void;
  company: string;
  model: string;
  amount: string;
  date: string;
  status: 'Received' | 'Upcoming' | 'Overdue';
  icon?: React.ReactNode;
  initials?: string;
  bgColor?: string;
}

export default function JobDetailsModal({
  isOpen,
  onClose,
  company,
  model,
  amount,
  date,
  status,
  icon,
  initials,
  bgColor = "from-gray-800 to-black"
}: JobDetailsModalProps) {
  if (!isOpen) return null;

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Received':
        return 'text-green-600';
      case 'Upcoming':
        return 'text-orange-600';
      case 'Overdue':
        return 'text-red-600';
      default:
        return 'text-gray-600';
    }
  };

  const getGainLoss = () => {
    const baseAmount = parseFloat(amount.replace('$', '').replace(',', ''));
    const percentage = Math.random() * 10 - 5; // Random percentage between -5% and +5%
    const gain = baseAmount * (percentage / 100);
    return { gain: gain.toFixed(2), percentage: percentage.toFixed(2) };
  };

  const { gain, percentage } = getGainLoss();
  const daysWorked = Math.floor(Math.random() * 365) + 1; // Random days between 1-365
  const sharesEquivalent = (parseFloat(amount.replace('$', '').replace(',', '')) / 150).toFixed(5); // Mock shares calculation
  const avgPrice = (parseFloat(amount.replace('$', '').replace(',', '')) / parseFloat(sharesEquivalent)).toFixed(2);
  const portfolioWeight = (Math.random() * 50 + 10).toFixed(2); // Random weight between 10-60%

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl max-w-sm w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="p-4 border-b border-gray-100">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className={`w-12 h-12 bg-gradient-to-br ${bgColor} rounded-xl flex items-center justify-center`}>
                {icon ? (
                  icon
                ) : (
                  <span className="text-white font-bold text-sm">{initials}</span>
                )}
              </div>
              <div>
                <h2 className="text-xl font-bold text-gray-900">{company}</h2>
                <p className="text-gray-600 text-sm">{model}</p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="p-2 hover:bg-gray-100 rounded-full transition-colors"
            >
              <X className="w-5 h-5 text-gray-500" />
            </button>
          </div>
          
          {/* Status and percentage */}
          <div className="mt-3 flex items-center justify-between">
            <span className={`${getStatusColor(status)} font-semibold`}>
              {parseFloat(percentage) >= 0 ? '+' : ''}{percentage}%
            </span>
            <button className="text-gray-400 hover:text-gray-600">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </button>
          </div>
        </div>

        {/* Details */}
        <div className="p-4 space-y-4">
          {/* Gain/Loss */}
          <div className="flex justify-between items-center py-3 border-b border-gray-100">
            <span className="text-gray-600">Gain/Loss</span>
            <span className={`font-semibold ${parseFloat(percentage) >= 0 ? 'text-green-600' : 'text-red-600'}`}>
              ${parseFloat(percentage) >= 0 ? '+' : ''}{gain} ({percentage}%)
            </span>
          </div>

          {/* Total Earnings */}
          <div className="flex justify-between items-center py-3 border-b border-gray-100">
            <span className="text-gray-600">Total Earnings</span>
            <span className="font-bold text-gray-900">{amount}</span>
          </div>

          {/* Projects Completed */}
          <div className="flex justify-between items-center py-3 border-b border-gray-100">
            <span className="text-gray-600">Projects</span>
            <span className="font-semibold text-gray-900">{sharesEquivalent} projects</span>
          </div>

          {/* Average Rate */}
          <div className="flex justify-between items-center py-3 border-b border-gray-100">
            <span className="text-gray-600">Average Rate</span>
            <span className="font-semibold text-gray-900">${avgPrice}/project</span>
          </div>

          {/* Portfolio Weight */}
          <div className="flex justify-between items-center py-3 border-b border-gray-100">
            <span className="text-gray-600">Portfolio Weight</span>
            <span className="font-semibold text-gray-900">{portfolioWeight}% of Earnings</span>
          </div>

          {/* Working Period */}
          <div className="flex justify-between items-center py-3">
            <span className="text-gray-600">Working for</span>
            <span className="font-semibold text-gray-900">{daysWorked} days</span>
          </div>
        </div>
      </div>
    </div>
  );
}