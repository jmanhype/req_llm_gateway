# Planning Guide

An interactive technical specification dashboard for RecLLMGateway - an OpenAI-compatible LLM proxy with telemetry, usage tracking, and multi-provider routing for Elixir/Phoenix applications.

**Experience Qualities**:
1. **Technical & Informative** - Clear presentation of complex API specifications and architectural decisions with visual hierarchy
2. **Interactive & Explorable** - Tabbed navigation allowing developers to explore different aspects of the spec (API, Components, Usage)
3. **Professional & Developer-Focused** - Code-centric design with syntax highlighting and practical examples

**Complexity Level**: Light Application (multiple features with basic state)
- This is a documentation/specification viewer with interactive tabs, code examples, and visual flow diagrams. It presents technical content in an organized, navigable format without backend persistence.

## Essential Features

### Tabbed Navigation
- **Functionality**: Switch between Overview, API Contract, Components, Configuration, Usage Examples, and Testing sections
- **Purpose**: Organize dense technical content into digestible sections
- **Trigger**: Click on tab buttons in the header
- **Progression**: User clicks tab → Content smoothly transitions → Selected tab highlighted → New content displayed
- **Success criteria**: All sections accessible, smooth transitions, clear visual indication of active section

### Interactive Code Examples
- **Functionality**: Display formatted code snippets with language indicators and copy functionality
- **Purpose**: Help developers understand request/response formats and implementation details
- **Trigger**: Navigate to sections containing code examples
- **Progression**: Section loads → Code blocks rendered with syntax highlighting → Hover reveals copy button → Click copies to clipboard
- **Success criteria**: All code examples properly formatted, easy to copy, language clearly identified

### Architecture Visualization
- **Functionality**: Visual diagram showing request flow from client through gateway to providers
- **Purpose**: Illustrate how the gateway routes requests and handles responses
- **Trigger**: View Overview or API Contract sections
- **Progression**: Section loads → Animated flow diagram appears → Arrows show data flow → Hover highlights components
- **Success criteria**: Clear visual representation of system architecture, smooth animations

### Component Browser
- **Functionality**: Browse and explore the 6 core Elixir modules with descriptions
- **Purpose**: Help developers understand the codebase structure and responsibilities
- **Trigger**: Navigate to Components tab
- **Progression**: Tab selected → Component cards displayed → Click card to expand → View detailed description and key functions
- **Success criteria**: All components listed, descriptions accurate, expandable for details

### Model Format Validator
- **Functionality**: Interactive tool to test the provider:model parsing logic
- **Purpose**: Help developers understand the model routing syntax
- **Trigger**: Enter model string in validator input
- **Progression**: Type model name → Live validation feedback → Shows parsed provider and model → Displays error for invalid formats
- **Success criteria**: Accurate parsing feedback, clear error messages, examples provided

## Edge Case Handling

- **Empty States**: Show helpful prompts when validator is empty or no tab selected
- **Invalid Model Formats**: Display clear error messages with format examples
- **Long Code Blocks**: Implement scrollable containers with fixed max-height
- **Mobile Navigation**: Collapse tabs into dropdown menu on small screens
- **Copy Failures**: Show toast notification when clipboard copy succeeds or fails

## Design Direction

The design should feel professional, technical, and developer-focused - like reading high-quality API documentation (Stripe, GitHub) with the polish of a modern SaaS dashboard. Clean, spacious interface with generous white space to prevent overwhelming the user with dense technical content.

## Color Selection

**Triadic color scheme** - Using purple (technical/innovation), teal (trust/stability), and orange (energy/action) to create a modern developer tool aesthetic with clear visual hierarchy.

- **Primary Color**: Deep Purple `oklch(0.45 0.15 290)` - Represents technical sophistication and innovation, used for main CTAs and headings
- **Secondary Colors**: 
  - Teal `oklch(0.55 0.12 195)` - Supporting color for code blocks and technical elements, conveys reliability
  - Orange `oklch(0.65 0.15 45)` - Accent for interactive elements and highlights
