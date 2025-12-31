import { motion } from 'motion/react';
import { Heart } from 'lucide-react';

export function OriginStory() {
  return (
    <section className="relative py-32 overflow-hidden">
      {/* Background image with heavy overlay */}
      <div 
        className="absolute inset-0 z-0"
        style={{
          backgroundImage: 'url(https://images.unsplash.com/photo-1760199789455-49098afd02f0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjeWJlcnNlY3VyaXR5JTIwdGVjaG5vbG9neXxlbnwxfHx8fDE3NjY5Njc1NDl8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral)',
          backgroundSize: 'cover',
          backgroundPosition: 'center',
        }}
      >
        <div className="absolute inset-0 bg-[#050505]/95" />
      </div>

      <div className="relative max-w-5xl mx-auto px-6">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-white/20 bg-white/5 backdrop-blur-sm mb-6">
            <Heart className="w-4 h-4 text-red-400" />
            <span className="text-sm uppercase tracking-wider text-white/70">Genesis</span>
          </div>
          
          <h2 className="text-4xl md:text-6xl mb-8">
            Why We Built This.
          </h2>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.2 }}
          className="relative"
        >
          {/* Quote marks */}
          <div className="absolute -top-8 -left-4 md:-left-8 text-8xl text-white/10">"</div>
          
          {/* Story container */}
          <div className="relative p-10 md:p-16 rounded-lg border border-white/10 bg-white/5 backdrop-blur-sm">
            {/* Corner accents */}
            <div className="absolute top-0 left-0 w-16 h-16 border-l-2 border-t-2 border-cyan-500/30" />
            <div className="absolute bottom-0 right-0 w-16 h-16 border-r-2 border-b-2 border-cyan-500/30" />

            <div className="text-xl md:text-2xl text-white/90 leading-relaxed space-y-6">
              <p>
                The genesis of Sentinel was born in the <span className="text-red-400">terrifying silence</span> between text messages during a live regional conflict.
              </p>
              
              <p>
                My own family was trapped in a conflict zone, drowning in a sea of conflicting data—local news was hours behind, and social media was flooded with propaganda.
              </p>
              
              <p>
                I realized then that civilians don't need another news aggregator; they need a <span className="text-yellow-400">General</span>. They need a system that ingests the chaos and issues clear, concise orders: <span className="text-white">'Go Left, Don't Go Right.'</span>
              </p>
              
              <p className="text-cyan-400">
                Sentinel is that General.
              </p>
            </div>

            {/* Attribution */}
            <div className="mt-12 pt-6 border-t border-white/10">
              <div className="text-sm text-white/50">
                — Founder, Sentinel Defense Technologies
              </div>
            </div>
          </div>

          {/* Closing quote */}
          <div className="absolute -bottom-4 -right-4 md:-right-8 text-8xl text-white/10">"</div>
        </motion.div>

        {/* Visual accent - heartbeat line */}
        <motion.div
          initial={{ scaleX: 0 }}
          whileInView={{ scaleX: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 1.5, delay: 0.5 }}
          className="mt-16 h-0.5 bg-gradient-to-r from-transparent via-red-500 to-transparent"
        />
      </div>
    </section>
  );
}
