interface DiemPayLogoProps {
  size?: number;
  className?: string;
}

export default function DiemPayLogo({ size = 80, className = "" }: DiemPayLogoProps) {
  return (
    <div className={`flex items-center justify-center ${className}`}>
      <svg
        width={size}
        height={size}
        viewBox="0 0 100 100"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        {/* Modern hexagonal container */}
        <path
          d="M50 5 L85 25 L85 75 L50 95 L15 75 L15 25 Z"
          fill="url(#modernGradient)"
          stroke="#000000"
          strokeWidth="1.5"
        />
        
        {/* Inner glow effect */}
        <path
          d="M50 12 L78 30 L78 70 L50 88 L22 70 L22 30 Z"
          fill="url(#innerGlow)"
          opacity="0.3"
        />
        
        {/* Letter "D" - Creative flowing design */}
        <path
          d="M28 30 L28 70 L40 70 Q58 70 58 50 Q58 30 40 30 L28 30 Z"
          fill="#FFFFFF"
          opacity="0.95"
        />
        
        {/* D - Inner cut-out with organic curves */}
        <path
          d="M35 37 L35 63 L40 63 Q51 63 51 50 Q51 37 40 37 L35 37"
          fill="url(#cutoutGradient)"
        />
        
        {/* Letter "P" - Creative angular design */}
        <path
          d="M48 30 L48 70 L55 70 L55 53 L65 53 Q75 53 75 41.5 Q75 30 65 30 L48 30 Z"
          fill="#FFFFFF"
          opacity="0.95"
        />
        
        {/* P - Inner cut-out with modern styling */}
        <path
          d="M55 37 L55 46 L65 46 Q68 46 68 41.5 Q68 37 65 37 L55 37 Z"
          fill="url(#cutoutGradient)"
        />
        
        {/* Accent elements - Modern dots */}
        <circle cx="42" cy="78" r="2" fill="#FFFFFF" opacity="0.8" />
        <circle cx="58" cy="78" r="2" fill="#FFFFFF" opacity="0.8" />
        <circle cx="50" cy="22" r="2" fill="#FFFFFF" opacity="0.8" />
        
        {/* Define gradients */}
        <defs>
          <linearGradient id="modernGradient" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#0F0F0F" />
            <stop offset="50%" stopColor="#1A1A1A" />
            <stop offset="100%" stopColor="#2D2D2D" />
          </linearGradient>
          
          <linearGradient id="innerGlow" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#FFFFFF" />
            <stop offset="100%" stopColor="#CCCCCC" />
          </linearGradient>
          
          <linearGradient id="cutoutGradient" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#1A1A1A" />
            <stop offset="100%" stopColor="#0F0F0F" />
          </linearGradient>
        </defs>
      </svg>
    </div>
  );
}