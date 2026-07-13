import { MessageCircle, Sparkles, Zap } from 'lucide-react';
import { FadeIn } from './FadeIn.jsx';

const aiCallouts = [
  { icon: MessageCircle, label: 'Plain language', sub: 'Say it your way' },
  { icon: Sparkles, label: 'Lumen proposes', sub: 'Never acts on its own' },
  { icon: Zap, label: 'You decide', sub: 'One tap to approve' },
];

export function AIComingSoonSection() {
  return (
    <section className="ai-teaser-section" id="ai">
      <FadeIn className="ai-teaser-inner">
        <p className="eyebrow">coming soon</p>
        <h2>describe it.<br /><em>you approve it.</em></h2>
        <p className="section-note">
          A conversational layer is on the way. Describe what you want in plain language,
          and Lumen proposes the scene, shows its reasoning, and waits for your tap.
        </p>
        <div className="ai-teaser-callouts">
          {aiCallouts.map(({ icon: Icon, label, sub }) => (
            <div className="ai-teaser-callout" key={label}>
              <Icon size={16} />
              <div>
                <b>{label}</b>
                <span>{sub}</span>
              </div>
            </div>
          ))}
        </div>
      </FadeIn>
    </section>
  );
}
