import { motion } from 'motion/react';
import { Activity, Database, MapPin, Zap } from 'lucide-react';
import { useEffect, useState } from 'react';

export function SystemStatus() {
  const [activeCount, setActiveCount] = useState(7942);

  useEffect(() => {
    const interval = setInterval(() => {
      setActiveCount(prev => prev + Math.floor(Math.random() * 3));
    }, 5000);
    return () => clearInterval(interval);
  }, []);

  return (
    <section className="relative py-16 border-y border-white/10">
      <div className="max-w-7xl mx-auto px-6">
        {/* Status header */}
        <div className="flex flex-col md:flex-row items-center justify-between gap-6 mb-8">
          <div className="flex items-center gap-3">
            <div className="w-3 h-3 bg-green-400 rounded-full animate-pulse" />
            <span className="text-xl text-green-400">SYSTEM STATUS: OPERATIONAL</span>
          </div>
          <div className="text-sm text-white/50">
            Last Updated: {new Date().toLocaleString('en-US', { 
              month: 'short', 
              day: 'numeric', 
              year: 'numeric',
              hour: '2-digit', 
              minute: '2-digit',
              second: '2-digit'
            })} UTC
          </div>
        </div>

        {/* Metrics grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <MetricCard
            icon={<MapPin className="w-5 h-5" />}
            label="Active Monitored Sectors"
            value={activeCount.toLocaleString()}
            status="operational"
          />
          <MetricCard
            icon={<Database className="w-5 h-5" />}
            label="Data Points Processed Today"
            value="2.9M+"
            status="operational"
          />
          <MetricCard
            icon={<Zap className="w-5 h-5" />}
            label="Average Alert Speed"
            value="< 30s"
            status="optimal"
          />
          <MetricCard
            icon={<Activity className="w-5 h-5" />}
            label="System Uptime"
            value="99.97%"
            status="operational"
          />
        </div>
      </div>
    </section>
  );
}

function MetricCard({ 
  icon, 
  label, 
  value, 
  status 
}: { 
  icon: React.ReactNode; 
  label: string; 
  value: string; 
  status: 'operational' | 'optimal';
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      className="relative group"
    >
      {/* Glassmorphism card */}
      <div className="relative p-6 rounded-lg border border-white/10 bg-white/5 backdrop-blur-sm hover:bg-white/10 transition-all">
        {/* Corner accent */}
        <div className="absolute top-0 right-0 w-8 h-8 border-r border-t border-cyan-500/30" />
        
        <div className="flex items-center gap-3 mb-3 text-white/70">
          {icon}
          <span className="text-xs uppercase tracking-wider">{label}</span>
        </div>
        
        <div className="text-3xl text-white mb-2">{value}</div>
        
        <div className={`text-xs uppercase tracking-wider ${
          status === 'optimal' ? 'text-cyan-400' : 'text-green-400'
        }`}>
          {status}
        </div>
      </div>
    </motion.div>
  );
}
