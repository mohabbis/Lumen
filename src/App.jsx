import { useEffect, useRef, useState } from "react";
import {
  ArrowDown,
  ArrowUpRight,
  Check,
  ChevronRight,
  House,
  Menu,
  Moon,
  Play,
  ShieldCheck,
  Sparkles,
  Sun,
  X,
} from "lucide-react";
import { DemoProvider, useDemo } from "./demo/DemoContext.jsx";
import { InteractiveDemo } from "./demo/InteractiveDemo.jsx";
import { Waitlist } from "./components/Waitlist.jsx";
import "./styles/tokens.css";
import "./styles/base.css";
import "./styles/marketing.css";

function Logo() {
  return (
    <span className="brand">
      <span className="brand-mark" aria-hidden="true">
        <i />
        <i />
        <i />
      </span>
      Lumen
    </span>
  );
}

function Navigation() {
  const [open, setOpen] = useState(false);
  const toggle = useRef(null);
  useEffect(() => {
    if (!open) return;
    const handler = (event) => {
      if (event.key === "Escape") {
        setOpen(false);
        toggle.current.focus();
      }
    };
    const resize = () => {
      if (window.innerWidth >= 768) setOpen(false);
    };
    document.addEventListener("keydown", handler);
    window.addEventListener("resize", resize);
    return () => {
      document.removeEventListener("keydown", handler);
      window.removeEventListener("resize", resize);
    };
  }, [open]);
  const close = () => setOpen(false);
  return (
    <header className="site-header">
      <div className="nav-wrap">
        <a href="#top" aria-label="Lumen home" onClick={close}>
          <Logo />
        </a>
        <nav
          aria-label="Main navigation"
          className={open ? "site-nav is-open" : "site-nav"}
          id="main-navigation"
        >
          <a href="#experience" onClick={close}>
            The experience
          </a>
          <a href="#why-lumen" onClick={close}>
            Why Lumen
          </a>
          <a href="#details" onClick={close}>
            The details
          </a>
          <a href="#access" className="mobile-nav-cta" onClick={close}>
            Join the waitlist
          </a>
        </nav>
        <div className="nav-actions">
          <a className="nav-cta" href="#access">
            Join the waitlist <ArrowUpRight size={15} />
          </a>
          <button
            ref={toggle}
            className="icon-button menu-toggle"
            aria-label={open ? "Close menu" : "Open menu"}
            aria-expanded={open}
            aria-controls="main-navigation"
            onClick={() => setOpen(!open)}
          >
            {open ? <X /> : <Menu />}
          </button>
        </div>
      </div>
    </header>
  );
}
function DemoLink({
  children,
  action = "EXPAND",
  id,
  className = "text-button",
}) {
  const { dispatch, openerRef } = useDemo();
  return (
    <button
      className={className}
      onClick={(event) => {
        openerRef.current = event.currentTarget;
        if (action === "ROOM") dispatch({ type: "ROOM", id });
        else dispatch({ type: action });
        dispatch({ type: "EXPAND" });
      }}
    >
      {children}
    </button>
  );
}
function MarketingPage({ signupConfig }) {
  return (
    <>
      <a href="#main-content" className="skip-link">
        Skip to content
      </a>
      <Navigation />
      <main id="main-content">
        <section
          className="hero section"
          id="top"
          aria-labelledby="hero-heading"
        >
          <div className="hero-copy">
            <span className="availability">
              <span /> In development for iPhone & iPad
            </span>
            <h1 id="hero-heading">
              Your home.
              <br />
              Less to manage.
            </h1>
            <p className="hero-lede">
              A calmer home companion. Bring your rooms, devices, and routines
              into focus, with gentle suggestions you can understand and
              approve.
            </p>
            <div className="hero-actions">
              <a className="button button-primary" href="#access">
                Join the waitlist <ArrowUpRight size={17} />
              </a>
              <DemoLink className="button button-outline">
                <Play size={15} fill="currentColor" /> Try Lumen
              </DemoLink>
            </div>
            <div className="hero-footnote">
              <span>Local-first by design</span>
              <span>Useful without smart hardware</span>
            </div>
          </div>
          <div className="hero-product">
            <div className="architectural-light" aria-hidden="true">
              <span />
              <i />
            </div>
            <InteractiveDemo />
            <span className="product-caption">
              A little more clarity. A little more calm.
            </span>
          </div>
          <a href="#experience" className="hero-scroll">
            Make yourself at home <ArrowDown size={15} />
          </a>
        </section>
        <section
          className="section experience-section"
          id="experience"
          aria-labelledby="experience-heading"
        >
          <div>
            <span className="section-kicker">Feel the difference</span>
            <h2 className="marketing-heading" id="experience-heading">
              A home that makes
              <br />a little more sense.
            </h2>
          </div>
          <div className="experience-copy">
            <p>
              Start with a softer evening. See what Lumen notices, review the
              changes, and decide for yourself. Or explore the rooms at your own
              pace.
            </p>
            <div className="experience-actions">
              <DemoLink action="GUIDE_START" className="button button-primary">
                <Moon size={17} /> Try an evening routine
              </DemoLink>
              <DemoLink>
                Explore the preview <ArrowUpRight size={16} />
              </DemoLink>
            </div>
            <p className="small-note">
              Interactive simulation. No account, hardware, or permissions
              needed.
            </p>
          </div>
        </section>
        <section
          className="section why-section"
          id="why-lumen"
          aria-labelledby="why-heading"
        >
          <div className="section-heading">
            <span className="section-kicker">Thoughtfully, by design</span>
            <h2 className="marketing-heading" id="why-heading">
              Less noise.
              <br />
              More room for you.
            </h2>
            <p>
              Built with different minds in mind. Clear context, familiar
              routines, and control that feels comfortable.
            </p>
          </div>
          <div className="principles">
            <article>
              <span className="principle-symbol">
                <Sun size={26} strokeWidth={1.3} />
              </span>
              <h3>Your day has a rhythm.</h3>
              <p>
                See where you are in the day and what comes next. Lumen’s daily
                rhythm works even before you connect a single device.
              </p>
              <div
                className="rhythm-strip"
                aria-label="Daily rhythm: Morning, Afternoon, Evening, Night"
              >
                <span />
                <span />
                <span className="current" />
                <span />
                <small>Now: Evening</small>
              </div>
            </article>
            <article>
              <span className="principle-symbol">
                <Sparkles size={26} strokeWidth={1.3} />
              </span>
              <h3>A reason, not a mystery.</h3>
              <p>
                Time of day, presence, reachable devices. See the signals behind
                a suggestion, along with exactly what it would change.
              </p>
              <div className="reason-example">
                <span>Evening</span>
                <span>At home</span>
                <span>Lights reachable</span>
              </div>
            </article>
            <article>
              <span className="principle-symbol">
                <ShieldCheck size={26} strokeWidth={1.3} />
              </span>
              <h3>The last word is yours.</h3>
              <p>
                Review and approve suggestions and manual scenes. Scheduled,
                arrival, and departure automations run independently only when
                you configure them.
              </p>
              <div className="consent-example">
                <Check size={16} />
                <span>Nothing to approve? Carry on.</span>
              </div>
            </article>
          </div>
        </section>
        <section
          className="section everyday-section"
          id="everyday"
          aria-labelledby="everyday-heading"
        >
          <div className="everyday-art" aria-hidden="true">
            <div className="room-illustration">
              <div className="room-window">
                <span />
                <span />
              </div>
              <div className="room-lamp">
                <i />
                <span />
                <b />
              </div>
              <div className="room-sofa">
                <span />
                <span />
                <i />
              </div>
              <div className="room-table" />
              <span className="room-floor" />
            </div>
            <div className="evening-receipt">
              <Moon size={19} />
              <span>
                <strong>Evening</strong>
                <small>Living room lights at 40%</small>
              </span>
              <Check size={16} />
            </div>
            <span className="illustration-caption">
              An illustration of a calmer evening
            </span>
          </div>
          <div className="everyday-copy">
            <span className="section-kicker">
              Small changes. Everyday ease.
            </span>
            <h2 className="marketing-heading" id="everyday-heading">
              Settle in.
              <br />
              Let the day soften.
            </h2>
            <p>
              The ceiling light lowers. The floor lamp warms. The kitchen light
              turns off. One scene brings the room into the evening, after you
              say yes.
            </p>
            <DemoLink action="GUIDE_START">
              See what Evening changes <ChevronRight size={17} />
            </DemoLink>
            <div className="everyday-alternatives">
              <DemoLink action="ROOM" id="living">
                <House size={18} />
                <span>Adjust a room</span>
                <ChevronRight size={16} />
              </DemoLink>
              <DemoLink action="ROOM" id="bedroom">
                <ShieldCheck size={18} />
                <span>Understand an unavailable device</span>
                <ChevronRight size={16} />
              </DemoLink>
            </div>
          </div>
        </section>
        <section
          className="section details-section"
          id="details"
          aria-labelledby="details-heading"
        >
          <div className="details-intro">
            <span className="section-kicker">The practical details</span>
            <h2 className="marketing-heading" id="details-heading">
              Built for your home.
              <br />
              Honest about the rest.
            </h2>
            <p>
              Lumen adds rhythm and explanation to home control. It uses Apple’s
              HomeKit framework for supported accessories.
            </p>
            <a className="text-link" href="/privacy">
              Read the privacy policy <ArrowUpRight size={16} />
            </a>
          </div>
          <dl className="details-list">
            <div>
              <dt>Native to iPhone & iPad</dt>
              <dd>
                Built with SwiftUI for iOS and iPadOS 17 or later. Beta access
                is by invitation; joining the waitlist does not immediately
                install the app.
              </dd>
            </div>
            <div>
              <dt>HomeKit, with permission</dt>
              <dd>
                Controls depend on the capabilities each accessory exposes
                through HomeKit, including compatible Matter accessories added
                to Apple Home. Availability varies by accessory; this is not a
                guarantee for every brand or Thread device.
              </dd>
            </div>
            <div>
              <dt>Local-first, from the start</dt>
              <dd>
                Home context and reasoning are handled on device. CloudKit sync
                is currently disabled. HomeKit, location, and notification
                access use explicit permissions.
              </dd>
            </div>
            <div>
              <dt>No hardware? Still at home.</dt>
              <dd>
                Daily rhythm and local preview let you explore without smart
                accessories. The browser preview uses sample data and never
                connects to your real home.
              </dd>
            </div>
          </dl>
        </section>
        <Waitlist config={signupConfig} />
      </main>
      <footer className="site-footer">
        <div>
          <a href="#top" aria-label="Lumen home">
            <Logo />
          </a>
          <p>A little more at home.</p>
        </div>
        <nav aria-label="Footer navigation">
          <a href="/privacy">Privacy</a>
          <a href="/terms">Terms</a>
          <a
            href="https://github.com/mohabbis/lumen"
            target="_blank"
            rel="noreferrer"
          >
            GitHub <ArrowUpRight size={13} />
          </a>
          <a href="mailto:m.rafiq2006@icloud.com">Contact</a>
        </nav>
        <span>© {new Date().getFullYear()} Lumen</span>
      </footer>
    </>
  );
}
export function App({ signupConfig }) {
  return (
    <DemoProvider>
      <MarketingPage signupConfig={signupConfig} />
    </DemoProvider>
  );
}
