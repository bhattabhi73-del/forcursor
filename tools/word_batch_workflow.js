export const meta = {
  name: 'thai-vocab-batch',
  description: 'Generate, verify, and integrate one themed batch of Thai vocabulary (~150 words)',
  phases: [
    { title: 'Generate', detail: 'one generator per theme + coverage gap-filler' },
    { title: 'Verify', detail: 'strict Thai-teacher check per sub-batch' },
    { title: 'Integrate', detail: 'inject Swift + android JSON, typecheck, commit' },
  ],
}

// args = output of tools/prepare_batch.py:
// { batch, next_id, total, target, words_per_theme, themes: [{name, category,
//   level, hint, existing: []}], gap_tokens: [] }

const CONVENTIONS = `
CONTENT CONVENTIONS (authoritative — follow exactly):
- "thai": real Thai script only. Single words or short common compounds actually used in Thai. No invented words.
- "roman": tone-marked Latin romanization (use à á ǎ â style tone marks), syllables joined with hyphens. House style is k/t/p: NEVER write g/dt/bp at syllable start (write "kài" not "gài", "tam" not "dtam", "pai" not "bpai").
- "hindiPron": Devanagari PRONUNCIATION transliteration (how to SAY the Thai word), NOT a translation. Rules: น้ำ standalone = नाम but SHORT नम inside compounds (น้ำตาล = नम-तान). The เ-ิ "er" vowel is written with र्: เปิด = पर्द, เดิน = दर्न, เงิน = ङर्न. Syllables joined with hyphens.
- "en": concise English meaning. "hi": Hindi TRANSLATION (not transliteration).
- "category": use exactly the category name you are given.
- "examples": exactly 2 short natural sentences (3–7 words) per word, each with thai/roman/en/hi (hi = Hindi translation of the sentence). Keep sentences VERY simple: reuse ubiquitous Thai words (ผม ฉัน คุณ เขา ไม่ มาก ดี กิน ไป มา อยู่ ที่ นี่ ครับ ค่ะ อร่อย ชอบ) plus the target word, because every Thai word inside a sentence must eventually exist in our dictionary.
- No double quotes (") or backslashes anywhere in any field.
`

const WORDS_SCHEMA = {
  type: 'object', required: ['words'],
  properties: {
    words: {
      type: 'array',
      items: {
        type: 'object',
        required: ['thai', 'roman', 'hindiPron', 'en', 'hi', 'category', 'examples'],
        properties: {
          thai: { type: 'string' }, roman: { type: 'string' },
          hindiPron: { type: 'string' }, en: { type: 'string' },
          hi: { type: 'string' }, category: { type: 'string' },
          examples: {
            type: 'array',
            items: {
              type: 'object', required: ['thai', 'roman', 'en', 'hi'],
              properties: {
                thai: { type: 'string' }, roman: { type: 'string' },
                en: { type: 'string' }, hi: { type: 'string' },
              },
            },
          },
        },
      },
    },
  },
}

const INTEGRATE_SCHEMA = {
  type: 'object', required: ['added', 'total'],
  properties: {
    added: { type: 'number' }, total: { type: 'number' },
    skipped_dupes: { type: 'number' }, rejected: { type: 'number' },
    commit: { type: 'string' }, pushed: { type: 'boolean' },
    error: { type: 'string' }, notes: { type: 'string' },
  },
}

function genPrompt(item) {
  if (item.type === 'gaps') {
    return `You are creating Thai vocabulary entries for a Thai-learning app for Hindi+English speakers.

These Thai strings appear inside our example sentences but are NOT yet dictionary entries (found by greedy segmentation, so some are broken fragments):
${JSON.stringify(item.tokens)}

For each token that is a REAL standalone Thai word or particle (e.g. ๆ the repetition mark IS valid as an entry), create a dictionary entry. SKIP fragments that are not real standalone words (single orphan letters like "เ", partial syllables like "เรี"). Choose a sensible existing-style category (e.g. "Grammar Core", "Verbs", "Time").
${CONVENTIONS}
Return ONLY the words array via structured output. Quality over quantity — skipping is better than inventing.`
  }
  const t = item.t
  return `You are creating Thai vocabulary entries for a Thai-learning app for Hindi+English speakers.

THEME: ${t.name} — ${t.hint}
CATEGORY (use exactly): ${t.category}
Generate ${item.count} DISTINCT words for this theme.

Words already in this category — do NOT repeat any of them:
${t.existing.length ? t.existing.join(', ') : '(none yet)'}
${CONVENTIONS}
Pick genuinely useful, natural, frequent words for this theme and level. Return ONLY the words array via structured output.`
}

