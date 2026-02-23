# Next.js Project Starter Checklist

## 1. Project Init
- [ ] `npx create-next-app@latest --typescript --tailwind --eslint --app --src-dir`
- [ ] Set Node.js version in `.nvmrc` or `package.json` engines
- [ ] Configure `tsconfig.json` — enable `strict`, `noUncheckedIndexedAccess`

## 2. Code Quality
- [ ] ESLint: `@next/eslint-plugin-next` + `eslint-config-prettier`
- [ ] Prettier: `.prettierrc` with consistent settings
- [ ] Husky + lint-staged: pre-commit hooks for lint + format
- [ ] `commitlint`: enforce Conventional Commits

## 3. Environment
- [ ] `.env.local` for local development secrets
- [ ] `.env.example` with all required vars (no values)
- [ ] Zod schema for `process.env` validation at build time
- [ ] Verify `.env` is in `.gitignore`

## 4. Styling
- [ ] Tailwind CSS configured with custom theme
- [ ] CSS variables for theme colors (dark mode support)
- [ ] `globals.css` with base reset and font loading

## 5. Auth (if needed)
- [ ] Auth provider (NextAuth.js / Clerk / Auth0)
- [ ] Middleware for protected routes
- [ ] Session handling in Server Components

## 6. Data Fetching
- [ ] API client with typed responses (Zod inference)
- [ ] Error handling wrapper for `fetch`
- [ ] Revalidation strategy per route (ISR / on-demand)

## 7. Database (if needed)
- [ ] ORM setup (Drizzle / Prisma)
- [ ] Connection pooling for serverless (Neon / PlanetScale)
- [ ] Migration workflow configured

## 8. Testing
- [ ] Vitest for unit tests
- [ ] React Testing Library for component tests
- [ ] Playwright for E2E tests
- [ ] Test CI pipeline configuration

## 9. Performance
- [ ] Bundle analyzer: `@next/bundle-analyzer`
- [ ] Image optimization: `next/image` configured
- [ ] Font optimization: `next/font` with `display: 'swap'`
- [ ] Core Web Vitals baseline measurement

## 10. Deployment
- [ ] CI/CD pipeline: lint -> test -> build -> deploy
- [ ] Preview deployments for PRs
- [ ] Environment variables configured in hosting platform
- [ ] Error monitoring (Sentry / Datadog)
- [ ] Analytics (Vercel Analytics / PostHog)
