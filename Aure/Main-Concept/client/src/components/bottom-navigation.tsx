import { Home, Book, User } from "lucide-react";
import { useLocation } from "wouter";

const navItems = [
  { icon: Home, label: "Home", route: "/" },
  { icon: Book, label: "Reports", route: "/reports" },
];

export default function BottomNavigation() {
  const [, setLocation] = useLocation();
  const [currentLocation] = useLocation();

  const handleNavigation = (route: string) => {
    setLocation(route);
  };

  return (
    <div className="fixed bottom-8 left-1/2 transform -translate-x-1/2">
      <div className="flex items-center space-x-4 px-6 py-3 bg-card/80 backdrop-blur-md border border-border rounded-full banking-shadow">
        {navItems.map(({ icon: Icon, label, route }) => {
          const isActive = currentLocation === route;
          return (
            <button
              key={route}
              onClick={() => handleNavigation(route)}
              className="hover:scale-105 transition-transform"
            >
              <div className={`w-14 h-14 rounded-full flex items-center justify-center transition-all duration-200 ${
                isActive 
                  ? "bg-foreground text-background" 
                  : "bg-card text-foreground hover:bg-muted"
              }`}>
                <Icon className="w-5 h-5" />
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}