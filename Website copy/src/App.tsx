import { Hero } from './components/Hero';
import { Problem } from './components/Problem';
import { Solution } from './components/Solution';
import { OriginStory } from './components/OriginStory';
import { MarketOpportunity } from './components/MarketOpportunity';
import { LiveThreatIntelligence } from './components/LiveThreatIntelligence';
import { InvestorAccess } from './components/InvestorAccess';
import { SystemStatus } from './components/SystemStatus';
import { Header } from './components/Header';
import { DonationButton } from './components/DonationButton';
import { AboutUs } from './components/AboutUs';
import { Toaster } from 'sonner@2.0.3';

export default function App() {
  return (
    <div className="bg-[#050505] min-h-screen text-white">
      <Toaster position="top-center" theme="dark" />
      <Header />
      <DonationButton />
      <div id="hero">
        <Hero />
      </div>
      <SystemStatus />
      <div id="about">
        <AboutUs />
      </div>
      <div id="mission">
        <Problem />
      </div>
      <div id="solution">
        <Solution />
      </div>
      <OriginStory />
      <MarketOpportunity />
      <div id="intel">
        <LiveThreatIntelligence />
      </div>
      <div id="investors">
        <InvestorAccess />
      </div>
      
      {/* Footer with last updated */}
      <footer className="border-t border-white/10 py-6 text-center text-xs text-white/40">
        <div className="max-w-7xl mx-auto px-6">
          Last Updated: December 30, 2025
        </div>
      </footer>
    </div>
  );
}