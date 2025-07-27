// Brandfetch API integration for fetching agency logos and brand colors

export interface BrandData {
  name: string;
  domain: string;
  logos?: {
    theme?: string;
    type: string;
    formats: {
      src: string;
      format: string;
      background?: string;
      height?: number;
      width?: number;
      size?: number;
    }[];
  }[];
  colors?: {
    hex: string;
    type: string;
    brightness: number;
  }[];
  fonts?: {
    name: string;
    type: string;
    origin: string;
    originId: string;
  }[];
}

export interface AgencyBrandInfo {
  name: string;
  logo: string;
  icon: string;
  primaryColor: string;
  secondaryColor?: string;
  textColor: string;
}

// Agency and brand domain mapping for better API results
const AGENCY_DOMAINS: Record<string, string> = {
  // Modeling Agencies
  "Soul Artist Management": "soulartist.com",
  "Wilhelmina London": "wilhelmina.com", 
  "WHY NOT Management": "whynotmodels.com",
  "Elite Model Management": "elitemodel.com",
  "IMG Models": "imgmodels.com",
  "Ford Models": "fordmodels.com",
  "Next Management": "nextmanagement.com",
  "Storm Model Management": "stormmodels.com",
  "Premier Model Management": "premiermodelmanagement.com",
  
  // Fashion Brands
  "J.Crew": "jcrew.com",
  "SAKS": "saks.com",
  "Saks Off 5th": "saksoff5th.com",
  "Abercrombie": "abercrombie.com",
  "A&F": "abercrombie.com",
  "Everlane": "everlane.com",
  "Helmut Lang": "helmutlang.com",
  "Calvin Klein": "calvinklein.com",
  "Louis Vuitton": "louisvuitton.com",
  "L'Oréal": "loreal.com",
  "Apple": "apple.com",
  "Mitsubishi": "mitsubishi.com",
  "Nike": "nike.com",
  "Adidas": "adidas.com",
  "Zara": "zara.com",
  "H&M": "hm.com",
  "Uniqlo": "uniqlo.com",
  "Gap": "gap.com",
  "Banana Republic": "bananarepublic.com",
  "Old Navy": "oldnavy.com"
};

// Fallback brand info for agencies
const FALLBACK_BRAND_INFO: Record<string, AgencyBrandInfo> = {
  "Soul Artist Management": {
    name: "Soul Artist Management",
    logo: "",
    icon: "S",
    primaryColor: "#8B5CF6", // Purple
    secondaryColor: "#A855F7",
    textColor: "#FFFFFF"
  },
  "Wilhelmina London": {
    name: "Wilhelmina London", 
    logo: "",
    icon: "W",
    primaryColor: "#3B82F6", // Blue
    secondaryColor: "#60A5FA",
    textColor: "#FFFFFF"
  },
  "Society Management": {
    name: "Society Management",
    logo: "",
    icon: "SM", 
    primaryColor: "#10B981", // Green
    secondaryColor: "#34D399",
    textColor: "#FFFFFF"
  }
};

export class BrandfetchService {
  private apiKey: string;
  private baseUrl = "https://api.brandfetch.io/v2";
  private cache: Map<string, { data: BrandData; timestamp: number }> = new Map();
  private rateLimitDelay = 1000; // 1 second between requests
  private lastRequestTime = 0;
  private readonly cacheExpiryTime = 24 * 60 * 60 * 1000; // 24 hours

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  private async waitForRateLimit(): Promise<void> {
    const now = Date.now();
    const timeSinceLastRequest = now - this.lastRequestTime;
    
    if (timeSinceLastRequest < this.rateLimitDelay) {
      const waitTime = this.rateLimitDelay - timeSinceLastRequest;
      await new Promise(resolve => setTimeout(resolve, waitTime));
    }
    
    this.lastRequestTime = Date.now();
  }

  private isCacheValid(cacheEntry: { data: BrandData; timestamp: number }): boolean {
    return Date.now() - cacheEntry.timestamp < this.cacheExpiryTime;
  }

  async fetchBrandData(domain: string): Promise<BrandData | null> {
    // Check cache first
    const cacheKey = `brand_${domain}`;
    const cached = this.cache.get(cacheKey);
    
    if (cached && this.isCacheValid(cached)) {
      return cached.data;
    }

    try {
      // Implement rate limiting
      await this.waitForRateLimit();
      
      const response = await fetch(`${this.baseUrl}/brands/${domain}`, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        if (response.status === 429) {
          // Rate limited - return cached data if available or null
          return cached ? cached.data : null;
        }
        return null;
      }

      const data = await response.json();
      
      // Cache the successful response
      this.cache.set(cacheKey, {
        data,
        timestamp: Date.now()
      });
      
      return data;
    } catch (error) {
      // Return cached data if available on error
      return cached ? cached.data : null;
    }
  }

