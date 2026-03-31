<div align="center">

<img src="public/assets/icon.png" alt="Kivixa Logo" width="120" height="120">

# Kivixa Landing Page

**Production-grade landing page for Kivixa — a privacy-first, local-first, cross-platform productivity workspace.**

[![Next.js](https://img.shields.io/badge/Next.js-16.2-black?logo=nextdotjs)](https://nextjs.org)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind%20CSS-4-06B6D4?logo=tailwindcss)](https://tailwindcss.com)
[![TypeScript](https://img.shields.io/badge/TypeScript-5-3178C6?logo=typescript)](https://www.typescriptlang.org)
[![Framer Motion](https://img.shields.io/badge/Framer%20Motion-12-0055FF?logo=framer)](https://www.framer.com/motion/)

</div>

---

## Overview

This repository contains the landing page website for [Kivixa](https://github.com/990aa/kivixa). It showcases the app's features, download options, platform support, and AI capabilities.

The download links are **dynamically fetched** from the GitHub Releases API, so the page always reflects the latest published release — no manual updates needed.

## Tech Stack

| Technology       | Purpose                              |
|-----------------|--------------------------------------|
| Next.js 16      | App Router, ISR, SSR                 |
| Tailwind CSS 4  | Styling via `@theme` CSS tokens      |
| TypeScript      | Type-safe codebase throughout        |
| Framer Motion   | Scroll-triggered animations          |
| Playwright      | E2E tests with accessibility checks  |

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) 18+
- npm (included with Node.js)

### Install & Run

```bash
# Install dependencies
npm install

# Start the dev server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to see the site.

### Build for Production

```bash
npm run build
npm start
```

## Dynamic Release Data

The page fetches the latest release from the GitHub API at build time and revalidates every hour via ISR:

```
GET https://api.github.com/repos/990aa/kivixa/releases/latest
```

This powers:
- Windows `.exe` download button
- Android ARM64 `.apk` download button
- Version badges throughout the page

If the API is unreachable, hardcoded fallback URLs are used.

## Testing

```bash
# Run E2E tests (requires dev server running)
npm run dev &
npm run test:e2e
```

### Test Coverage

| Test | What it checks |
|------|---------------|
| No browser errors | Page loads without console or runtime errors |
| Renders key sections | Hero, Features, and Download sections are visible |
| Latest GitHub version | Version shown matches GitHub API latest release |
| Download URLs match | Hero CTA + download buttons point to correct release assets |
| Valid download URLs | URLs match expected GitHub release pattern |
| Accessibility | All images have alt text, passes axe-core WCAG 2 AA |

## Screenshots

All screenshots in `public/assets/screenshots/` are from the actual Kivixa application — no placeholders are used.

## About Kivixa

For full details about the Kivixa application itself (features, models, build instructions), see [KIVIXA_README.md](KIVIXA_README.md).

---

<div align="center">

Built with Next.js + Tailwind CSS · Data stays on your device

</div>
