import { Apple, Mail, Send } from 'lucide-react';
import { FadeIn } from './FadeIn.jsx';

const steps = [
  { icon: Mail, title: 'Enter your email', sub: 'One field. No account to create yet.' },
  { icon: Send, title: 'Get your TestFlight invite', sub: 'We email an Apple TestFlight link when a spot opens.' },
  { icon: Apple, title: 'Install on your iPhone', sub: 'Tap install and Lumen opens like any App Store app.' },
];

export function GettingStartedSection() {
  return (
    <section className="getting-started-section surface-alt" id="start">
      <FadeIn className="section-copy centered">
        <p className="eyebrow">getting started</p>
        <h2>Three steps<br /><em>to your first run.</em></h2>
        <p className="section-note">
          From an email address to Lumen open on your iPhone. There is no account to create.
        </p>
      </FadeIn>
      <ol className="getting-started-steps">
        {steps.map(({ icon: Icon, title, sub }, i) => (
          <li className="getting-started-step" key={title}>
            <span className="getting-started-num">{i + 1}</span>
            <span className="getting-started-icon"><Icon size={18} /></span>
            <span className="getting-started-text">
              <b>{title}</b>
              <span>{sub}</span>
            </span>
          </li>
        ))}
      </ol>
      <a className="getting-started-cta" href="#access">
        Join the waitlist
      </a>
    </section>
  );
}
