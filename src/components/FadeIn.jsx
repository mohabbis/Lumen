import { motion } from 'framer-motion';
import { useReducedMotion } from '../hooks/useReducedMotion.js';

/**
 * A single, quiet reveal.
 *
 * Deliberately minimal: one section-level fade with a short travel, no
 * per-item stagger and no configurable delay. A page that animates every
 * card in on scroll reads as decoration; one settle per section reads as
 * the page arriving. Honours prefers-reduced-motion by rendering static.
 */
export function FadeIn({ children, className = '' }) {
  const reducedMotion = useReducedMotion();

  if (reducedMotion) {
    return <div className={className}>{children}</div>;
  }

  return (
    <motion.div
      className={className}
      initial={{ opacity: 0, y: 8 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.32, ease: 'easeOut' }}
    >
      {children}
    </motion.div>
  );
}