  async searchBrandData(query: string): Promise<BrandData | null> {
    // Check cache first
    const cacheKey = `search_${query}`;
    const cached = this.cache.get(cacheKey);
    
    if (cached && this.isCacheValid(cached)) {
      return cached.data;
    }

    try {
      // Implement rate limiting
      await this.waitForRateLimit();
      
      const response = await fetch(`${this.baseUrl}/search/${encodeURIComponent(query)}`, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        if (response.status === 429) {
          // Rate limited - return cached data if available
          return cached ? cached.data : null;
        }
        return null;
      }

      const results = await response.json();
      const result = results?.[0] || null;
      
      if (result) {
        // Cache the successful response
        this.cache.set(cacheKey, {
          data: result,
          timestamp: Date.now()
        });
      }
      
      return result;
    } catch (error) {
      // Return cached data if available on error
      return cached ? cached.data : null;
    }
  }

  async getAgencyBrandInfo(agencyName: string): Promise<AgencyBrandInfo> {
    // Special handling for Soul Artist Management - use search instead of domain
    if (agencyName === "Soul Artist Management") {
      const searchResult = await this.searchBrandData("Soul Artist Management");
      if (searchResult) {
        return this.extractBrandInfo(searchResult, agencyName);
      }
    }
    
    // Get domain for the agency
    const domain = AGENCY_DOMAINS[agencyName];
    
    if (!domain) {
      // Return fallback if no domain mapping
      return FALLBACK_BRAND_INFO[agencyName] || {
        name: agencyName,
        logo: "",
        icon: agencyName.charAt(0),
        primaryColor: "#6B7280",
        textColor: "#FFFFFF"
      };
    }

    // Fetch brand data from Brandfetch
    const brandData = await this.fetchBrandData(domain);
    
    if (!brandData) {
      // Return fallback if API fails
      return FALLBACK_BRAND_INFO[agencyName] || {
        name: agencyName,
        logo: "",
        icon: agencyName.charAt(0),
        primaryColor: "#6B7280", 
        textColor: "#FFFFFF"
      };
    }

    return this.extractBrandInfo(brandData, agencyName);
  }

  private extractBrandInfo(brandData: BrandData, agencyName: string): AgencyBrandInfo {
    // Extract brand information (prioritize PNG/JPEG over SVG for better compatibility)
    const logos = (brandData as any).logos || [];
    const logoItem = logos.find((l: any) => l.type === 'logo') || 
                     logos.find((l: any) => l.type === 'symbol') || 
                     logos[0];
    
    const iconItem = logos.find((l: any) => l.type === 'icon') || 
                     logos.find((l: any) => l.type === 'symbol');
    
    // Prefer PNG/JPEG formats for better browser compatibility
    const logo = logoItem?.formats?.find((f: any) => f.format === 'png' || f.format === 'jpeg')?.src ||
                 logoItem?.formats?.[0]?.src || "";
                 
    const icon = iconItem?.formats?.find((f: any) => f.format === 'png' || f.format === 'jpeg')?.src ||
                 iconItem?.formats?.[0]?.src || "";
    
    // Extract primary color
    let primaryColor = "#6B7280"; // Default gray
    let secondaryColor = undefined;
    
    if (brandData.colors && brandData.colors.length > 0) {
      // Sort colors by brightness to get primary and secondary
      const sortedColors = brandData.colors
        .filter(color => color.hex)
        .sort((a, b) => b.brightness - a.brightness);
      
      primaryColor = sortedColors[0]?.hex || primaryColor;
      secondaryColor = sortedColors[1]?.hex;
    }

    // Determine text color based on primary color brightness
    const textColor = this.getContrastTextColor(primaryColor);

    return {
      name: brandData.name || agencyName,
      logo,
      icon: icon || agencyName.charAt(0),
      primaryColor,
      secondaryColor,
      textColor
    };
  }

  private getContrastTextColor(hexColor: string): string {
    // Remove # if present
    const hex = hexColor.replace('#', '');
    
    // Convert to RGB
    const r = parseInt(hex.substr(0, 2), 16);
    const g = parseInt(hex.substr(2, 2), 16);
    const b = parseInt(hex.substr(4, 2), 16);
    
    // Calculate luminance
    const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    
    // Return white for dark colors, black for light colors
    return luminance > 0.5 ? '#000000' : '#FFFFFF';
  }
}

// Export a factory function to create the service
export function createBrandfetchService(): BrandfetchService | null {
  const apiKey = process.env.BRANDFETCH_API_KEY;
  
  if (!apiKey) {
    console.warn('BRANDFETCH_API_KEY not found in environment variables');
    return null;
  }
  
  return new BrandfetchService(apiKey);
}