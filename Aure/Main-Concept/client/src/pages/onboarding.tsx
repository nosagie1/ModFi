import { useState, useRef, useCallback } from "react";
import { useLocation } from "wouter";
import { Button } from "@/components/ui/button";
import { ChevronLeft, ChevronRight, ArrowLeft } from "lucide-react";

interface OnboardingSlide {
  id: number;
  title: string;
  description: string;
  illustration: JSX.Element;
}

const slides: OnboardingSlide[] = [
  {
    id: 1,
    title: "Track your modeling career",
    description: "Manage earnings from multiple agencies, track payments, and grow your fashion career with smart financial tools trusted by models worldwide.",
    illustration: (
      <div className="relative w-full h-80 flex items-center justify-center">
        {/* Floating 3D Elements */}
        <div className="relative">
          {/* Job tracking cards stack - top left */}
          <div className="absolute -top-8 -left-12 transform rotate-12">
            <div className="w-16 h-12 bg-gradient-to-br from-purple-500 to-purple-700 rounded-lg shadow-2xl transform rotate-3 flex items-center justify-center">
              <div className="text-white text-xs font-bold">Jobs</div>
            </div>
            <div className="absolute top-1 left-1 w-16 h-12 bg-gradient-to-br from-blue-500 to-blue-700 rounded-lg shadow-xl transform rotate-6 flex items-center justify-center">
              <div className="text-white text-xs font-bold">25</div>
            </div>
            <div className="absolute top-2 left-2 w-16 h-12 bg-gradient-to-br from-green-500 to-green-700 rounded-lg shadow-lg transform rotate-9 flex items-center justify-center">
              <div className="text-white text-xs font-bold">Track</div>
            </div>
          </div>
          
          {/* Modeling portfolio coin - top right */}
          <div className="absolute -top-4 right-8 w-20 h-20 bg-gradient-to-br from-pink-400 via-purple-500 to-purple-700 rounded-full shadow-2xl flex items-center justify-center transform rotate-12 animate-pulse">
            <div className="text-white text-lg font-bold">👤</div>
          </div>
          
          {/* Career progress crystal - center */}
          <div className="absolute top-8 left-4 w-24 h-16 bg-gradient-to-br from-gray-100 to-white rounded-2xl shadow-2xl transform -rotate-12 flex items-center justify-center">
            <div className="w-8 h-8 bg-gradient-to-br from-green-400 to-emerald-600 transform rotate-45 rounded flex items-center justify-center">
              <div className="text-white text-xs font-bold transform -rotate-45">↗</div>
            </div>
          </div>
          
          {/* Agency connection sphere - bottom left */}
          <div className="absolute bottom-4 -left-8 w-16 h-16 bg-gradient-to-br from-orange-400 to-red-500 rounded-full shadow-2xl flex items-center justify-center">
            <div className="text-white text-sm font-bold">3</div>
          </div>
          
          {/* Earnings coin - center bottom */}
          <div className="absolute bottom-0 right-0 w-18 h-18 bg-gradient-to-br from-emerald-400 to-green-600 rounded-full shadow-2xl flex items-center justify-center">
            <div className="text-white text-lg font-bold">$</div>
          </div>
          
          {/* Fashion industry star - bottom right */}
          <div className="absolute -bottom-4 right-12 w-14 h-14 bg-gradient-to-br from-yellow-400 to-amber-600 rounded-full shadow-xl flex items-center justify-center transform rotate-45">
            <div className="text-white text-sm font-bold">✨</div>
          </div>
        </div>
      </div>
    )
  },
  {
    id: 2,
    title: "Earn from multiple agencies",
    description: "Track payments and commissions from all your modeling agencies. Get insights on agency performance and optimize your career earnings.",
    illustration: (
      <div className="relative w-full h-80 flex items-center justify-center">
        {/* Floating 3D Agency Elements */}
        <div className="relative">
          {/* Soul Artist agency building - top left */}
          <div className="absolute -top-6 left-4 w-20 h-20 bg-gradient-to-br from-purple-500 to-purple-700 rounded-2xl shadow-2xl flex items-center justify-center transform -rotate-12">
            <div className="text-white text-lg font-bold">S</div>
            <div className="absolute -bottom-2 -right-2 bg-green-500 text-white px-1 py-0.5 rounded text-xs">60%</div>
          </div>
          
          {/* Wilhelmina commission crystal - top right */}
          <div className="absolute top-8 -right-8 transform rotate-45">
            <div className="w-16 h-16 bg-gradient-to-br from-green-400 to-emerald-600 rounded-lg shadow-2xl"></div>
            <div className="absolute inset-2 bg-gradient-to-br from-white to-gray-100 rounded flex items-center justify-center transform -rotate-45">
              <div className="text-green-600 text-sm font-bold">W</div>
            </div>
            <div className="absolute -top-2 -left-2 bg-blue-600 text-white px-1 py-0.5 rounded text-xs transform -rotate-45">28%</div>
          </div>
          
          {/* WHY NOT payment sphere - bottom left */}
          <div className="absolute bottom-8 left-8 w-18 h-18 bg-gradient-to-br from-blue-400 to-blue-600 rounded-full shadow-2xl relative overflow-hidden">
            <div className="absolute inset-0 bg-gradient-to-br from-transparent to-blue-800 opacity-30"></div>
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="text-white text-sm font-bold">WN</div>
            </div>
            <div className="absolute -bottom-1 -right-1 bg-orange-500 text-white px-1 py-0.5 rounded text-xs">12%</div>
          </div>
          
          {/* Payment flow indicator - center right */}
          <div className="absolute top-4 right-4 w-14 h-14 bg-gradient-to-br from-emerald-400 to-green-600 rounded-full shadow-xl animate-bounce flex items-center justify-center">
            <div className="text-white text-xs font-bold">💰</div>
          </div>
          
          {/* Commission tracking card - bottom right */}
          <div className="absolute bottom-4 -right-4 w-16 h-12 bg-gradient-to-br from-gray-100 to-white rounded-2xl shadow-2xl transform rotate-12 flex items-center justify-center">
            <div className="text-gray-600 text-xs font-bold">Track</div>
          </div>
          
          {/* Earnings growth indicator - small accent */}
          <div className="absolute -bottom-2 left-16 w-12 h-12 bg-gradient-to-br from-yellow-400 to-amber-600 rounded-full shadow-xl flex items-center justify-center">
            <div className="text-white text-xs font-bold">+</div>
          </div>
        </div>
      </div>
    )
  },
  {
    id: 3,
    title: "Career insights by our experts",
    description: "Get personalized advice on agency selection, payment optimization, and career growth strategies from industry professionals.",
    illustration: (
      <div className="relative w-full h-80 flex items-center justify-center">
        {/* Floating 3D Insights Elements */}
        <div className="relative">
          {/* Career growth chart - top left */}
          <div className="absolute -top-4 left-8 transform -rotate-12">
            <div className="w-20 h-16 bg-gradient-to-br from-emerald-400 to-green-600 rounded-xl shadow-2xl relative overflow-hidden">
              <div className="absolute bottom-0 left-2 w-2 h-4 bg-white rounded-t"></div>
              <div className="absolute bottom-0 left-6 w-2 h-8 bg-white rounded-t"></div>
              <div className="absolute bottom-0 left-10 w-2 h-12 bg-white rounded-t"></div>
              <div className="absolute bottom-0 left-14 w-2 h-10 bg-white rounded-t"></div>
            </div>
            <div className="absolute -top-2 -right-2 bg-gray-800 text-white px-2 py-1 rounded text-xs font-bold">
              Career ↗
            </div>
          </div>
          
          {/* Industry expert advisor - top right */}
          <div className="absolute top-12 -right-8 w-18 h-18 bg-gradient-to-br from-purple-500 to-indigo-600 rounded-full shadow-2xl flex items-center justify-center animate-pulse">
            <div className="text-white text-lg font-bold">👨‍💼</div>
          </div>
          
          {/* Agency performance ring - bottom left */}
          <div className="absolute bottom-8 left-4 w-16 h-16 relative">
            <div className="w-full h-full bg-gradient-to-br from-blue-400 to-blue-600 rounded-full shadow-2xl"></div>
            <div className="absolute inset-3 bg-white rounded-full flex items-center justify-center">
              <div className="text-blue-600 text-xs font-bold">Top</div>
            </div>
          </div>
          
          {/* Personalized advice card - center right */}
          <div className="absolute top-4 right-4 transform rotate-12">
            <div className="w-14 h-10 bg-gradient-to-br from-amber-400 to-orange-500 rounded-lg shadow-xl flex items-center justify-center">
              <div className="text-white text-xs font-bold">Advice</div>
            </div>
          </div>
          
          {/* Strategy crystal - bottom right */}
          <div className="absolute -bottom-2 right-8 w-12 h-16 bg-gradient-to-br from-gray-100 to-white rounded-t-2xl shadow-2xl transform rotate-45 flex items-center justify-center">
            <div className="w-4 h-4 bg-gradient-to-br from-purple-400 to-pink-500 rounded transform -rotate-45"></div>
          </div>
          
          {/* Optimization indicator - small accent */}
          <div className="absolute bottom-4 -right-4 w-10 h-10 bg-gradient-to-br from-green-400 to-emerald-500 rounded-full shadow-xl flex items-center justify-center">
            <div className="text-white text-xs font-bold">⚡</div>
          </div>
        </div>
      </div>
    )
  },
  {
    id: 4,
    title: "Build your career with smart tools",
    description: "Track jobs, monitor payments, analyze trends. No hidden fees, no commission caps, and complete transparency in your modeling finances.",
    illustration: (
      <div className="relative w-full h-80 flex items-center justify-center">
        {/* Floating 3D Tools Elements */}
        <div className="relative">
          {/* Smart analytics cube - center */}
          <div className="absolute top-8 left-8 transform -rotate-12">
            <div className="w-20 h-20 bg-gradient-to-br from-gray-100 to-white rounded-2xl shadow-2xl relative">
              <div className="absolute inset-2 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center">
                <div className="text-white text-sm font-bold">📈</div>
              </div>
            </div>
          </div>
          
          {/* Payment monitoring stack - top left */}
          <div className="absolute -top-6 -left-4 transform rotate-15">
            <div className="w-16 h-4 bg-gradient-to-r from-emerald-400 to-green-600 rounded shadow-xl flex items-center justify-center">
              <div className="text-white text-xs font-bold">Pay</div>
            </div>
            <div className="w-16 h-4 bg-gradient-to-r from-blue-300 to-blue-500 rounded shadow-lg transform translate-y-1 flex items-center justify-center">
              <div className="text-white text-xs font-bold">Track</div>
            </div>
            <div className="w-16 h-4 bg-gradient-to-r from-purple-200 to-purple-400 rounded shadow-md transform translate-y-2 flex items-center justify-center">
              <div className="text-white text-xs font-bold">Jobs</div>
            </div>
          </div>
          
          {/* Smart tools indicator - top right */}
          <div className="absolute -top-4 right-4 w-18 h-18 bg-gradient-to-br from-indigo-400 to-purple-600 rounded-full shadow-2xl flex items-center justify-center animate-pulse">
            <div className="text-white text-lg font-bold">🔧</div>
          </div>
          
          {/* Transparency guarantee - bottom right */}
          <div className="absolute bottom-6 -right-8 transform rotate-45">
            <div className="w-14 h-14 bg-gradient-to-br from-emerald-500 to-green-600 rounded-lg shadow-2xl"></div>
            <div className="absolute inset-2 bg-gradient-to-br from-white to-gray-100 rounded transform -rotate-45 flex items-center justify-center">
              <div className="text-green-600 text-xs font-bold">✓</div>
            </div>
          </div>
          
          {/* No fees sphere - bottom left */}
          <div className="absolute bottom-4 left-4 w-16 h-16 bg-gradient-to-br from-cyan-400 to-blue-600 rounded-full shadow-2xl flex items-center justify-center">
            <div className="text-white text-sm font-bold">Free</div>
          </div>
          
          {/* Smart automation indicator - center right */}
          <div className="absolute top-4 right-12 w-8 h-8 bg-gradient-to-br from-amber-400 to-orange-500 rounded-full shadow-lg animate-bounce flex items-center justify-center">
            <div className="text-white text-xs font-bold">AI</div>
          </div>
          
          {/* Complete solution badge - bottom center */}
          <div className="absolute -bottom-2 left-16 w-12 h-8 bg-gradient-to-br from-gray-100 to-white rounded-xl shadow-xl transform -rotate-12 flex items-center justify-center">
            <div className="text-gray-600 text-xs font-bold">All-in-1</div>
          </div>
        </div>
      </div>
    )
  }
];

