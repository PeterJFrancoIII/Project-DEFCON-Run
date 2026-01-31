import { motion } from 'motion/react';
import { AlertTriangle } from 'lucide-react';

export function Problem() {
  const metrics = [
    {
      stat: "72%",
      label: "Increase in civilian deaths in conflict zones globally in 2024",
      detail: "with disinformation cited as a primary factor in delayed evacuations."
    },
    {
      stat: "4-6 hours",
      label: "Delay between verified news and social media rumors",
      detail: "during active crises, when every minute counts."
    },
    {
      stat: "120M+",
      label: "Forcibly displaced people worldwide",
      detail: "lacking access to reliable, localized safety intelligence."
    }
  ];

  return (
    <section className="relative py-32 overflow-hidden">
      {/* Background accent */}
      <div className="absolute inset-0 bg-gradient-to-b from-[#050505] via-red-950/5 to-[#050505]" />
      
      <div className="relative max-w-7xl mx-auto px-6">
        {/* Section header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-20"
        >
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-red-600/30 bg-red-600/10 mb-6">
            <AlertTriangle className="w-4 h-4 text-red-500" />
            <span className="text-sm uppercase tracking-wider text-red-400">Critical Problem</span>
          </div>
          
          <h2 className="text-4xl md:text-6xl mb-6">
            Confusion is Deadlier
            <br />
            <span className="text-red-500">Than Munitions.</span>
          </h2>
          
          <p className="text-xl text-white/60 max-w-3xl mx-auto">
            In the fog of conflict, civilians die not from lack of warnings, but from an overwhelming cacophony of misinformation.
          </p>
        </motion.div>

        {/* Metrics grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {metrics.map((metric, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.2 }}
            >
              <MetricCard {...metric} index={index} />
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}

function MetricCard({ 
  stat, 
  label, 
  detail, 
  index 
}: { 
  stat: string; 
  label: string; 
  detail: string;
  index: number;
}) {
  return (
    <div className="relative group h-full">
      {/* Card container with glassmorphism */}
      <div className="relative h-full p-8 rounded-lg border border-red-600/20 bg-gradient-to-br from-red-950/20 to-transparent backdrop-blur-sm hover:border-red-600/40 transition-all">
        {/* Index indicator */}
        <div className="absolute top-4 right-4 text-red-600/30 text-sm">
          [{(index + 1).toString().padStart(2, '0')}]
        </div>

        {/* Threat level indicator */}
        <div className="flex items-center gap-2 mb-6">
          <div className="w-2 h-2 bg-red-600 animate-pulse" />
          <div className="w-2 h-2 bg-red-600 animate-pulse delay-100" />
          <div className="w-2 h-2 bg-red-600 animate-pulse delay-200" />
        </div>

        {/* Main stat */}
        <div className="text-5xl md:text-6xl text-red-500 mb-4">
          {stat}
        </div>

        {/* Label */}
        <div className="text-lg text-white mb-3">
          {label}
        </div>

        {/* Detail */}
        <div className="text-sm text-white/50 leading-relaxed">
          {detail}
        </div>

        {/* Corner accent */}
        <div className="absolute bottom-0 left-0 w-12 h-12 border-l border-b border-red-600/20 group-hover:border-red-600/40 transition-colors" />
      </div>
    </div>
  );
}
