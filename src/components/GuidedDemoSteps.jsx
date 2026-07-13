import { useEffect, useState } from 'react';
import { ArrowRight } from 'lucide-react';
import { guidedDemoSteps } from '../siteConfig.js';
import { usePhone } from '../InteractivePhone.jsx';
import { FadeIn } from './FadeIn.jsx';

function deriveActiveStep(phone) {
  if (phone.tab === 'Auto' && phone.sheet === 'approval') return 'scenes';
  if (phone.sheet === 'action' || phone.toast) return 'action';
  if (phone.sheet === 'reasoning') return 'reasoning';
  return 'home';
}

export function GuidedDemoSteps() {
  const phone = usePhone();
  const active = deriveActiveStep(phone);

  return (
    <FadeIn className="guided-demo-steps">
      <p className="guided-demo-label">Try the flow</p>
      <div className="guided-demo-strip" role="list">
        {guidedDemoSteps.map((step, i) => (
          <button
            key={step.id}
            type="button"
            role="listitem"
            className={`guided-demo-step ${active === step.id ? 'active' : ''}`}
            onClick={() => phone.runGuidedStep(step.id)}
            aria-current={active === step.id ? 'step' : undefined}
          >
            <span className="guided-demo-num">{i + 1}</span>
            <span className="guided-demo-text">
              <b>{step.label}</b>
              <span>{step.short}</span>
            </span>
          </button>
        ))}
      </div>
    </FadeIn>
  );
}

export function MobileDemoFAB() {
  const visible = useMobileDemoFab();

  if (!visible) return null;

  return (
    <a className="mobile-demo-fab" href="#demo">
      <span className="demo-live-dot" />
      Live demo
      <ArrowRight size={14} />
    </a>
  );
}

function useMobileDemoFab() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const demo = document.getElementById('demo');
    if (!demo) return undefined;

    const mq = window.matchMedia('(max-width: 900px)');
    const observer = new IntersectionObserver(
      ([entry]) => setVisible(mq.matches && !entry.isIntersecting),
      { threshold: 0.15 },
    );

    const sync = () => {
      if (!mq.matches) {
        setVisible(false);
        return;
      }
      observer.observe(demo);
    };

    mq.addEventListener('change', sync);
    sync();

    return () => {
      mq.removeEventListener('change', sync);
      observer.disconnect();
    };
  }, []);

  return visible;
}
