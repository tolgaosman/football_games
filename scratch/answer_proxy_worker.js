// Flyball answer-search proxy — Cloudflare Worker (reference implementation).
//
// WHY THIS EXISTS
// The app must NOT ship the Gemini API key (a --dart-define / dotenv key is
// compiled into the APK and trivially extractable). This Worker holds the key
// server-side and is the only thing that talks to Gemini. The app POSTs a prompt
// + budgets to `/answers`; the Worker injects the key + Google Search tool and
// returns Gemini's response body VERBATIM, so the app's existing parser is
// unchanged.
//
// DEPLOY (free tier, ~5 min):
//   1. npm i -g wrangler && wrangler login
//   2. wrangler secret put GEMINI_API_KEY      # paste a FRESH, rotated key
//   3. wrangler deploy answer_proxy_worker.js --name flyball-answer-proxy
//   4. Point the app at the printed URL:
//        flutter run --dart-define=PROXY_BASE_URL=https://flyball-answer-proxy.<you>.workers.dev
//
// SECURITY NOTES
//   - The key lives only in the Worker secret store, never in the app binary.
//   - Basic abuse controls below: method/shape validation, a hard cap on prompt
//     size, and an optional Origin/Referer allowlist. For stronger protection add
//     Cloudflare Rate Limiting Rules or Turnstile in front of this route.

const GEMINI_MODEL = 'gemini-2.5-flash';
const GEMINI_URL =
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

// Hard ceilings so a caller can't ask the Worker to burn unbounded Gemini quota.
const MAX_PROMPT_CHARS = 8000;
const MAX_OUTPUT_TOKENS_CAP = 8192;
const MAX_THINKING_CAP = 4096;

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') {
      return json({ error: 'method_not_allowed' }, 405);
    }
    if (new URL(request.url).pathname !== '/answers') {
      return json({ error: 'not_found' }, 404);
    }

    let payload;
    try {
      payload = await request.json();
    } catch {
      return json({ error: 'invalid_json' }, 400);
    }

    const prompt = typeof payload.prompt === 'string' ? payload.prompt : '';
    if (!prompt || prompt.length > MAX_PROMPT_CHARS) {
      return json({ error: 'invalid_prompt' }, 400);
    }
    const thinkingBudget = clampInt(payload.thinkingBudget, 0, MAX_THINKING_CAP, 512);
    const maxOutputTokens = clampInt(payload.maxOutputTokens, 1, MAX_OUTPUT_TOKENS_CAP, 4096);

    // Mirror the request the app used to make directly, with the key + Google
    // Search grounding tool injected here instead of in the client.
    const geminiBody = JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      tools: [{ google_search: {} }],
      generationConfig: {
        temperature: 0.2,
        thinkingConfig: { thinkingBudget },
        maxOutputTokens,
      },
    });

    let res;
    try {
      res = await fetch(GEMINI_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          // `x-goog-api-key` works for both classic AIza... and newer AQ. keys.
          'x-goog-api-key': env.GEMINI_API_KEY,
        },
        body: geminiBody,
      });
    } catch {
      return json({ error: 'upstream_unreachable' }, 502);
    }

    // Pass Gemini's body straight through so the app's parser sees the exact
    // shape it already understands. Never echo our request headers/key back.
    const text = await res.text();
    return new Response(text, {
      status: res.status,
      headers: { 'Content-Type': 'application/json' },
    });
  },
};

function clampInt(v, min, max, fallback) {
  const n = Number.isFinite(v) ? Math.trunc(v) : fallback;
  return Math.min(max, Math.max(min, n));
}

function json(obj, status) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
