import { motion } from 'motion/react';
import { TrendingUp, DollarSign, Target } from 'lucide-react';

export function MarketOpportunity() {
  const opportunities = [
    {
      icon: <DollarSign className="w-6 h-6" />,
      title: "Total Addressable Market",
      stat: "$7.7B",
      description: "The Global Personal Safety App market is projected to reach $7.7 Billion by 2034",
      growth: "CAGR 15.6%",
      color: "green"
    },
    {
      icon: <TrendingUp className="w-6 h-6" />,
      title: "Regional Growth",
      stat: "14.47%",
      description: "Demand for 'Smart Personal Safety Devices' in APAC is growing annually",
      growth: "Year-over-year acceleration",
      color: "cyan"
    },
    {
      icon: <Target className="w-6 h-6" />,
      title: "Market Gap",
      stat: "<5%",
      description: "While 90% of safety apps focus on urban crime, less than 5% address geopolitical conflict",
      growth: "Sentinel's exclusive niche",
      color: "yellow"
    }
  ];

  return (
    <section className="relative py-32 border-y border-white/10 overflow-hidden">
      {/* Background accent */}
      <div className="absolute inset-0 bg-gradient-to-b from-[#050505] via-green-950/5 to-[#050505]" />

      <div className="relative max-w-7xl mx-auto px-6">
        {/* Section header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-20"
        >
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-green-600/30 bg-green-600/10 mb-6">
            <TrendingUp className="w-4 h-4 text-green-400" />
            <span className="text-sm uppercase tracking-wider text-green-400">Market Analysis</span>
          </div>
          
          <h2 className="text-4xl md:text-6xl mb-6">
            A Market
            <br />
            <span className="text-green-400">Ripe for Disruption.</span>
          </h2>
          
          <p className="text-xl text-white/60 max-w-3xl mx-auto">
            The convergence of AI, geospatial intelligence, and global instability creates an unprecedented opportunity.
          </p>
        </motion.div>

        {/* Opportunities grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {opportunities.map((opportunity, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.15 }}
            >
              <OpportunityCard {...opportunity} index={index} />
            </motion.div>
          ))}
        </div>

        {/* Bottom insight */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mt-16 p-8 rounded-lg border border-yellow-600/20 bg-yellow-950/10 backdrop-blur-sm"
        >
          <div className="flex items-start gap-4">
            <div className="p-2 rounded bg-yellow-600/20">
              <Target className="w-5 h-5 text-yellow-400" />
            </div>
            <div>
              <h3 className="text-xl text-yellow-400 mb-2">Strategic Positioning</h3>
              <p className="text-white/70 leading-relaxed">
                Sentinel occupies a unique position at the intersection of humanitarian technology and defense innovation. As geopolitical tensions escalate globally, we're not just entering a market—we're defining it.
              </p>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}

function OpportunityCard({ 
  icon, 
  title, 
  stat, 
  description, 
  growth,
  color,
  index
}: { 
  icon: React.ReactNode;
  title: string;
  stat: string;
  description: string;
  growth: string;
  color: 'green' | 'cyan' | 'yellow';
  index: number;
}) {
  const colorClasses = {
    green: 'border-green-600/20 bg-green-950/10',
    cyan: 'border-cyan-600/20 bg-cyan-950/10',
    yellow: 'border-yellow-600/20 bg-yellow-950/10'
  };

  const accentColors = {
    green: 'text-green-400',
    cyan: 'text-cyan-400',
    yellow: 'text-yellow-400'
  };

  return (
    <div className="relative h-full group">
      <div className={`h-full p-8 rounded-lg border backdrop-blur-sm hover:scale-[1.02] transition-all ${colorClasses[color]}`}>
        {/* Icon header */}
        <div className={`inline-flex p-3 rounded-lg border mb-6 ${colorClasses[color]}`}>
          <div className={accentColors[color]}>
            {icon}
          </div>
        </div>

        {/* Title */}
        <div className="text-sm uppercase tracking-wider text-white/50 mb-4">
          {title}
        </div>

        {/* Main stat */}
        <div className={`text-5xl mb-6 ${accentColors[color]}`}>
          {stat}
        </div>

        {/* Description */}
        <p className="text-white/80 mb-4 leading-relaxed">
          {description}
        </p>

        {/* Growth indicator */}
        <div className={`text-sm ${accentColors[color]}`}>
          → {growth}
        </div>

        {/* Corner accent */}
        <div className={`absolute top-0 right-0 w-8 h-8 border-r-2 border-t-2 ${
          color === 'green' ? 'border-green-600/30' : 
          color === 'cyan' ? 'border-cyan-600/30' : 
          'border-yellow-600/30'
        }`} />

        {/* Index */}
        <div className="absolute bottom-4 right-4 text-xs text-white/20">
          [0{index + 1}]
        </div>
      </div>
    </div>
  );
}
