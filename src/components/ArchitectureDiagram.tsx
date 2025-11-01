import { motion } from 'framer-motion'

export function ArchitectureDiagram() {
  return (
    <div className="w-full py-8">
      <svg
        viewBox="0 0 800 400"
        className="w-full max-w-4xl mx-auto"
        style={{ maxHeight: '400px' }}
      >
        <motion.g
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <rect
            x="50"
            y="150"
            width="120"
            height="100"
            rx="12"
            fill="oklch(0.94 0.03 290)"
            stroke="oklch(0.45 0.15 290)"
            strokeWidth="2"
          />
          <text x="110" y="205" textAnchor="middle" className="fill-foreground font-semibold text-sm">
            Client App
          </text>
        </motion.g>

        <motion.g
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.5, delay: 0.2 }}
        >
          <rect
            x="340"
            y="120"
            width="160"
            height="160"
            rx="16"
            fill="oklch(0.45 0.15 290)"
            stroke="oklch(0.35 0.18 290)"
            strokeWidth="3"
          />
          <text x="420" y="160" textAnchor="middle" className="fill-primary-foreground font-bold text-base">
            RecLLMGateway
          </text>
          <text x="420" y="190" textAnchor="middle" className="fill-primary-foreground/80 text-xs">
            /v1/chat/completions
          </text>
          <text x="420" y="220" textAnchor="middle" className="fill-primary-foreground/70 text-xs">
            • Parse provider:model
          </text>
          <text x="420" y="240" textAnchor="middle" className="fill-primary-foreground/70 text-xs">
            • Emit telemetry
          </text>
          <text x="420" y="260" textAnchor="middle" className="fill-primary-foreground/70 text-xs">
            • Track usage (ETS)
          </text>
        </motion.g>

        <motion.g
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
        >
          <rect
            x="620"
            y="80"
            width="130"
            height="80"
            rx="12"
            fill="oklch(0.55 0.12 195)"
            stroke="oklch(0.45 0.14 195)"
            strokeWidth="2"
          />
          <text x="685" y="115" textAnchor="middle" className="fill-teal-foreground font-semibold text-sm">
            OpenAI
          </text>
          <text x="685" y="135" textAnchor="middle" className="fill-teal-foreground/80 text-xs">
            gpt-4o-mini
          </text>
        </motion.g>

        <motion.g
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.5 }}
        >
          <rect
            x="620"
            y="240"
            width="130"
            height="80"
            rx="12"
            fill="oklch(0.65 0.15 45)"
            stroke="oklch(0.55 0.18 45)"
            strokeWidth="2"
          />
          <text x="685" y="275" textAnchor="middle" className="fill-orange-foreground font-semibold text-sm">
            Anthropic
          </text>
          <text x="685" y="295" textAnchor="middle" className="fill-orange-foreground/80 text-xs">
            claude-3-sonnet
          </text>
        </motion.g>

        <motion.path
          d="M 170 200 L 340 200"
          stroke="oklch(0.45 0.15 290)"
          strokeWidth="2"
          fill="none"
          markerEnd="url(#arrowhead)"
          initial={{ pathLength: 0 }}
          animate={{ pathLength: 1 }}
          transition={{ duration: 0.8, delay: 0.6 }}
        />

        <motion.path
          d="M 500 160 L 620 120"
          stroke="oklch(0.55 0.12 195)"
          strokeWidth="2"
          fill="none"
          markerEnd="url(#arrowhead-teal)"
          initial={{ pathLength: 0 }}
          animate={{ pathLength: 1 }}
          transition={{ duration: 0.8, delay: 0.8 }}
        />

        <motion.path
          d="M 500 240 L 620 280"
          stroke="oklch(0.65 0.15 45)"
          strokeWidth="2"
          fill="none"
          markerEnd="url(#arrowhead-orange)"
          initial={{ pathLength: 0 }}
          animate={{ pathLength: 1 }}
          transition={{ duration: 0.8, delay: 1.0 }}
        />

        <defs>
          <marker
            id="arrowhead"
            markerWidth="10"
            markerHeight="10"
            refX="9"
            refY="3"
            orient="auto"
          >
            <polygon points="0 0, 10 3, 0 6" fill="oklch(0.45 0.15 290)" />
          </marker>
          <marker
            id="arrowhead-teal"
            markerWidth="10"
            markerHeight="10"
            refX="9"
            refY="3"
            orient="auto"
          >
            <polygon points="0 0, 10 3, 0 6" fill="oklch(0.55 0.12 195)" />
          </marker>
          <marker
            id="arrowhead-orange"
            markerWidth="10"
            markerHeight="10"
            refX="9"
            refY="3"
            orient="auto"
          >
            <polygon points="0 0, 10 3, 0 6" fill="oklch(0.65 0.15 45)" />
          </marker>
        </defs>
      </svg>
    </div>
  )
}
