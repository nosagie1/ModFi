import { useAgencyBrand } from "@/hooks/use-agency-brand";
import type { Card } from "@shared/schema";

interface DynamicAgencyCardProps {
  card: Card;
  onClick?: () => void;
  className?: string;
}

export default function DynamicAgencyCard({ card, onClick, className = "" }: DynamicAgencyCardProps) {
  const { data: brandInfo, isLoading } = useAgencyBrand(card.holderName);

  // Fallback colors based on card type
  const getFallbackGradient = (cardType: string) => {
    switch (cardType.toLowerCase()) {
      case "soul artist management":
        return "from-purple-500 to-purple-600";
      case "wilhelmina london":
        return "from-blue-500 to-blue-600";
      case "society management":
        return "from-green-500 to-green-600";
      default:
        return "from-gray-500 to-gray-600";
    }
  };

  const getFallbackInitials = (name: string) => {
    return name
      .split(' ')
      .map(word => word.charAt(0))
      .join('')
      .substring(0, 2)
      .toUpperCase();
  };

  // Use brand info if available, otherwise use fallback
  const gradient = brandInfo?.primaryColor 
    ? `linear-gradient(135deg, ${brandInfo.primaryColor}, ${brandInfo.secondaryColor || brandInfo.primaryColor})`
    : `bg-gradient-to-br ${getFallbackGradient(card.holderName)}`;

  const textColor = brandInfo?.textColor || "#FFFFFF";
  const logo = brandInfo?.logo;
  const initials = brandInfo?.icon || getFallbackInitials(card.holderName);

  return (
    <div 
      className={`relative overflow-hidden rounded-3xl p-6 text-white cursor-pointer transform transition-all duration-300 hover:scale-105 hover:shadow-2xl ${className}`}
      style={{
        background: brandInfo?.primaryColor ? gradient : undefined,
      }}
      onClick={onClick}
    >
      {/* Background gradient for fallback */}
      {!brandInfo?.primaryColor && (
        <div className={`absolute inset-0 bg-gradient-to-br ${getFallbackGradient(card.holderName)}`} />
      )}
      
      {/* Loading overlay */}
      {isLoading && (
        <div className="absolute inset-0 bg-black bg-opacity-20 flex items-center justify-center">
          <div className="w-6 h-6 border-2 border-white border-t-transparent rounded-full animate-spin" />
        </div>
      )}

      {/* Card Content */}
      <div className="relative z-10">
        {/* Header with logo/initials */}
        <div className="flex justify-between items-start mb-8">
          <div className="flex items-center space-x-3">
            {logo ? (
              <img 
                src={logo} 
                alt={card.holderName}
                className="w-12 h-12 object-contain bg-white rounded-lg p-2"
                onError={(e) => {
                  // Fallback to initials if logo fails to load
                  e.currentTarget.style.display = 'none';
                  const fallbackDiv = e.currentTarget.nextElementSibling as HTMLElement;
                  if (fallbackDiv) fallbackDiv.style.display = 'flex';
                }}
              />
            ) : null}
            
            {/* Fallback initials (hidden if logo exists) */}
            <div 
              className={`w-12 h-12 rounded-full flex items-center justify-center font-bold text-lg bg-white bg-opacity-20 ${logo ? 'hidden' : 'flex'}`}
              style={{ color: textColor }}
            >
              {initials}
            </div>
            
            <div>
              <div className="text-xs opacity-75" style={{ color: textColor }}>
                {card.type}
              </div>
              <div className="font-semibold text-sm" style={{ color: textColor }}>
                {brandInfo?.name || card.holderName}
              </div>
            </div>
          </div>
          
          {/* Card number */}
          <div className="text-right">
            <div className="text-xs opacity-75" style={{ color: textColor }}>
              •••• {card.lastFourDigits}
            </div>
          </div>
        </div>

        {/* Balance */}
        <div className="mb-4">
          <div className="text-xs opacity-75 mb-1" style={{ color: textColor }}>
            Available Balance
          </div>
          <div className="text-2xl font-bold" style={{ color: textColor }}>
            {card.balance}
          </div>
        </div>

        {/* Footer */}
        <div className="flex justify-between items-end">
          <div>
            <div className="text-xs opacity-75" style={{ color: textColor }}>
              Valid Thru
            </div>
            <div className="text-sm font-medium" style={{ color: textColor }}>
              {card.expiry}
            </div>
          </div>
          
          {/* Brand indicator */}
          {brandInfo && (
            <div className="text-xs opacity-75" style={{ color: textColor }}>
              Powered by Brandfetch
            </div>
          )}
        </div>
      </div>

      {/* Decorative elements */}
      <div 
        className="absolute top-0 right-0 w-32 h-32 rounded-full opacity-10 transform translate-x-16 -translate-y-16"
        style={{ backgroundColor: textColor }}
      />
      <div 
        className="absolute bottom-0 left-0 w-24 h-24 rounded-full opacity-5 transform -translate-x-12 translate-y-12"
        style={{ backgroundColor: textColor }}
      />
    </div>
  );
}