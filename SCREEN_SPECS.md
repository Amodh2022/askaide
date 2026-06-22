# AskAide — Screen-by-screen specs (source of truth for UI)

Reference live site: https://askaide.in · React repo: github.com/AskAide-AI/frontend

## Global visual language (ALL screens)
- Warm paper bg `#F4F1EA`, cards `#FBF9F3` w/ 1px `#D9D4C7` border + soft shadow.
- Fraunces serif headings (often ONE word in italic). Inter Tight body. JetBrains Mono UPPERCASE micro-labels ("— SECTION NAME", wide letter-spacing, muted).
- Deep-green `#2E5D4F` accent; mustard `#E8D16A` used as a hand-drawn underline swipe behind emphasis words.
- Primary buttons = dark pills; secondary = outlined pills.
- Full dark-mode parity (`#14140F` bg, `#8FBFA8` accent).
- Floating WhatsApp FAB bottom-right on PUBLIC pages.
- Every screen: fade-up scroll reveals, count-up numbers, marquee ticker.

## Public top navbar
Left: "a" rounded-square mark + "askaide" serif + tiny "AI" mono. Center: Try Free · Free Papers · For Schools · Blog · Features. Right: theme toggle (sun/moon), "Sign in" text, dark pill "Try a session →".

## Landing `/` (max-width ~1280, generous padding)
1. HERO 2-col. LEFT: mono "— A PRACTICE PLATFORM · CLASSES 6–12"; giant serif "Do the *work*, not the watching." (mustard underline behind "work", "watching" muted); subtext; stats row (pulsing green ● LIVE + count-up "63 students learning", "10,000+ questions answered", "CBSE · ICSE · State"); two pill CTAs ("Start a free session →", "See school pricing"); shield "Free forever • No credit card"; mono "do, don't watch". RIGHT: tilted ~-0.5deg "STUDY CALCULATOR" card — 3 sliders (Days 7–90, Questions/day 5–20, Target mastery 50–95%) → live result "YOUR ESTIMATED RESULT / {n} questions mastered".
2. TICKER: full-width bordered strip, infinite horizontal marquee of board+partner names (mono).
3. "Why practice *beats* watching." → 3 cards: "01 / 03" + method chip + 120px patterned illustration box w/ Lucide icon (Focus, SlidersHorizontal, Timer) + serif title + muted text.
4. "How it works" (card bg, bordered) → 3 cells split by hairlines: "01/02/03" + serif title + desc.
5. "One platform, every *stakeholder*." → 4 role cards (Students/Teachers/Parents/Schools) in 1px-gap grid: serif title, "—" bulleted list, optional accent link.
6. Testimonials → responsive grid; each: 5 mustard stars, serif quote, circular initials avatar + name + mono "🇮🇳 ROLE · CITY".
7. Community + Leaderboard → stat cards (Study Forum 2,500/15,000/4.2; Weekly Challenges 50/500/₹5,000; Weekly Rankings 1st/2nd/3rd; Skill Badges 5/50/90%).
8. FAQ → left mono label + serif "Questions, *answered.*"; right accordion rows w/ rotating "+".
9. Final CTA → dark full-bleed, "◉ READY?", massive serif "Start *practising.*" (accent italic), pill CTA.
10. Footer → brand blurb + Product/Popular/Legal columns + "© 2026 ASKAIDE · BENGALURU · DELHI" + GitHub/LinkedIn icons.

## Login `/login` (no navbar, centered ~530px)
mono "— WELCOME BACK"; serif "Sign *in.*"; subtext "The next 10 minutes of practice are waiting." Fields: EMAIL (placeholder "you@school.in"), PASSWORD (eye toggle) + inline "Forgot password?". Checkbox "Keep me signed in". Dark pill "Sign in to your account →". Divider → outlined pills "G Google", "🏫 School SSO". "🔒 Your data is encrypted and secure". Bottom: "New to AskAide? Create an account →". DO NOT auto-submit / auto-run SSO.

## Signup `/signup` (3-step wizard, top-right "STEP 1 / 3")
mono "— ACCOUNT"; serif "Create *account.*"; "Three fields. No card, no spam."; "Join 10,000+ students…". Fields: YOUR NAME, EMAIL, SET A PASSWORD (eye toggle, "Min. 6 characters"), CONFIRM PASSWORD. Checkbox "I want to receive study tips and motivation". Dark pill "Create account →". Account creation is the user's action.

## `/try` → TryNow then practice
TryNow: mono "— FREE TRIAL"; serif "Try three *questions.*"; card "READY TO PRACTICE" + serif topic + "{class} · {subject}" + "⌄ Change topic" expander + dark pill "Start practicing →". Below: stat strip (63+ / 10,000++ / CBSE·ICSE·State) + "— DIFFICULTY CALCULATOR" card (EASY/MEDIUM/HARD).
Practice (also core `/study` QuestionPractice): header "FREE PRACTICE TRIAL / Question 1 of 3" + right "0/0 correct"; accent banner "Sign up after to save your progress…"; question card → text, MCQ buttons or fill-in input, submit, inline correct/incorrect feedback + explanation, next.

## Free paper generator `/free-paper-generator` (2-step wizard)
mono "— FREE PAPER GENERATOR · CBSE · ICSE · STATE BOARDS"; serif "A paper in *seconds.*"; stat strip. Stepper tabs "①  Class & Subject" | "②  Chapters". Step 1: "SELECT CLASS" pills 6th–12th + "SELECT SUBJECT". Step 2: chapter multi-select → generate → PDF (pdf/printing) + WhatsApp delivery (url_launcher wa.me).

## For Schools `/for-schools`
mono "— FOR PRINCIPALS & HEADS OF SCHOOL"; huge serif "A daily habit, *measurable* by week 6." CTAs: dark pill "Book a principal's demo →", green pill "Free paper generator →", text "Email us". Stat row (serif numbers): +34% mastery, 92% weekly active, ₹200 student/yr, 40 sec to first question, 15-25% score improvement, 45 days.

## Authenticated app shell (desktop ≥768px = 240px left sidebar; mobile = bottom nav + hamburger)
Sidebar: logo + user avatar + role chip on top; grouped nav LEARN/MANAGE/ACCOUNT (role-filtered, Lucide icons, active = serif font + accent-light bg + dot); bottom = theme toggle + red "Sign out".
Screens: /dashboard (role variants, gamified for students, fl_chart), /progress (subject→chapter→topic mastery cards + AI insights), /quizzes + attempt(timed)/result/history, /question-paper generator+preview+history, /profile, /settings, /referral, floating AI assistant chat widget (markdown answers, PDF download).
