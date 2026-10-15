import { useRef, useState } from 'react';
import { Check, Mail } from 'lucide-react';
import { getSignupConfig, isSignupConfigured } from '../siteConfig.js';
import { isValidEmail, normalizeEmail, submitWaitlist } from '../waitlistSubmit.js';
import { trackWaitlistEvent } from '../waitlistAnalytics.js';

export function Waitlist({ config = getSignupConfig(), submit = submitWaitlist }) {
  const [email, setEmail] = useState('');
  const [status, setStatus] = useState('idle');
  const [message, setMessage] = useState('');
  const pending = useRef(false);
  const configured = isSignupConfigured(config);
  const handleSubmit = async event => {
    event.preventDefault();
    if (pending.current) return;
    if (!isValidEmail(normalizeEmail(email))) { setStatus('error'); setMessage('Enter a valid email address.'); return; }
    pending.current = true;
    trackWaitlistEvent('submit_attempt', { source: 'lumen-site' });
    setStatus('loading'); setMessage('');
    try {
      const result = await submit(email, config);
      setStatus('success');
      trackWaitlistEvent('submit_success', { source: 'lumen-site' });
      setMessage(result.status === 'duplicate' ? 'This email is already on the waitlist. You’re all set.' : 'You’re on the waitlist. We’ll email when a beta spot is available.');
      setEmail('');
    } catch (error) { setStatus('error'); setMessage(error.message); trackWaitlistEvent('submit_error', { source: 'lumen-site' }); }
    finally { pending.current = false; }
  };
  return <section className="section signup-section" id="access" aria-labelledby="signup-heading"><div className="signup-copy"><span className="section-kicker">A little less to manage</span><h2 id="signup-heading">Come home<br />to something calmer.</h2><p>Join the Lumen waitlist for beta updates. We’ll let you know when a spot is available for iPhone and iPad.</p></div><div className="signup-panel">{configured ? <form noValidate onSubmit={handleSubmit}><label htmlFor="waitlist-email">Your email address</label><input id="waitlist-email" type="email" autoComplete="email" name="email" placeholder="you@example.com" value={email} onChange={event => { setEmail(event.target.value); if (status === 'error') { setStatus('idle'); setMessage(''); } }} aria-invalid={status === 'error' || undefined} aria-describedby="signup-message signup-privacy" required disabled={status === 'loading'} /><button className="button button-primary" disabled={status === 'loading'}>{status === 'loading' ? 'Joining…' : status === 'success' ? <><Check size={17} /> Join another email</> : 'Join the waitlist'}</button><div id="signup-message" className={`signup-message ${status}`} role={status === 'error' ? 'alert' : 'status'}>{message}</div></form> : <div className="email-alternative"><Mail size={24} /><h3>Let’s keep in touch.</h3><p>Online signup is currently unavailable. You can email us to request a place on the waitlist.</p><a className="button button-primary" href={`mailto:${config.contactEmail}?subject=Lumen%20waitlist`}>Email to request access</a><p className="small-note">This opens your email app. Send the message to contact us; it does not automatically join the waitlist.</p></div>}<p id="signup-privacy" className="small-note">Beta updates only. Your address is used to manage your request. <a href="/privacy">Read our privacy policy</a>.</p>{configured && <a className="signup-contact" href={`mailto:${config.contactEmail}`}>Having trouble? Contact us</a>}</div></section>;
}
