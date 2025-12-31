import { motion } from 'motion/react';
import sentinelLogo from 'figma:asset/c0ec0c1eca1674538074e27f27da4ae9f4225cde.png';

export function Header() {
  const handleNavClick = (e: React.MouseEvent<HTMLAnchorElement>, targetId: string) => {
    e.preventDefault();
    const element = document.querySelector(targetId);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  };

  return (
    <motion.header
      initial={{ y: -100 }}
      animate={{ y: 0 }}
      className="fixed top-0 left-0 right-0 z-50 border-b border-white/10 bg-[#050505]/95 backdrop-blur-md"
    >
      <div className="max-w-7xl mx-auto px-6 py-4">
        <div className="flex items-center justify-between">
          {/* Logo */}
          <a 
            href="#hero" 
            onClick={(e) => handleNavClick(e, '#hero')}
            className="flex items-center gap-4 group"
          >
            <img 
              src={sentinelLogo} 
              alt="Sentinel Logo" 
              className="w-12 h-12 object-contain group-hover:scale-110 transition-transform"
            />
            <div>
              <div className="text-xl tracking-wider text-white">SENTINEL</div>
              <div className="text-xs text-white/50 tracking-widest">DEFENSE TECHNOLOGIES</div>
            </div>
          </a>

          {/* Navigation */}
          <nav className="hidden md:flex items-center gap-8">
            <a 
              href="#about" 
              onClick={(e) => handleNavClick(e, '#about')}
              className="text-sm text-white/70 hover:text-white transition-colors uppercase tracking-wider"
            >
              About
            </a>
            <a 
              href="#mission" 
              onClick={(e) => handleNavClick(e, '#mission')}
              className="text-sm text-white/70 hover:text-white transition-colors uppercase tracking-wider"
            >
              Mission
            </a>
            <a 
              href="#solution" 
              onClick={(e) => handleNavClick(e, '#solution')}
              className="text-sm text-white/70 hover:text-white transition-colors uppercase tracking-wider"
            >
              Technology
            </a>
            <a 
              href="#intel" 
              onClick={(e) => handleNavClick(e, '#intel')}
              className="text-sm text-white/70 hover:text-white transition-colors uppercase tracking-wider"
            >
              Intelligence
            </a>
            <a 
              href="#investors" 
              onClick={(e) => handleNavClick(e, '#investors')}
              className="text-sm text-white/70 hover:text-white transition-colors uppercase tracking-wider"
            >
              Investors
            </a>
            <a 
              href="mailto:PeterJFrancoIII@gmail.com" 
              className="px-4 py-2 border border-cyan-600/50 text-cyan-400 hover:bg-cyan-600/20 transition-colors text-sm uppercase tracking-wider"
            >
              Contact
            </a>
            <a 
              href="https://www.paypal.com/donate?hosted_button_id=SKTF4DM7JLV26"
              target="_blank"
              rel="noopener noreferrer"
              className="px-4 py-2 border border-red-600/50 bg-red-600/10 text-red-400 hover:bg-red-600/30 transition-colors text-sm uppercase tracking-wider"
            >
              Donate
            </a>
          </nav>
        </div>
      </div>
    </motion.header>
  );
}