function verifyPrompt(item, generated) {
  return `You are a STRICT Thai language teacher reviewing vocabulary entries for a published learning app (theme: ${item.type === 'gaps' ? 'coverage gap fillers' : item.t.name}). Empty results are preferred over invented or wrong content.

Review every entry below. For each:
1. Is the Thai spelling a real, correctly spelled Thai word in normal use?
2. Does the romanization match the actual pronunciation, tones included, in k/t/p house style?
3. Does the Devanagari follow the pronunciation rules given?
4. Are the English and Hindi meanings correct? Are both example sentences natural, grammatical Thai with correct translations?

FIX small errors in place. DROP any entry you are not fully sure about (wrong word, dubious existence, unfixable example). You may trim an entry to 1 example if the other is bad.
${CONVENTIONS}
ENTRIES:
${JSON.stringify(generated.words)}

Return the corrected list via structured output.`
}

let A = typeof args === 'string' ? JSON.parse(args) : args
if (!A || !A.themes) {
  A = await agent(
    'Run `python3 tools/prepare_batch.py` from the repo root /Users/amitbh/Desktop/forcursor and return the JSON it prints on stdout, exactly and completely, via structured output. Do not modify any files.',
    { label: 'plan', phase: 'Generate',
      schema: {
        type: 'object', required: ['batch', 'themes', 'total', 'target', 'words_per_theme'],
        properties: {
          batch: { type: 'number' }, next_id: { type: 'number' },
          total: { type: 'number' }, target: { type: 'number' },
          words_per_theme: { type: 'number' },
          themes: { type: 'array' }, gap_tokens: { type: 'array' },
        },
      } })
}
if (A.total >= A.target) return { done: true, total: A.total }

const items = [
  ...A.themes.map(t => ({ type: 'theme', t, count: A.words_per_theme })),
  ...(A.gap_tokens && A.gap_tokens.length >= 5
    ? [{ type: 'gaps', tokens: A.gap_tokens }] : []),
]

const verified = await pipeline(
  items,
  item => agent(genPrompt(item), {
    label: `gen:${item.type === 'gaps' ? 'gap-fill' : item.t.name}`,
    phase: 'Generate', schema: WORDS_SCHEMA,
  }),
  (gen, item) => gen && gen.words.length
    ? agent(verifyPrompt(item, gen), {
        label: `verify:${item.type === 'gaps' ? 'gap-fill' : item.t.name}`,
        phase: 'Verify', schema: WORDS_SCHEMA,
      })
    : { words: [] },
)

const words = verified.filter(Boolean).flatMap(v => v.words)
log(`${words.length} words survived verification across ${items.length} sub-batches`)

if (!words.length) return { batch: A.batch, added: 0, error: 'no words survived verification' }

const nnn = String(A.batch).padStart(3, '0')
const result = await agent(`You are the integrator for Thai Learn vocab batch ${A.batch}. Repo root: /Users/amitbh/Desktop/forcursor

1. Write this exact JSON to tools/batches/batch_${nnn}.json (use the Write tool; content below, as-is):
${JSON.stringify({ batch: A.batch, themes: A.themes.map(t => ({ name: t.name })), words })}

2. Run from the repo root: python3 tools/integrate_batch.py tools/batches/batch_${nnn}.json --commit
   (It validates, dedupes, injects Swift literals, regenerates android vocabulary.json, typechecks, commits and pushes. The last line of stdout is a JSON summary.)

3. If it reports "typecheck failed", read the stderr it printed, remove ONLY the offending entries from the batch JSON, and run the script once more. Do not retry more than twice total.

Report the final summary via structured output (added/total/commit/etc; put anything noteworthy in notes).`,
  { label: 'integrate+commit', phase: 'Integrate', schema: INTEGRATE_SCHEMA })

return { batch: A.batch, submitted: words.length, ...result }
