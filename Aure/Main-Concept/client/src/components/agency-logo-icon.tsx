import { useAgencyBrand } from "@/hooks/use-agency-brand";

interface AgencyLogoIconProps {
  agencyName: string;
  fallbackIcon: string;
  fallbackColor: string;
  size?: "small" | "medium" | "large";
}

export default function AgencyLogoIcon({ agencyName, fallbackIcon, fallbackColor, size = "small" }: AgencyLogoIconProps) {
  const { data: brandInfo, isLoading } = useAgencyBrand(agencyName);

  // Size configurations
  const sizeConfig = {
    small: {
      container: "w-6 h-6",
      logo: "w-4 h-4",
      fallback: "w-4 h-4",
      spinner: "w-3 h-3",
      text: "text-xs",
      positioning: "absolute top-2 right-2"
    },
    medium: {
      container: "w-10 h-10",
      logo: "w-8 h-8",
      fallback: "w-8 h-8",
      spinner: "w-6 h-6",
      text: "text-sm",
      positioning: ""
    },
    large: {
      container: "w-12 h-12",
      logo: "w-10 h-10",
      fallback: "w-10 h-10",
      spinner: "w-8 h-8",
      text: "text-base",
      positioning: ""
    }
  };

  const config = sizeConfig[size];

  return (
    <div className={config.positioning}>
      <div className={`${config.container} bg-white bg-opacity-70 rounded-full flex items-center justify-center border border-gray-200 shadow-sm`}>
        {isLoading ? (
          // Loading spinner
          <div className={`${config.spinner} border border-gray-300 border-t-transparent rounded-full animate-spin`} />
        ) : brandInfo?.logo && brandInfo.logo.trim() !== '' ? (
          // Display logo if available
          <img 
            src={brandInfo.logo} 
            alt={agencyName}
            className={`${config.logo} object-contain rounded-sm`}
            onError={(e) => {
              // Fallback to icon if logo fails to load
              e.currentTarget.style.display = 'none';
              const fallbackDiv = e.currentTarget.nextElementSibling as HTMLElement;
              if (fallbackDiv) fallbackDiv.style.display = 'flex';
            }}
          />
        ) : null}
        
        {/* Fallback icon (hidden if logo exists and loads successfully) */}
        <div 
          className={`${config.fallback} ${fallbackColor} rounded-sm flex items-center justify-center ${
            brandInfo?.logo && brandInfo.logo.trim() !== '' ? 'hidden' : 'flex'
          }`}
        >
          <span className={`text-white font-bold ${config.text}`}>{fallbackIcon}</span>
        </div>
      </div>
    </div>
  );
}