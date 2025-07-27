import { useQuery } from "@tanstack/react-query";
import type { AgencyBrandInfo } from "@shared/brandfetch";

export function useAgencyBrand(agencyName: string) {
  return useQuery<AgencyBrandInfo>({
    queryKey: ["/api/agency-brand", agencyName],
    queryFn: async () => {
      const response = await fetch(`/api/agency-brand/${encodeURIComponent(agencyName)}`);
      if (!response.ok) {
        throw new Error(`Failed to fetch brand info for ${agencyName}`);
      }
      return response.json();
    },
    enabled: !!agencyName,
    staleTime: 1000 * 60 * 60, // Cache for 1 hour
    retry: 1, // Only retry once on failure
    refetchOnWindowFocus: false, // Don't refetch on window focus
  });
}

// Hook to get multiple agency brands at once
export function useMultipleAgencyBrands(agencyNames: string[]) {
  const queries = agencyNames.map(name => ({
    queryKey: ["/api/agency-brand", name],
    enabled: !!name,
    staleTime: 1000 * 60 * 60,
    retry: 1,
    refetchOnWindowFocus: false,
  }));

  const results = useQuery({
    queryKey: ["agency-brands-batch", agencyNames],
    queryFn: async () => {
      const brandPromises = agencyNames.map(async (name) => {
        const response = await fetch(`/api/agency-brand/${encodeURIComponent(name)}`);
        if (!response.ok) throw new Error(`Failed to fetch brand for ${name}`);
        return response.json() as Promise<AgencyBrandInfo>;
      });
      
      const brands = await Promise.all(brandPromises);
      return agencyNames.reduce((acc, name, index) => {
        acc[name] = brands[index];
        return acc;
      }, {} as Record<string, AgencyBrandInfo>);
    },
    enabled: agencyNames.length > 0,
    staleTime: 1000 * 60 * 60,
    retry: 1,
    refetchOnWindowFocus: false,
  });

  return results;
}