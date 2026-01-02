import { motion } from 'motion/react';
import { Lock, Download, Mail, Building2, User, Send } from 'lucide-react';
import { useState } from 'react';

export function InvestorAccess() {
  const [formData, setFormData] = useState({
    name: '',
    organization: '',
    email: '',
    investorType: '',
    message: ''
  });

  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Create mailto link with form data
    const subject = encodeURIComponent(`Investment Inquiry from ${formData.name}`);
    const body = encodeURIComponent(
      `Name: ${formData.name}\n` +
      `Organization: ${formData.organization}\n` +
      `Email: ${formData.email}\n` +
      `Investor Type: ${formData.investorType}\n\n` +
      `Message:\n${formData.message}`
    );
    window.location.href = `mailto:PeterJFrancoIII@gmail.com?subject=${subject}&body=${body}`;
    setSubmitted(true);
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setFormData(prev => ({
      ...prev,
      [e.target.name]: e.target.value
    }));
  };

  return (
    <section className="relative py-32 overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0 bg-gradient-to-b from-[#050505] via-cyan-950/5 to-[#050505]" />

      <div className="relative max-w-7xl mx-auto px-6">
        {/* Section header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-20"
        >
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-cyan-600/30 bg-cyan-600/10 mb-6">
            <Lock className="w-4 h-4 text-cyan-400" />
            <span className="text-sm uppercase tracking-wider text-cyan-400">Investors and Donations</span>
          </div>
          
          <h2 className="text-4xl md:text-6xl mb-6">
            Partner
            <br />
            <span className="text-cyan-400">with Us.</span>
          </h2>
          
          <p className="text-xl text-white/60 max-w-3xl mx-auto">
            Request access to our data room, technical documentation, and executive materials.
          </p>
        </motion.div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          {/* Left: Form */}
          <motion.div
            initial={{ opacity: 0, x: -30 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
          >
            {!submitted ? (
              <form onSubmit={handleSubmit} className="space-y-6">
                {/* Name */}
                <div>
                  <label className="block text-sm text-white/70 mb-2 flex items-center gap-2">
                    <User className="w-4 h-4" />
                    Full Name
                  </label>
                  <input
                    type="text"
                    name="name"
                    required
                    value={formData.name}
                    onChange={handleChange}
                    className="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-white/30 focus:outline-none focus:border-cyan-500/50 backdrop-blur-sm transition-colors"
                    placeholder="John Doe"
                  />
                </div>

                {/* Organization */}
                <div>
                  <label className="block text-sm text-white/70 mb-2 flex items-center gap-2">
                    <Building2 className="w-4 h-4" />
                    Organization
                  </label>
                  <input
                    type="text"
                    name="organization"
                    required
                    value={formData.organization}
                    onChange={handleChange}
                    className="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-white/30 focus:outline-none focus:border-cyan-500/50 backdrop-blur-sm transition-colors"
                    placeholder="Venture Capital Fund LLC"
                  />
                </div>

                {/* Email */}
                <div>
                  <label className="block text-sm text-white/70 mb-2 flex items-center gap-2">
                    <Mail className="w-4 h-4" />
                    Email Address
                  </label>
                  <input
                    type="email"
                    name="email"
                    required
                    value={formData.email}
                    onChange={handleChange}
                    className="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-white/30 focus:outline-none focus:border-cyan-500/50 backdrop-blur-sm transition-colors"
                    placeholder="investor@fund.com"
                  />
                </div>

                {/* Investor Type */}
                <div>
                  <label className="block text-sm text-white/70 mb-2">
                    Investor Type
                  </label>
                  <select
                    name="investorType"
                    required
                    value={formData.investorType}
                    onChange={handleChange}
                    className="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white focus:outline-none focus:border-cyan-500/50 backdrop-blur-sm transition-colors"
                  >
                    <option value="" className="bg-[#050505]">Select type...</option>
                    <option value="vc" className="bg-[#050505]">Venture Capital</option>
                    <option value="pe" className="bg-[#050505]">Private Equity</option>
                    <option value="strategic" className="bg-[#050505]">Strategic Partner</option>
                    <option value="angel" className="bg-[#050505]">Angel Investor</option>
                    <option value="other" className="bg-[#050505]">Other</option>
                  </select>
                </div>

                {/* Message */}
                <div>
                  <label className="block text-sm text-white/70 mb-2">
                    Message (Optional)
                  </label>
                  <textarea
                    name="message"
                    value={formData.message}
                    onChange={handleChange}
                    rows={4}
                    className="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-white/30 focus:outline-none focus:border-cyan-500/50 backdrop-blur-sm transition-colors resize-none"
                    placeholder="Tell us about your interest in Sentinel..."
                  />
                </div>

                {/* Submit */}
                <button
                  type="submit"
                  className="w-full group relative px-6 py-4 bg-cyan-600 text-white overflow-hidden hover:bg-cyan-700 transition-colors border border-cyan-500"
                >
                  <div className="relative z-10 flex items-center justify-center gap-2">
                    <Send className="w-5 h-5" />
                    Request Data Room Access
                  </div>
                  <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/10 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-700" />
                </button>

                {/* Disclaimer */}
                <p className="text-xs text-white/40 text-center">
                  By submitting this form, you will be directed to send an email with your information. All materials are confidential and subject to NDA.
                </p>
              </form>
            ) : (
              <motion.div
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                className="p-12 rounded-lg border border-green-600/40 bg-green-950/20 backdrop-blur-sm text-center"
              >
                <div className="w-16 h-16 rounded-full bg-green-600/20 flex items-center justify-center mx-auto mb-6">
                  <div className="w-8 h-8 rounded-full border-4 border-green-400 border-t-transparent animate-spin" />
                </div>
                <h3 className="text-2xl text-green-400 mb-4">Request Received</h3>
                <p className="text-white/70">
                  Thank you for your interest. Our team will review your request and contact you within 24-48 hours with next steps.
                </p>
              </motion.div>
            )}
          </motion.div>

          {/* Right: Downloads & Info */}
          <motion.div
            initial={{ opacity: 0, x: 30 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            className="space-y-6"
          >
            {/* Download cards */}
            <div className="space-y-4">
              <h3 className="text-xl text-white/80 mb-6">Available Documentation</h3>
              
              <DownloadCard
                title="Technical Whitepaper"
                description="Detailed technical architecture, AI model specifications, and geospatial analytics methodology."
                fileSize="4.2 MB"
                restricted={true}
              />

              <DownloadCard
                title="Executive Summary"
                description="Market analysis, competitive landscape, and five-year financial projections."
                fileSize="1.8 MB"
                restricted={true}
              />

              <DownloadCard
                title="Product Demo Deck"
                description="Visual walkthrough of the Sentinel platform and key features."
                fileSize="12.5 MB"
                restricted={true}
              />
            </div>

            {/* Info box */}
            <div className="p-6 rounded-lg border border-yellow-600/20 bg-yellow-950/10 backdrop-blur-sm">
              <div className="flex items-start gap-3">
                <Lock className="w-5 h-5 text-yellow-400 mt-1 flex-shrink-0" />
                <div>
                  <h4 className="text-lg text-yellow-400 mb-2">Secure Access</h4>
                  <p className="text-sm text-white/70 leading-relaxed">
                    All documentation is protected and requires NDA signature before access. Downloads are tracked and watermarked for security purposes.
                  </p>
                </div>
              </div>
            </div>

            {/* Contact info */}
            <div className="p-6 rounded-lg border border-white/10 bg-white/5 backdrop-blur-sm">
              <h4 className="text-lg text-white mb-4">Direct Inquiries</h4>
              <div className="space-y-3 text-sm">
                <div className="flex items-center gap-3 text-white/70">
                  <Mail className="w-4 h-4 text-cyan-400" />
                  <a href="mailto:PeterJFrancoIII@gmail.com" className="hover:text-cyan-400 transition-colors">
                    PeterJFrancoIII@gmail.com
                  </a>
                </div>
                <div className="flex items-center gap-3 text-white/70">
                  <Building2 className="w-4 h-4 text-cyan-400" />
                  <span>Sentinel Defense Technologies Inc.</span>
                </div>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}

function DownloadCard({ 
  title, 
  description, 
  fileSize, 
  restricted 
}: { 
  title: string; 
  description: string; 
  fileSize: string;
  restricted: boolean;
}) {
  return (
    <button
      disabled={restricted}
      className="w-full text-left p-6 rounded-lg border border-white/10 bg-white/5 backdrop-blur-sm hover:bg-white/10 transition-all disabled:opacity-50 disabled:cursor-not-allowed group"
    >
      <div className="flex items-start justify-between gap-4">
        <div className="flex-1">
          <div className="flex items-center gap-3 mb-2">
            <Download className="w-5 h-5 text-cyan-400" />
            <h4 className="text-lg text-white">{title}</h4>
          </div>
          <p className="text-sm text-white/60 mb-3">
            {description}
          </p>
          <div className="text-xs text-white/40">
            {fileSize} • PDF
          </div>
        </div>
        
        {restricted && (
          <div className="flex-shrink-0">
            <Lock className="w-5 h-5 text-yellow-400" />
          </div>
        )}
      </div>
    </button>
  );
}