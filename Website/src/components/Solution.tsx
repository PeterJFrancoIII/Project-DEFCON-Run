import { motion } from 'motion/react';
import { Zap, Target, Globe } from 'lucide-react';

export function Solution() {
  const metrics = [
    {
      icon: <Zap className="w-6 h-6" />,
      title: "Speed",
      stat: "< 30 seconds",
      description: "Sentinel's AI Engine processes OSINT data and issues valid alerts in under 30 seconds",
      comparison: "vs. 45 mins for traditional channels",
      color: "yellow"
    },
    {
      icon: <Target className="w-6 h-6" />,
      title: "Precision",
      stat: "94%",
      description: "Geospatial filtering reduces false positives by 94%",
      comparison: "ensuring alerts only reach users within the relevant 5km - 20km threat radius",
      color: "cyan"
    },
    {
      icon: <Globe className="w-6 h-6" />,
      title: "Scale",
      stat: "2.9M+",
      description: "Currently monitoring 7,900+ unique zip codes across Southeast Asia",
      comparison: "analyzing over 2.9 million data points daily",
      color: "green"
    }
  ];

  return (
    <section className="relative py-32 overflow-hidden">
      {/* Background grid */}
      <div className="absolute inset-0 opacity-5">
        <div className="h-full w-full" style={{
          backgroundImage: 'linear-gradient(rgba(255,255,255,.1) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.1) 1px, transparent 1px)',
          backgroundSize: '100px 100px'
        }} />
      </div>

      <div className="relative max-w-7xl mx-auto px-6">
        {/* Section header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-20"
        >
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-green-600/30 bg-green-600/10 mb-6">
            <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
            <span className="text-sm uppercase tracking-wider text-green-400">System Performance</span>
          </div>
          
          <h2 className="text-4xl md:text-6xl mb-6">
            A General
            <br />
            <span className="text-yellow-400">for the Populace.</span>
          </h2>
          
          <p className="text-xl text-white/60 max-w-3xl mx-auto">
            Sentinel doesn't aggregate news. It issues orders. Clear. Concise. Life-saving.
          </p>
        </motion.div>

        {/* Metrics */}
        <div className="space-y-8">
          {metrics.map((metric, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, x: -50 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.2 }}
            >
              <MetricRow {...metric} index={index} />
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}

function MetricRow({ 
  icon, 
  title, 
  stat, 
  description, 
  comparison,
  color,
  index
}: { 
  icon: React.ReactNode;
  title: string;
  stat: string;
  description: string;
  comparison: string;
  color: 'yellow' | 'cyan' | 'green';
  index: number;
}) {
  const colorClasses = {
    yellow: 'border-yellow-600/20 bg-yellow-950/10 text-yellow-400',
    cyan: 'border-cyan-600/20 bg-cyan-950/10 text-cyan-400',
    green: 'border-green-600/20 bg-green-950/10 text-green-400'
  };

  const accentColors = {
    yellow: 'text-yellow-400',
    cyan: 'text-cyan-400',
    green: 'text-green-400'
  };

  return (
    <div className="relative group">
      {/* Main container */}
      <div className={`relative p-8 md:p-10 rounded-lg border backdrop-blur-sm hover:scale-[1.01] transition-all ${colorClasses[color]}`}>
        <div className="grid grid-cols-1 md:grid-cols-12 gap-6 md:gap-8 items-center">
          {/* Left: Icon & Title */}
          <div className="md:col-span-2 flex md:flex-col items-center md:items-start gap-4">
            <div className={`p-3 rounded-lg border ${colorClasses[color]}`}>
              {icon}
            </div>
            <div className="text-sm uppercase tracking-wider text-white/70">
              {title}
            </div>
          </div>

          {/* Center: Stat */}
          <div className="md:col-span-3">
            <div className={`text-5xl md:text-6xl ${accentColors[color]}`}>
              {stat}
            </div>
          </div>

          {/* Right: Description */}
          <div className="md:col-span-7 space-y-2">
            <p className="text-lg text-white">
              {description}
            </p>
            <p className="text-sm text-white/50">
              {comparison}
            </p>
          </div>
        </div>

        {/* Corner markers */}
        <div className="absolute top-0 left-0 w-6 h-6 border-l-2 border-t-2 border-white/20" />
        <div className="absolute bottom-0 right-0 w-6 h-6 border-r-2 border-b-2 border-white/20" />

        {/* Index */}
        <div className="absolute top-4 right-4 text-xs text-white/30">
          METRIC_{(index + 1).toString().padStart(2, '0')}
        </div>
      </div>

      {/* Connection line to next item */}
      {index < 2 && (
        <div className="hidden md:block absolute left-12 top-full h-8 w-0.5 bg-gradient-to-b from-white/20 to-transparent" />
      )}
    </div>
  );
}
