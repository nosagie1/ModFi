import { ArrowUp, ArrowDown, Users, Grid3X3 } from "lucide-react";

const actions = [
  { icon: ArrowUp, label: "Send", action: "send" },
  { icon: ArrowDown, label: "Receive", action: "receive" },
  { icon: Users, label: "Family", action: "family" },
  { icon: Grid3X3, label: "More", action: "more" },
];

export default function ActionButtons() {
  const handleAction = (action: string) => {
    // Handle action logic here
  };

  return (
    <div className="px-6 mb-8">
      <div className="flex justify-between">
        {actions.map(({ icon: Icon, label, action }) => (
          <button
            key={action}
            onClick={() => handleAction(action)}
            className="flex flex-col items-center space-y-2 hover:scale-105 transition-transform"
          >
            <div className="w-16 h-16 bg-card border border-border rounded-full flex items-center justify-center banking-shadow">
              <Icon className="w-5 h-5 text-foreground" />
            </div>
            <span className="text-foreground text-sm font-medium">{label}</span>
          </button>
        ))}
      </div>
    </div>
  );
}