export default function OnboardingPage() {
  const [currentSlide, setCurrentSlide] = useState(0);
  const [, setLocation] = useLocation();
  const touchStartX = useRef<number>(0);
  const touchEndX = useRef<number>(0);

  const nextSlide = () => {
    if (currentSlide < slides.length - 1) {
      setCurrentSlide(currentSlide + 1);
    }
  };

  const prevSlide = () => {
    if (currentSlide > 0) {
      setCurrentSlide(currentSlide - 1);
    }
  };

  const goToSlide = (index: number) => {
    setCurrentSlide(index);
  };

  const handleSignUp = () => {
    setLocation("/signup");
  };

  const handleLogin = () => {
    setLocation("/login");
  };

  // Touch event handlers for swipe functionality
  const handleTouchStart = useCallback((e: React.TouchEvent) => {
    touchStartX.current = e.touches[0].clientX;
  }, []);

  const handleTouchMove = useCallback((e: React.TouchEvent) => {
    touchEndX.current = e.touches[0].clientX;
  }, []);

  const handleTouchEnd = useCallback(() => {
    const deltaX = touchStartX.current - touchEndX.current;
    const minSwipeDistance = 50;

    if (Math.abs(deltaX) > minSwipeDistance) {
      if (deltaX > 0 && currentSlide < slides.length - 1) {
        // Swipe left - go to next slide
        nextSlide();
      } else if (deltaX < 0 && currentSlide > 0) {
        // Swipe right - go to previous slide
        prevSlide();
      }
    }
  }, [currentSlide]);

  return (
    <div className="min-h-screen bg-white flex flex-col">
      {/* Status Bar with Back Button */}
      <div className="flex items-center justify-between px-6 pt-4 pb-2">
        <div className="flex items-center space-x-4">
          <button 
            onClick={currentSlide === 0 ? () => setLocation("/login") : prevSlide}
            className="p-1 hover:bg-gray-100 rounded-full transition-colors"
          >
            <ArrowLeft className="h-5 w-5 text-gray-600" />
          </button>
          <div className="text-sm font-semibold">09:41</div>
        </div>
        <div className="flex items-center space-x-1">
          <div className="flex space-x-1">
            <div className="w-1 h-3 bg-black rounded-full"></div>
            <div className="w-1 h-3 bg-black rounded-full"></div>
            <div className="w-1 h-3 bg-black rounded-full"></div>
            <div className="w-1 h-3 bg-gray-300 rounded-full"></div>
          </div>
          <div className="ml-2 flex space-x-1">
            <div className="w-4 h-2 border border-black rounded-sm">
              <div className="w-full h-full bg-black rounded-sm"></div>
            </div>
          </div>
        </div>
      </div>

      {/* Back Button */}
      <div className="px-6 py-2">
        <button
          onClick={() => setLocation("/")}
          className="flex items-center space-x-2 text-gray-600 hover:text-gray-900 transition-colors"
        >
          <ArrowLeft className="w-5 h-5" />
          <span className="text-sm font-medium">Back to splash</span>
        </button>
      </div>

      {/* Main Content */}
      <div 
        className="flex-1 flex flex-col px-6"
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
      >
        {/* Slide Content */}
        <div className="flex-1 flex flex-col justify-center">
          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold text-gray-900 mb-4 leading-tight">
              {slides[currentSlide].title}
            </h1>
            <p className="text-gray-600 text-base leading-relaxed px-4">
              {slides[currentSlide].description}
            </p>
          </div>

          {/* Illustration */}
          <div className="flex-1 flex items-center justify-center min-h-[320px]">
            {slides[currentSlide].illustration}
          </div>
        </div>

        {/* Dots Indicator */}
        <div className="flex justify-center space-x-2 mb-8">
          {slides.map((_, index) => (
            <button
              key={index}
              onClick={() => goToSlide(index)}
              className={`w-2 h-2 rounded-full transition-colors ${
                index === currentSlide ? "bg-black" : "bg-gray-300"
              }`}
            />
          ))}
        </div>

        {/* Navigation Buttons */}
        <div className="space-y-3 mb-8">
          <Button
            onClick={handleSignUp}
            className="w-full bg-gray-900 hover:bg-gray-800 text-white font-semibold py-4 rounded-full"
          >
            Sign up
          </Button>
          <Button
            onClick={handleLogin}
            variant="outline"
            className="w-full border-gray-900 text-gray-900 hover:bg-gray-50 font-semibold py-4 rounded-full"
          >
            Log in
          </Button>
        </div>

        {/* Footer */}
        <div className="flex items-center justify-center space-x-2 text-xs text-gray-500 mb-6">
          <div className="flex items-center space-x-1">
            <div className="w-4 h-4 bg-gray-900 rounded flex items-center justify-center">
              <span className="text-white font-bold text-xs">M</span>
            </div>
            <span className="font-semibold">ModelFinance</span>
          </div>
          <span>curated by</span>
          <div className="flex items-center space-x-1">
            <div className="w-4 h-4 bg-gray-700 rounded flex items-center justify-center">
              <span className="text-white font-bold text-xs">R</span>
            </div>
            <span className="font-semibold">Replit</span>
          </div>
        </div>

        {/* Home Indicator */}
        <div className="flex justify-center mb-4">
          <div className="w-32 h-1 bg-black rounded-full"></div>
        </div>
      </div>

      {/* Navigation Arrows (Optional, hidden for mobile) */}
      {currentSlide > 0 && (
        <button
          onClick={prevSlide}
          className="absolute left-4 top-1/2 transform -translate-y-1/2 w-12 h-12 bg-white rounded-full shadow-xl flex items-center justify-center opacity-80 hover:opacity-100 transition-all duration-200 hidden md:flex border border-gray-200 hover:shadow-2xl"
        >
          <ChevronLeft className="w-6 h-6 text-gray-700" />
        </button>
      )}
      
      {currentSlide < slides.length - 1 && (
        <button
          onClick={nextSlide}
          className="absolute right-4 top-1/2 transform -translate-y-1/2 w-12 h-12 bg-white rounded-full shadow-xl flex items-center justify-center opacity-80 hover:opacity-100 transition-all duration-200 hidden md:flex border border-gray-200 hover:shadow-2xl"
        >
          <ChevronRight className="w-6 h-6 text-gray-700" />
        </button>
      )}
    </div>
  );
}