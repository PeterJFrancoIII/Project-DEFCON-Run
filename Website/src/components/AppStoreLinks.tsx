import { motion } from 'motion/react';
import { Apple, Smartphone } from 'lucide-react';
import sentinelLogo from 'figma:asset/c0ec0c1eca1674538074e27f27da4ae9f4225cde.png';

export function AppStoreLinks() {
  const handleAppStoreClick = () => {
    alert('Apple App Store link coming soon. Sentinel is currently in development.');
  };

  const handlePlayStoreClick = () => {
    alert('Google Play Store link coming soon. Sentinel is currently in development.');
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 30 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      className="flex flex-col sm:flex-row items-center justify-center gap-4 mt-12"
    >
      {/* Apple App Store */}
      <button
        onClick={handleAppStoreClick}
        className="group relative w-full sm:w-auto cursor-pointer"
      >
        <div className="flex items-center gap-4 px-6 py-4 bg-white/5 backdrop-blur-sm border border-white/20 hover:bg-white/10 transition-all hover:scale-105 min-w-[220px]">
          {/* App icon */}
          <div className="relative w-12 h-12 rounded-lg overflow-hidden border border-white/20 flex-shrink-0">
            <img 
              src={sentinelLogo} 
              alt="Sentinel App Icon" 
              className="w-full h-full object-cover"
            />
          </div>
          
          <div className="text-left flex-1">
            <div className="text-xs text-white/60">Download on the</div>
            <div className="text-lg text-white flex items-center gap-2">
              <Apple className="w-5 h-5" />
              App Store
            </div>
          </div>

          {/* Corner accent */}
          <div className="absolute top-0 right-0 w-6 h-6 border-r border-t border-cyan-500/30" />
        </div>
      </button>

      {/* Google Play Store */}
      <button
        onClick={handlePlayStoreClick}
        className="group relative w-full sm:w-auto cursor-pointer"
      >
        <div className="flex items-center gap-4 px-6 py-4 bg-white/5 backdrop-blur-sm border border-white/20 hover:bg-white/10 transition-all hover:scale-105 min-w-[220px]">
          {/* App icon */}
          <div className="relative w-12 h-12 rounded-lg overflow-hidden border border-white/20 flex-shrink-0">
            <img 
              src={sentinelLogo} 
              alt="Sentinel App Icon" 
              className="w-full h-full object-cover"
            />
          </div>
          
          <div className="text-left flex-1">
            <div className="text-xs text-white/60">Get it on</div>
            <div className="text-lg text-white flex items-center gap-2">
              <Smartphone className="w-5 h-5" />
              Google Play
            </div>
          </div>

          {/* Corner accent */}
          <div className="absolute top-0 right-0 w-6 h-6 border-r border-t border-cyan-500/30" />
        </div>
      </button>
    </motion.div>
  );
}