- **Accent Color**: Bright Orange `oklch(0.70 0.18 40)` - Attention-grabbing for active states and important CTAs, creates visual pop
- **Foreground/Background Pairings**:
  - Background (White `oklch(0.99 0 0)`): Dark Gray text `oklch(0.25 0 0)` - Ratio 13.5:1 ✓
  - Card (Light Gray `oklch(0.97 0 0)`): Dark Gray text `oklch(0.25 0 0)` - Ratio 12.8:1 ✓
  - Primary (Deep Purple `oklch(0.45 0.15 290)`): White text `oklch(0.99 0 0)` - Ratio 7.2:1 ✓
  - Secondary (Light Purple `oklch(0.94 0.03 290)`): Dark Purple text `oklch(0.35 0.12 290)` - Ratio 8.5:1 ✓
  - Accent (Bright Orange `oklch(0.70 0.18 40)`): Dark Gray text `oklch(0.20 0 0)` - Ratio 6.1:1 ✓
  - Muted (Cool Gray `oklch(0.95 0.01 250)`): Medium Gray text `oklch(0.50 0.02 250)` - Ratio 6.8:1 ✓

## Font Selection

Use **Inter** for its excellent readability at all sizes and technical documentation feel, paired with **JetBrains Mono** for code blocks to maintain professional developer aesthetic.

- **Typographic Hierarchy**:
  - H1 (Page Title): Inter Bold/32px/tight letter-spacing (-0.02em) - "RecLLMGateway MVP"
  - H2 (Section Headers): Inter Semibold/24px/normal letter-spacing - Tab titles, component names
  - H3 (Subsections): Inter Semibold/18px/normal - Code block headers, feature titles
  - Body (Content): Inter Regular/16px/1.6 line-height - Documentation text
  - Code (Inline): JetBrains Mono Regular/14px/1.5 line-height - Model examples, variables
  - Code Blocks: JetBrains Mono Regular/13px/1.6 line-height - Full code examples
  - Labels: Inter Medium/14px/uppercase/tracked (0.05em) - Tab labels, badges

## Animations

Subtle, purposeful animations that enhance the developer experience without slowing down information access - smooth tab transitions and gentle hover effects create polish while maintaining snappy interaction.

- **Purposeful Meaning**: Motion communicates state changes (tab switching) and provides feedback (hover effects on interactive elements), creating a refined experience
- **Hierarchy of Movement**: 
  - Primary: Tab transitions (300ms ease) - most important navigation action
  - Secondary: Code copy button appearance (150ms ease) - interactive feedback
  - Tertiary: Card hover effects (200ms ease) - subtle visual enrichment

## Component Selection

- **Components**: 
  - **Tabs** - Primary navigation between specification sections, modified with custom pill-style active indicators
  - **Card** - Container for component descriptions, code examples, and feature blocks with subtle shadows
  - **Badge** - Indicate provider types (OpenAI, Anthropic), HTTP methods (POST), status codes
  - **Button** - Copy code actions, primary CTAs, modified with icon support
  - **Input** - Model format validator with inline validation feedback
  - **ScrollArea** - Contain long code blocks without breaking layout
  - **Separator** - Divide sections visually within tabs
  - **Alert** - Highlight important notes about OpenAI compatibility and design decisions
  
- **Customizations**: 
  - Custom syntax highlighting component for code blocks (not in shadcn)
  - Visual flow diagram component using SVG for architecture visualization
  - Animated gradient background for hero section
  
- **States**: 
  - Tabs: Active (primary color), Hover (lighter primary), Inactive (muted)
  - Buttons: Default (primary), Hover (darker primary with lift), Active (pressed), Disabled (muted)
  - Input: Default (border), Focus (primary ring), Error (destructive border), Success (teal border)
  
- **Icon Selection**: 
  - `Code` - Code examples and technical content
  - `GitBranch` - Architecture/routing concepts
  - `Gauge` - Telemetry and monitoring features
  - `Copy` - Copy to clipboard actions
  - `Check` - Validation success states
  - `Warning` - Error states and important notes
  - `Play` - Usage examples section
  - `Package` - Component/module representations
  
- **Spacing**: 
  - Page padding: `px-6` (24px) mobile, `px-12` (48px) desktop
  - Section gaps: `gap-8` (32px) for major sections
  - Card padding: `p-6` (24px)
  - Component gaps: `gap-4` (16px) for related elements
  - Tight grouping: `gap-2` (8px) for labels and values
  
- **Mobile**: 
  - Tabs collapse into horizontal scrollable strip with snap points
  - Code blocks remain scrollable horizontally with touch-friendly scroll
  - Two-column layouts stack into single column below 768px
  - Larger touch targets (44px min) for all interactive elements
  - Hero section reduces text size and padding on mobile
