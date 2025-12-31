import { motion } from 'motion/react';
import { Radio, MapPin, Clock } from 'lucide-react';
import { useState, useEffect } from 'react';

const SITREPS = [
  {
    id: 'SITREP-001',
    sector: 'Sector 4-Alpha',
    threat: 'Artillery Activity Detected',
    severity: 'high',
    location: 'Northern Corridor, 12.4km radius',
    timestamp: '14 mins ago',
    status: 'Monitoring'
  },
  {
    id: 'SITREP-002',
    sector: 'Border Region 7',
    threat: 'Mobilization Confirmed',
    severity: 'critical',
    location: 'Eastern Border Zone',
    timestamp: '28 mins ago',
    status: 'Active'
  },
  {
    id: 'SITREP-003',
    sector: 'Urban Sector 2-B',
    threat: 'Heightened Security Presence',
    severity: 'medium',
    location: 'Metropolitan District',
    timestamp: '1 hour ago',
    status: 'Resolved'
  },
  {
    id: 'SITREP-004',
    sector: 'Coastal Sector 9',
    threat: 'Naval Activity Increase',
    severity: 'high',
    location: 'Maritime Zone Alpha',
    timestamp: '2 hours ago',
    status: 'Monitoring'
  },
  {
    id: 'SITREP-005',
    sector: 'Sector 3-Charlie',
    threat: 'Communication Disruption',
    severity: 'medium',
    location: 'Rural Communications Hub',
    timestamp: '3 hours ago',
    status: 'Investigating'
  },
  {
    id: 'SITREP-006',
    sector: 'Border Region 5',
    threat: 'Elevated Alert Status',
    severity: 'high',
    location: 'Western Border Crossing',
    timestamp: '4 hours ago',
    status: 'Monitoring'
  }
];

export function LiveThreatIntelligence() {
  const [currentTime, setCurrentTime] = useState(new Date());

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <section className="relative py-32 overflow-hidden">
      {/* Animated background grid */}
      <div className="absolute inset-0 opacity-5">
        <div className="h-full w-full" style={{
          backgroundImage: 'linear-gradient(rgba(255,255,255,.1) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.1) 1px, transparent 1px)',
          backgroundSize: '50px 50px'
        }} />
      </div>

      <div className="relative max-w-7xl mx-auto px-6">
        {/* Section header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mb-12"
        >
          <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-6 mb-8">
            <div>
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-red-600/30 bg-red-600/10 mb-4">
                <Radio className="w-4 h-4 text-red-400" />
                <span className="text-sm uppercase tracking-wider text-red-400">Live Intelligence Feed</span>
              </div>
              
              <h2 className="text-4xl md:text-6xl">
                Active Threat
                <br />
                <span className="text-red-500">Intelligence.</span>
              </h2>
            </div>

            {/* Live clock */}
            <div className="p-6 rounded-lg border border-white/10 bg-white/5 backdrop-blur-sm">
              <div className="text-xs text-white/50 mb-1">SYSTEM TIME (UTC)</div>
              <div className="text-2xl font-mono text-green-400 flex items-center gap-2">
                <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                {currentTime.toISOString().split('T')[1].split('.')[0]}
              </div>
            </div>
          </div>

          <p className="text-xl text-white/60 max-w-3xl">
            Real-time situation reports proving our intelligence network is operational and monitoring threats as they emerge.
          </p>
        </motion.div>

        {/* SITREP Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {SITREPS.map((sitrep, index) => (
            <motion.div
              key={sitrep.id}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.1 }}
            >
              <SitrepCard {...sitrep} />
            </motion.div>
          ))}
        </div>

        {/* Footer note */}
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          className="mt-12 text-center text-sm text-white/40"
        >
          <p>All data anonymized for demonstration. Actual threat intelligence available to authorized partners only.</p>
        </motion.div>
      </div>
    </section>
  );
}

function SitrepCard({ 
  id, 
  sector, 
  threat, 
  severity, 
  location, 
  timestamp, 
  status 
}: { 
  id: string;
  sector: string;
  threat: string;
  severity: 'critical' | 'high' | 'medium';
  location: string;
  timestamp: string;
  status: string;
}) {
  const severityConfig = {
    critical: {
      color: 'border-red-600/40 bg-red-950/20',
      textColor: 'text-red-400',
      indicator: 'bg-red-600'
    },
    high: {
      color: 'border-yellow-600/40 bg-yellow-950/20',
      textColor: 'text-yellow-400',
      indicator: 'bg-yellow-600'
    },
    medium: {
      color: 'border-cyan-600/40 bg-cyan-950/20',
      textColor: 'text-cyan-400',
      indicator: 'bg-cyan-600'
    }
  };

  const config = severityConfig[severity];

  return (
    <div className={`relative p-6 rounded-lg border backdrop-blur-sm hover:scale-[1.02] transition-all group ${config.color}`}>
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div className="text-xs text-white/50 font-mono">{id}</div>
        <div className={`w-2 h-2 rounded-full ${config.indicator} ${severity === 'critical' ? 'animate-pulse' : ''}`} />
      </div>

      {/* Sector */}
      <div className="text-sm text-white/70 mb-2">{sector}</div>

      {/* Threat */}
      <h3 className={`text-xl mb-4 ${config.textColor}`}>
        {threat}
      </h3>

      {/* Location */}
      <div className="flex items-start gap-2 mb-3 text-sm text-white/60">
        <MapPin className="w-4 h-4 mt-0.5 flex-shrink-0" />
        <span>{location}</span>
      </div>

      {/* Timestamp */}
      <div className="flex items-center gap-2 mb-4 text-xs text-white/40">
        <Clock className="w-3 h-3" />
        <span>{timestamp}</span>
      </div>

      {/* Status */}
      <div className="pt-4 border-t border-white/10">
        <div className="flex items-center justify-between">
          <span className="text-xs text-white/50 uppercase tracking-wider">Status</span>
          <span className={`text-xs uppercase tracking-wider ${config.textColor}`}>
            {status}
          </span>
        </div>
      </div>

      {/* Corner accent */}
      <div className="absolute bottom-0 right-0 w-6 h-6 border-r border-b border-white/10 opacity-0 group-hover:opacity-100 transition-opacity" />
    </div>
  );
}
