import { motion } from 'motion/react';
import { Play, FileText } from 'lucide-react';
import { AppStoreLinks } from './AppStoreLinks';
import { toast } from 'sonner@2.0.3';

export function Hero() {
  const handleUnderConstruction = () => {
    toast.error('🚧 Under Construction', {
      description: `Status as of December 30, 2025`,
      duration: 4000,
    });
  };

  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden pt-20">
      {/* Background image with overlay */}
      <div 
        className="absolute inset-0 z-0"
        style={{
          backgroundImage: 'url(https://images.unsplash.com/photo-1633421878925-ac220d8f6e4f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkaWdpdGFsJTIwbmV0d29yayUyMGdsb2JlfGVufDF8fHx8MTc2Njk2NzU0OXww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral)',
          backgroundSize: 'cover',
          backgroundPosition: 'center',
        }}
      >
        <div className="absolute inset-0 bg-gradient-to-b from-[#050505]/80 via-[#050505]/90 to-[#050505]" />
      </div>

      {/* Grid overlay for tactical feel */}
      <div className="absolute inset-0 z-0 opacity-10">
        <div className="h-full w-full" style={{
          backgroundImage: 'linear-gradient(rgba(255,255,255,.05) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.05) 1px, transparent 1px)',
          backgroundSize: '50px 50px'
        }} />
      </div>

      {/* Corner markers - tactical HUD feel */}
      <div className="absolute top-8 left-8 w-16 h-16 border-l-2 border-t-2 border-white/30 z-10" />
      <div className="absolute top-8 right-8 w-16 h-16 border-r-2 border-t-2 border-white/30 z-10" />
      <div className="absolute bottom-8 left-8 w-16 h-16 border-l-2 border-b-2 border-white/30 z-10" />
      <div className="absolute bottom-8 right-8 w-16 h-16 border-r-2 border-b-2 border-white/30 z-10" />

      {/* Content */}
      <div className="relative z-10 max-w-7xl mx-auto px-6 py-20 text-center">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="space-y-8"
        >
          {/* Brand name */}
          <div className="flex items-center justify-center gap-3 mb-6">
            <div className="w-2 h-2 bg-red-600 animate-pulse" />
            <span className="tracking-[0.3em] text-sm text-white/70 uppercase">Sentinel</span>
            <div className="w-2 h-2 bg-red-600 animate-pulse" />
          </div>

          {/* Main headline */}
          <h1 className="text-5xl md:text-7xl lg:text-8xl tracking-tight">
            The Fog of War,
            <br />
            <span className="text-white/90">Lifted.</span>
          </h1>

          {/* Sub-headline */}
          <p className="text-xl md:text-2xl text-white/80 max-w-4xl mx-auto leading-relaxed">
            Real-Time Civilian Risk Intelligence. AI-Driven. Geographically Precise.
            <br />
            <span className="text-yellow-400">The General for the Civilian Populace.</span>
          </p>

          {/* Video placeholder */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="relative max-w-5xl mx-auto mt-12 group"
          >
            {/* Glassmorphism container */}
            <div className="relative aspect-video rounded-lg overflow-hidden border border-white/10 backdrop-blur-sm bg-white/5">
              <img
                src="https://images.unsplash.com/photo-1761274441884-357dad8f28ab?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtaWxpdGFyeSUyMHRhY3RpY2FsJTIwbWFwfGVufDF8fHx8MTc2Njk2NzU0OHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
                alt="Sentinel App Interface"
                className="w-full h-full object-cover opacity-60"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#050505]/80 to-transparent" />
              
              {/* Play button overlay */}
              <div className="absolute inset-0 flex items-center justify-center">
                <button 
                  onClick={handleUnderConstruction}
                  className="relative w-20 h-20 rounded-full bg-white/10 backdrop-blur-md border border-white/20 flex items-center justify-center hover:bg-white/20 transition-all hover:scale-110"
                >
                  <Play className="w-8 h-8 text-white ml-1" fill="white" />
                  {/* Diagonal slash */}
                  <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                    <div className="w-full h-0.5 bg-white/40 rotate-[-25deg]" />
                  </div>
                </button>
              </div>

              {/* HUD elements */}
              <div className="absolute top-4 left-4 text-left text-xs">
                <div className="text-white/50">LIVE FEED</div>
                <div className="text-green-400 flex items-center gap-2 mt-1">
                  <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                  OPERATIONAL
                </div>
              </div>
            </div>

            {/* Scanning line effect */}
            <motion.div
              className="absolute inset-0 bg-gradient-to-b from-transparent via-cyan-500/20 to-transparent h-1"
              animate={{ y: [0, 400, 0] }}
              transition={{ duration: 3, repeat: Infinity, ease: "linear" }}
            />
          </motion.div>

          {/* CTA Buttons */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.4 }}
            className="flex flex-col sm:flex-row gap-4 justify-center items-center mt-12"
          >
            <button 
              onClick={handleUnderConstruction}
              className="group relative px-8 py-4 bg-red-600 text-white overflow-hidden hover:bg-red-700 transition-colors border border-red-500 min-w-[240px]"
            >
              <div className="relative z-10 flex items-center justify-center gap-2">
                <FileText className="w-5 h-5" />
                Request Pitch Deck
              </div>
              {/* Diagonal slash */}
              <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                <div className="w-full h-0.5 bg-white/40 rotate-[-25deg] scale-150" />
              </div>
              <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/10 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-700" />
            </button>

            <button className="group relative px-8 py-4 bg-white/5 text-white backdrop-blur-sm border border-white/20 hover:bg-white/10 transition-colors min-w-[240px]">
              <a 
                href="https://www.youtube.com/watch?v=paEEa6gdCc8&list=PLzHKkfEYFUZBOL_D0-doyizMuuxKFFa2z"
                target="_blank"
                rel="noopener noreferrer"
                className="relative z-10 flex items-center justify-center gap-2"
              >
                <Play className="w-5 h-5" />
                Watch Live Demo
              </a>
            </button>
          </motion.div>

          {/* Status indicator */}
          <div className="flex items-center justify-center gap-2 text-sm text-white/50 mt-8">
            <div className="w-1.5 h-1.5 bg-green-400 rounded-full animate-pulse" />
            System Status: All Systems Operational
          </div>

          {/* App Store Links */}
          <AppStoreLinks />
        </motion.div>
      </div>

      {/* Bottom gradient fade */}
      <div className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-[#050505] to-transparent z-10" />
    </section>
  );
}