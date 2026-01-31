import { motion } from 'motion/react';
import { Heart } from 'lucide-react';
import { useState } from 'react';

export function DonationButton() {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <motion.div
      initial={{ x: 100, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      transition={{ delay: 1 }}
      className="fixed right-6 top-1/2 -translate-y-1/2 z-50"
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <a
        href="https://www.paypal.com/donate?hosted_button_id=SKTF4DM7JLV26"
        target="_blank"
        rel="noopener noreferrer"
        className="group relative block"
      >
        {/* Main button */}
        <div className="relative flex items-center gap-3 px-6 py-4 bg-gradient-to-r from-red-600 to-red-700 border border-red-500 shadow-lg hover:shadow-red-500/50 transition-all hover:scale-105">
          {/* Pulsing heart icon */}
          <Heart 
            className={`w-6 h-6 text-white transition-all ${isHovered ? 'fill-white scale-110' : ''}`} 
          />
          
          {/* Text that expands on hover */}
          <motion.span
            initial={false}
            animate={{ 
              width: isHovered ? 'auto' : 0,
              opacity: isHovered ? 1 : 0
            }}
            className="overflow-hidden whitespace-nowrap text-white uppercase tracking-wider"
          >
            Support Sentinel
          </motion.span>

          {/* Shine effect */}
          <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-700" />
        </div>

        {/* Corner accents */}
        <div className="absolute -top-1 -left-1 w-3 h-3 border-l-2 border-t-2 border-red-400" />
        <div className="absolute -bottom-1 -right-1 w-3 h-3 border-r-2 border-b-2 border-red-400" />

        {/* Glow effect */}
        <div className="absolute inset-0 -z-10 bg-red-600/30 blur-xl opacity-0 group-hover:opacity-100 transition-opacity" />
      </a>

      {/* Tooltip */}
      <motion.div
        initial={false}
        animate={{ 
          opacity: isHovered ? 1 : 0,
          x: isHovered ? -10 : 0
        }}
        className="absolute right-full top-1/2 -translate-y-1/2 mr-4 pointer-events-none"
      >
        <div className="px-4 py-2 bg-white/10 backdrop-blur-md border border-white/20 rounded text-sm text-white whitespace-nowrap">
          Help fund civilian safety
        </div>
      </motion.div>
    </motion.div>
  );
}
