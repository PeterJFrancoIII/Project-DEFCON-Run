import { motion } from 'motion/react';
import { MapPin, Users, Shield, Target } from 'lucide-react';

export function AboutUs() {
  return (
    <section className="relative py-20 overflow-hidden">
      {/* Background grid */}
      <div className="absolute inset-0 opacity-5">
        <div className="h-full w-full" style={{
          backgroundImage: 'linear-gradient(rgba(255,255,255,.05) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.05) 1px, transparent 1px)',
          backgroundSize: '50px 50px'
        }} />
      </div>

      <div className="relative z-10 max-w-7xl mx-auto px-6">
        {/* Section Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <div className="flex items-center justify-center gap-3 mb-4">
            <div className="w-2 h-2 bg-cyan-400" />
            <span className="tracking-[0.3em] text-sm text-white/70 uppercase">About Sentinel</span>
            <div className="w-2 h-2 bg-cyan-400" />
          </div>
          <h2 className="text-4xl md:text-6xl mb-6">
            Mission-Driven Defense Intelligence
          </h2>
          <p className="text-xl text-white/70 max-w-3xl mx-auto">
            Building the future of civilian protection through real-time AI-powered threat intelligence
          </p>
        </motion.div>

        {/* Main Content Grid */}
        <div className="grid md:grid-cols-2 gap-8 mb-16">
          {/* Who We Are */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            className="relative p-8 bg-white/5 backdrop-blur-sm border border-white/10 hover:border-cyan-500/50 transition-colors"
          >
            <div className="absolute top-4 right-4 opacity-10">
              <Shield className="w-24 h-24" />
            </div>
            <div className="relative z-10">
              <div className="flex items-center gap-3 mb-4">
                <Users className="w-6 h-6 text-cyan-400" />
                <h3 className="text-2xl">Who We Are</h3>
              </div>
              <p className="text-white/70 leading-relaxed mb-4">
                Sentinel Defense Technologies is a cutting-edge defense-tech startup dedicated to protecting civilian lives through advanced artificial intelligence and geospatial intelligence. 
              </p>
              <p className="text-white/70 leading-relaxed">
                Founded by experts in AI, defense, and humanitarian response, we combine Google Vertex AI with real-time geospatial data to deliver actionable threat intelligence directly to civilians in conflict zones.
              </p>
            </div>
          </motion.div>

          {/* Our Mission */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            className="relative p-8 bg-white/5 backdrop-blur-sm border border-white/10 hover:border-red-500/50 transition-colors"
          >
            <div className="absolute top-4 right-4 opacity-10">
              <Target className="w-24 h-24" />
            </div>
            <div className="relative z-10">
              <div className="flex items-center gap-3 mb-4">
                <Target className="w-6 h-6 text-red-400" />
                <h3 className="text-2xl">Our Mission</h3>
              </div>
              <p className="text-white/70 leading-relaxed mb-4">
                To democratize military-grade threat intelligence and make it accessible to every civilian at risk, transforming the fog of war into crystal-clear situational awareness.
              </p>
              <p className="text-white/70 leading-relaxed">
                We believe every person has the right to know when danger is approaching, giving them the critical minutes needed to make life-saving decisions.
              </p>
            </div>
          </motion.div>
        </div>

        {/* Location & Contact Info */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="relative p-8 bg-gradient-to-r from-cyan-950/20 to-blue-950/20 backdrop-blur-sm border border-cyan-500/30"
        >
          <div className="absolute inset-0 bg-gradient-to-r from-cyan-500/5 to-blue-500/5" />
          
          <div className="relative z-10 grid md:grid-cols-2 gap-8">
            {/* Headquarters */}
            <div>
              <div className="flex items-center gap-3 mb-4">
                <MapPin className="w-6 h-6 text-cyan-400" />
                <h3 className="text-2xl">Headquarters</h3>
              </div>
              <div className="space-y-2 text-white/70">
                <p className="text-lg">United States</p>
                <p className="text-sm">
                  Operating globally with a focus on conflict zones and high-risk regions
                </p>
              </div>
            </div>

            {/* Operating Regions */}
            <div>
              <div className="flex items-center gap-3 mb-4">
                <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                <h3 className="text-2xl">Global Operations</h3>
              </div>
              <div className="grid grid-cols-2 gap-2 text-sm text-white/60">
                <div className="flex items-center gap-2">
                  <div className="w-1 h-1 bg-green-400 rounded-full" />
                  Middle East
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-1 h-1 bg-green-400 rounded-full" />
                  Eastern Europe
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-1 h-1 bg-green-400 rounded-full" />
                  Sub-Saharan Africa
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-1 h-1 bg-green-400 rounded-full" />
                  South Asia
                </div>
              </div>
            </div>
          </div>

          {/* Contact CTA */}
          <div className="mt-8 pt-6 border-t border-white/10">
            <p className="text-center text-white/60 text-sm">
              For partnership inquiries, investor relations, or media requests
            </p>
            <div className="flex justify-center mt-4">
              <a 
                href="mailto:PeterJFrancoIII@gmail.com"
                className="px-6 py-2 border border-cyan-600/50 text-cyan-400 hover:bg-cyan-600/20 transition-colors text-sm uppercase tracking-wider"
              >
                Contact Us
              </a>
            </div>
          </div>
        </motion.div>

        {/* Values Grid */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="grid md:grid-cols-3 gap-6 mt-16"
        >
          {[
            {
              title: 'Humanitarian First',
              description: 'Every decision we make prioritizes civilian safety and protection',
              color: 'red'
            },
            {
              title: 'AI Excellence',
              description: 'Leveraging Google Vertex AI to deliver unparalleled accuracy and speed',
              color: 'cyan'
            },
            {
              title: 'Transparent Ethics',
              description: 'Operating with complete transparency in our methods and intentions',
              color: 'yellow'
            }
          ].map((value, index) => (
            <div
              key={index}
              className="p-6 bg-white/5 backdrop-blur-sm border border-white/10 hover:border-white/30 transition-colors"
            >
              <div className={`w-1 h-12 bg-${value.color}-400 mb-4`} />
              <h4 className="text-lg mb-2">{value.title}</h4>
              <p className="text-sm text-white/60">{value.description}</p>
            </div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
