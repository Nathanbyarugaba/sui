---
name: protocol-verify
description: Theorem-driven protocol verification: promise -> property -> counterexample -> repair -> prove -> refine -> regression
---

# Protocol Verify

Theorem-driven protocol verification.

```javascript
export const meta = {
 name: 'protocol-verify',
 description: 'Theorem-driven protocol verification: promise → property → counterexample → repair → prove → refine → regression',
 whenToUse: 'Security research on a blockchain/protocol mechanism where every claim must be a falsifiable theorem, not a generic review comment. Pass a target via args.',
 phases: [
   { title: 'Triage', detail: 'Rank subsystems by loss-of-funds / consensus / novelty / concurrency risk (Phase 1)' },
   { title: 'Model', detail: 'Reconstruct each mechanism as a state machine — actors, state, views, transitions, time, exceptions (Phase 2)' },
   { title: 'Specify', detail: 'Convert promises into ranked, falsifiable property registry entries (Phase 3)' },
   { title: 'Falsify', detail: '>=2 independent, mutually-blind adversary passes per property search for the smallest counterexample (Phase 4)' },
   { title: 'Adjudicate', detail: 'A skeptic actively tries to REFUTE each candidate counterexample (agent separation)' },
   { title: 'Refine', detail: 'Derive D_safe from the property; find unsafe permissiveness AND unnecessary reverts; map model->code divergence (Phases 5 & 7)' },
   { title: 'Prove', detail: 'Formalize model + theorem in Rocq (.v), run `rocq compile`, earn MACHINE_CHECKED_PROOF only on a Qed-closed, admit/axiom-free compile (Phase 6)' },
   { title: 'Evidence', detail: 'Emit the regression battery pinned to the counterexample and the Rocq obligation (Phase 8)' },
   { title: 'Synthesize', detail: 'Assemble the property -> counterexample -> code path -> fix -> Rocq proof -> regression evidence chain' },
 ],
}

// ---------------------------------------------------------------------------
// Target configuration (Phase 1 inputs). args may be a string (mechanism) or
// an object. Everything falls back to sensible defaults for the local repo.
// ---------------------------------------------------------------------------
let cfg = args || {}
if (typeof cfg === 'string') {
 const s = cfg.trim()
 // args may arrive as a JSON string; parse it if so, else treat it as a mechanism name.
 if (s.startsWith('{')) { try { cfg = JSON.parse(s) } catch { cfg = { mechanism: s } } }
 else cfg = { mechanism: s }
}
const T = {
 protocol: cfg.protocol || 'Pyth Cross-Chain',
 version: cfg.version || 'local working tree (see `git rev-parse HEAD`)',
 repoPath: cfg.repoPath || 'pyth-crosschain',
 mechanism: cfg.mechanism || null,          // null => run the triage/prioritizer phase
 files: cfg.files || null,                  // optional explicit file globs / paths
 adversary: cfg.adversary || 'arbitrary transaction ordering; control of a non-privileged actor; ability to deploy and call untrusted contracts; observe all public state and mempool',
 assumptions: cfg.assumptions || 'honest supermajority of validators/guardians; cryptographic primitives sound; the compiler/toolchain is correct unless a representation bug is the finding',
}
// Scale depth: honor an explicit "+Nk" budget if present, else conservative defaults.
const PASSES = cfg.passes || 2                                  // independent blind adversary passes per property
const MAX_MECHANISMS = cfg.maxMechanisms || (T.mechanism ? 1 : 3)
const MAX_PROPS = cfg.maxProperties || 6                        // cap properties carried into falsification per model

const TARGET_BLOCK = `TARGET
- Protocol: ${T.protocol}
- Version: ${T.version}
- Repository root (read with Read/Grep/Bash, cite exact symbols + line numbers): ${T.repoPath}
- In-scope mechanism: ${T.mechanism || '(to be selected by the Triage phase)'}
- Source materials: ${T.files || 'discover within the repo; prefer on-chain contracts, verifiers, serialization, and consensus/execution boundaries'}
- Adversary capabilities: ${T.adversary}
- Trust assumptions: ${T.assumptions}
- Testing environment: authorized local checkout only.`

const RULES = `HARD RULES (do not violate):
- Treat every security claim as a THEOREM CANDIDATE. No generic review, no speculative vuln lists.
- Never claim a vulnerability without a concrete, executable trace with exact state values.
- Never report "no counterexample found" as "proved". Never claim "proved" unless it is machine-checked.
- Never invent missing semantics — mark them UNKNOWN and treat as UNDER_SPECIFIED.
- Cite exact code symbols and line numbers (file:line) whenever available.
- Keep design-level findings separate from implementation-level findings.
- State uncertainty explicitly.
- Valid status labels ONLY: COUNTEREXAMPLE_FOUND | UNDER_SPECIFIED | NO_COUNTEREXAMPLE_WITHIN_BOUND | PROOF_SKETCH_ONLY | MACHINE_CHECKED_PROOF`

const LENSES = `HIGH-VALUE LENSES (apply all that are relevant):
- Mutation completeness: is every INDIRECTLY changed account/pool/position/message checked, not just the sender/initiator?
- Exception symmetry: are enable/disable, delegate/undelegate, grant/revoke, deposit/withdraw, activate/deactivate treated consistently?
- Temporal consistency: what rule does each component use at n, n+K, n+2K? Are they compatible?
- Speculative assumptions: for each speculative read, exactly what dependency is recorded and validated at merge?
- Pre-state vs post-state: is status determined before or after the transition, and which does the property require?
- Cross-layer assumptions: which component assumes another enforces the property, and where is that enforcement actually implemented?
- Noninterference: can an untrusted callee affect the caller outside explicitly permitted output channels?
- Representation semantics: does the language/ABI/storage layout/compiler implement the intended mathematical/byte-level operation (UB, int widths, endianness)?
- Permissiveness: is the protection rejecting/retrying/locking behavior that is actually safe?
- Liveness: can an accepted input reach panic, abort, deadlock, infinite retry, or unbounded work?`

// Rocq (The Rocq Prover 9.1.x, formerly Coq) is installed: `rocq compile FILE.v` (fallback `coqc FILE.v`).
const PROOFS_DIR = 'research/proofs'
const ROCQ = `ROCQ PROOF PROTOCOL (The Rocq Prover 9.1.x — formerly Coq — IS installed on this machine):
- Write the formal artifact to ${PROOFS_DIR}/<propId>.v (run \`mkdir -p ${PROOFS_DIR}\` first).
- Formalize the ABSTRACT MODEL as Rocq: state as a Record/Inductive, the transition relation as an Inductive or a step function, actors/views/time as needed. Keep it faithful to the reconstructed model but no larger than necessary.
- State the property as a Theorem/Lemma with EXPLICIT quantifiers (forall ...). Identify inductive invariants as separate Lemmas.
- Attempt a real proof. Compile with: \`rocq compile ${PROOFS_DIR}/<propId>.v\` (fallback \`coqc ${PROOFS_DIR}/<propId>.v\`). Paste the EXACT command and its full raw output.
- CHEAT DETECTION (report honestly): after a clean compile, run \`grep -nE 'Admitted|admit|Axiom|Parameter |Variable |Hypothesis' ${PROOFS_DIR}/<propId>.v\` and paste the result.
- Award MACHINE_CHECKED_PROOF **only if** the file compiles with exit 0 AND the target theorem closes with \`Qed.\` (not \`Admitted.\`) AND there is no \`admit\`/\`Admitted\` AND no \`Axiom\`/\`Parameter\`/\`Variable\`/\`Hypothesis\` that the target theorem depends on to discharge its goal. Confirm with \`Print Assumptions <theorem_name>.\` and paste its output — it must say "Closed under the global context".
- Otherwise the status is PROOF_SKETCH_ONLY, even if the file compiles with \`Admitted.\` or leans on axioms. NEVER overclaim: a compile with admits/axioms is a sketch, not a proof.
- If the theorem is FALSE (an adjudicated counterexample exists), do NOT try to prove it. Instead formalize the counterexample: define the concrete trace and prove the negation (e.g. \`Theorem cex : ~ Property.\` closed by \`Qed.\`), which machine-checks that the property genuinely fails on that trace.`

// ---------------------------------------------------------------------------
// Schemas
// ---------------------------------------------------------------------------
const MECHANISMS_SCHEMA = {
 type: 'object', additionalProperties: false,
 required: ['mechanisms'],
 properties: {
   mechanisms: {
     type: 'array', minItems: 1, maxItems: 8,
     items: {
       type: 'object', additionalProperties: false,
       required: ['name', 'location', 'rationale', 'riskScore'],
       properties: {
         name: { type: 'string' },
         location: { type: 'string', description: 'paths / crates / contracts (file:line where possible)' },
         rationale: { type: 'string', description: 'why high risk: loss-of-funds/inflation/consensus-halt/novelty/concurrency/cross-layer/low-level' },
         riskScore: { type: 'integer', minimum: 1, maximum: 100 },
       },
     },
   },
 },
}

const MODEL_SCHEMA = {
 type: 'object', additionalProperties: false,
 required: ['mechanism', 'actors', 'state', 'views', 'transitions', 'time', 'exceptions', 'assumptionLedger'],
 properties: {
   mechanism: { type: 'string' },
   actors: { type: 'array', items: { type: 'string' } },
   state: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['name', 'kind'], properties: {
     name: { type: 'string' }, kind: { type: 'string', enum: ['persistent', 'transient', 'cached', 'speculative'] }, description: { type: 'string' } } } },
   views: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['component', 'snapshot'], properties: {
     component: { type: 'string' }, snapshot: { type: 'string' }, staleness: { type: 'string' }, authoritative: { type: 'boolean' } } } },
   transitions: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['name', 'preconditions', 'reads', 'writes', 'failureBehavior'], properties: {
     name: { type: 'string' }, preconditions: { type: 'string' }, reads: { type: 'string' }, writes: { type: 'string' },
     externalCalls: { type: 'string' }, deferredEffects: { type: 'string' }, failureBehavior: { type: 'string' } } } },
   time: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['variable', 'meaning'], properties: {
     variable: { type: 'string' }, meaning: { type: 'string' } } } },
   exceptions: { type: 'array', items: { type: 'string' }, description: 'emergency paths, withdrawal/emptying exceptions, exempt accounts, upgrade transitions, bypass conditions' },
   assumptionLedger: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['fact', 'classification'], properties: {
     fact: { type: 'string' }, classification: { type: 'string', enum: ['EXPLICIT', 'INFERRED', 'UNKNOWN'] } } } },
   citations: { type: 'array', items: { type: 'string' } },
 },
}

const REGISTRY_SCHEMA = {
 type: 'object', additionalProperties: false,
 required: ['properties'],
 properties: {
   properties: {
     type: 'array', minItems: 1, maxItems: 12,
     items: {
       type: 'object', additionalProperties: false,
       required: ['id', 'name', 'statement', 'impact_if_false', 'rank'],
       properties: {
         id: { type: 'string', description: 'e.g. P-001' },
         name: { type: 'string' },
         statement: { type: 'string', description: 'quantified "For all ..., if ..., then ..." form' },
         lens: { type: 'string' },
         impact_if_false: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
         adversary_capabilities: { type: 'array', items: { type: 'string' } },
         assumptions: { type: 'array', items: { type: 'string' } },
         counterexample_bound: { type: 'object', additionalProperties: true },
         rank: { type: 'integer', minimum: 1, description: '1 = search first' },
       },
     },
   },
 },
}

const CE_SCHEMA = {
 type: 'object', additionalProperties: false,
 required: ['status', 'boundSearched'],
 properties: {
   status: { type: 'string', enum: ['COUNTEREXAMPLE_FOUND', 'UNDER_SPECIFIED', 'NO_COUNTEREXAMPLE_WITHIN_BOUND', 'PROOF_SKETCH_ONLY'] },
   boundSearched: { type: 'string', description: 'exact bound: #actors, #transitions, K values, boundary values, orderings, views, time points explored' },
   remainingCases: { type: 'string', description: 'case partition still unsearched (required when no CE found)' },
   counterexample: {
     type: ['object', 'null'], additionalProperties: false,
     required: ['initialState', 'actors', 'orderedTrace', 'componentViews', 'stateAfterEachStep', 'assumptionsHold', 'violatedClause', 'impact', 'minimality', 'implementationPath'],
     properties: {
       initialState: { type: 'string' },
       actors: { type: 'string' },
       orderedTrace: { type: 'array', items: { type: 'string' } },
       componentViews: { type: 'string', description: 'exact state snapshot each component observes at each step' },
       stateAfterEachStep: { type: 'array', items: { type: 'string' } },
       assumptionsHold: { type: 'string', description: 'why EVERY premise/assumption still holds in this trace' },
       violatedClause: { type: 'string' },
       impact: { type: 'string' },
       minimality: { type: 'string' },
       implementationPath: { type: 'string', description: 'exact file:line path the trace exercises' },
       regressionTestOutline: { type: 'string' },
     },
   },
   notes: { type: 'string' },
 },
}

const ADJ_SCHEMA = {
 type: 'object', additionalProperties: false,
 required: ['verdict', 'refutationAttempt', 'reasoning'],
 properties: {
   verdict: { type: 'string', enum: ['CONFIRMED', 'REFUTED', 'UNDER_SPECIFIED'] },
   refutationAttempt: { type: 'string', description: 'the strongest concrete attempt to break the counterexample (broken premise, impossible ordering, missing guard elsewhere, wrong state values)' },
   reasoning: { type: 'string' },
   residualDoubt: { type: 'string' },
 },
}

const REFINE_SCHEMA = {
 type: 'object', additionalProperties: false,
 required: ['divergences', 'permissiveness', 'modelCodeMap'],
 properties: {
   divergences: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['class', 'description', 'severity'], properties: {
     class: { type: 'string', enum: ['missing-enforcement', 'wrong-scope', 'wrong-time', 'wrong-snapshot', 'wrong-exception', 'wrong-failure', 'concurrency', 'representation'] },
     description: { type: 'string' }, modelConcept: { type: 'string' }, codeSymbols: { type: 'string' }, enforcementPoint: { type: 'string' },
     severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low', 'info'] } } } },
   permissiveness: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['opportunity'], properties: {
     opportunity: { type: 'string', description: 'unnecessary revert/retry/lock/reserve/history requirement — a trace in D_safe \\ D_current' },
     unnecessaryConstruct: { type: 'string' }, saferAndMorePermissiveRule: { type: 'string' } } } },
   modelCodeMap: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['modelConcept', 'codeSymbols'], properties: {
     modelConcept: { type: 'string' }, codeSymbols: { type: 'string' }, reads: { type: 'string' }, writes: { type: 'string' }, assumption: { type: 'string' }, enforcementPoint: { type: 'string' } } } },
 },
}

// Phase 6 — Rocq formalization + machine-checked proof (or machine-checked refutation).
const PROOF_SCHEMA = {
 type: 'object', additionalProperties: false,
 required: ['status', 'goal', 'rocqFile', 'theoremName', 'compileCommand', 'compileExitZero', 'compilerOutput', 'cheatGrepOutput', 'printAssumptionsOutput'],
 properties: {
   status: { type: 'string', enum: ['MACHINE_CHECKED_PROOF', 'PROOF_SKETCH_ONLY'] },
   goal: { type: 'string', enum: ['prove-property', 'refute-property'], description: 'refute when an adjudicated counterexample exists: machine-check ~Property on the concrete trace' },
   rocqFile: { type: 'string', description: \`path under \${PROOFS_DIR}/\` },
   theoremName: { type: 'string' },
   theoremStatement: { type: 'string', description: 'the explicitly-quantified Rocq Theorem/Lemma statement' },
   invariants: { type: 'array', items: { type: 'string' }, description: 'inductive invariant lemmas' },
   compileCommand: { type: 'string' },
   compileExitZero: { type: 'boolean' },
   compilerOutput: { type: 'string', description: 'full raw output of the compile command' },
   qedClosed: { type: 'boolean', description: 'target theorem closes with Qed. (not Admitted.)' },
   cheatGrepOutput: { type: 'string', description: 'raw output of the Admitted/admit/Axiom/Parameter/Variable/Hypothesis grep' },
   printAssumptionsOutput: { type: 'string', description: 'raw \`Print Assumptions <theorem>.\` output; must be "Closed under the global context" for MACHINE_CHECKED_PROOF' },
   modelFidelityCaveats: { type: 'string', description: 'where the Rocq model abstracts away from the real implementation — proof strength is bounded by this' },
 },
}

const EVIDENCE_SCHEMA = {
 type: 'object', additionalProperties: false,
 required: ['regressionTests'],
 properties: {
   regressionTests: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['name', 'kind', 'outline'], properties: {
     name: { type: 'string' },
     kind: { type: 'string', enum: ['deterministic', 'invariant', 'boundary', 'ordering', 'temporal', 'reentrancy', 'concurrency', 'differential', 'compiler-matrix'] },
     outline: { type: 'string' } } } },
 },
}

// ---------------------------------------------------------------------------
// Phase 1 — Prioritize mechanisms, not files
// ---------------------------------------------------------------------------
phase('Triage')
let mechanisms
if (T.mechanism) {
 mechanisms = [{ name: T.mechanism, location: T.files || '(operator-specified)', rationale: 'operator-selected in-scope mechanism', riskScore: 100 }]
} else {
 const triage = await agent(
   \`\${TARGET_BLOCK}\n\n\${RULES}\n\nPHASE 1 — PRIORITIZE MECHANISMS, NOT FILES.\n\` +
   \`Explore \${T.repoPath}. Rank subsystems by: potential loss of funds / inflation / consensus divergence / chain halt; novelty & lack of production history; concurrency, speculation, retries, async processing; components operating on different state snapshots; activation delays, epochs, cooldowns, challenge periods, reorg assumptions; many exceptions/exemptions/emergency modes/upgrade paths; cross-component assumptions (consensus relying on execution; an L2 relying on an L1 verifier); low-level hazards (serialization, unsafe memory, integer widths, storage layout, compilers, FFI).\n\` +
   \`Return the highest-risk mechanisms with concrete locations (file:line). Prefer a small mechanism with high blast radius over a large low-risk one.\`,
   { schema: MECHANISMS_SCHEMA, phase: 'Triage', label: 'triage:prioritize' },
 )
 mechanisms = (triage?.mechanisms || []).sort((a, b) => b.riskScore - a.riskScore).slice(0, MAX_MECHANISMS)
}
if (!mechanisms.length) return { error: 'Triage produced no mechanisms', target: T }
log(\`Selected \${mechanisms.length} mechanism(s): \${mechanisms.map(m => m.name).join(' | ')}\`)

// ---------------------------------------------------------------------------
// Phase 2 — Reconstruct the state machine (Modeler: models, does NOT hunt bugs)
// ---------------------------------------------------------------------------
phase('Model')
const models = (await parallel(mechanisms.map(m => () =>
 agent(
   \`\${TARGET_BLOCK}\n\n\${RULES}\n\nROLE: MODELER. You reconstruct the mechanism as a state-transition system. You DO NOT search for bugs — anchoring is the enemy; another agent does that.\n\` +
   \`MECHANISM: \${m.name} @ \${m.location}\n\nPHASE 2 — Read the code and document precisely:\n\` +
   \`- ACTORS (honest, adversarial, validators/sequencers/relayers/keepers, privileged roles, external contracts).\n\` +
   \`- STATE (balances/shares/reserves/debt; nonces & message IDs; permissions & delegation; config & version; queues/checkpoints/roots; cached & speculative state) with kind.\n\` +
   \`- VIEWS: which snapshot each component sees, how stale it can be, which is authoritative.\n\` +
   \`- TRANSITIONS: preconditions, reads, writes, external calls, deferred effects, failure behavior.\n\` +
   \`- TIME: blocks/slots/epochs, delay K, activation/deactivation, reorg & finality assumptions.\n\` +
   \`- EXCEPTIONS: emergency paths, emptying/withdrawal exceptions, exempt accounts, upgrade transitions, bypass conditions.\n\` +
   \`- ASSUMPTION LEDGER: label each fact EXPLICIT / INFERRED / UNKNOWN.\n\` +
   \`Do NOT collapse admission, consensus, speculative execution, merge, canonical execution, settlement, and finalization into one operation. Cite file:line.\`,
   { schema: MODEL_SCHEMA, phase: 'Model', label: \`model:\${m.name.slice(0, 24)}\` },
 ),
))).filter(Boolean)
if (!models.length) return { error: 'Modeler produced no state machines', mechanisms, target: T }

// ---------------------------------------------------------------------------
// Phase 3 — Convert promises into theorem candidates (Specifier)
// ---------------------------------------------------------------------------
phase('Specify')
const registries = (await parallel(models.map(model => () =>
 agent(
   \`\${TARGET_BLOCK}\n\n\${RULES}\n\n\${LENSES}\n\nROLE: SPECIFIER. Given the reconstructed model, produce a property registry.\n\` +
   \`MODEL:\n\${JSON.stringify(model)}\n\nPHASE 3 — Each property must be QUANTIFIED, FALSIFIABLE, and tied to impact, in "For all ..., if ..., then ..." form.\n\` +
   \`Draw on canonical shapes where they fit: accepted-then-executable; parallel-execution equivalence; bridge/message uniqueness (exactly one canonical finalized source event; not previously consumed); conservation of value within a stated rounding bound; safe-call noninterference; minimal reverts (reject only when accepting permits a future protocol-allowed execution that violates safety).\n\` +
   \`Fill counterexample_bound (small: <=3 actors, <=4 transactions, blocks/K small). RANK by impact: loss-of-funds/inflation > consensus/client halt > replay/double-execution > authorization failure > cross-component inconsistency > liveness > determinism. rank=1 searched first. Emit at most \${MAX_PROPS} properties.\`,
   { schema: REGISTRY_SCHEMA, phase: 'Specify', label: \`specify:\${model.mechanism.slice(0, 24)}\` },
 ).then(r => ({ model, registry: r })),
))).filter(Boolean)

// Flatten to per-property work items, each carrying its parent model. Rank + cap.
const items = registries.flatMap(({ model, registry }) =>
 (registry?.properties || [])
   .sort((a, b) => (a.rank || 99) - (b.rank || 99))
   .slice(0, MAX_PROPS)
   .map(prop => ({ model, prop })),
)
if (!items.length) return { error: 'Specifier produced no properties', models, target: T }
log(\`Falsifying \${items.length} propert\${items.length === 1 ? 'y' : 'ies'} with \${PASSES} independent blind pass(es) each.\`)

// ---------------------------------------------------------------------------
// Phases 4/5/6/7/8 — pipelined per property (no barrier between stages).
//   Falsify -> Adjudicate -> Refine -> Evidence
// ---------------------------------------------------------------------------
const records = await pipeline(
 items,

 // Phase 4 — Falsify before proving. PASSES mutually-blind adversary passes.
 ({ model, prop }) => parallel(
   Array.from({ length: PASSES }, (_, k) => () => agent(
     \`\${TARGET_BLOCK}\n\n\${RULES}\n\n\${LENSES}\n\nROLE: ADVERSARY (independent pass #\${k + 1} — you have NOT seen any other pass; do your own search).\n\` +
     \`MODEL:\n\${JSON.stringify(model)}\n\nPROPERTY TO FALSIFY:\n\${JSON.stringify(prop)}\n\n\` +
     \`PHASE 4 — Your FIRST objective is a counterexample, not a proof. Negate the conclusion while keeping EVERY premise true, then find the SMALLEST trace:\n\` +
     \`- <=3 actors, 2-4 transitions; K in {1,2}.\n- boundary values 0, 1, T-1, T, T+1, and maximums.\n- enumerate transaction/message orderings.\n- exercise every exceptional branch and paired operations.\n\` +
     \`- test views: current, stale, speculative, merged, finalized.\n- test indirect mutation via callbacks, delegation, hooks, routers, nested calls, system contracts.\n- test time at n, n+K-1, n+K, n+K+1, n+2K.\n- test one conflicting speculative write / retry / reorg / upgrade boundary.\n\` +
     \`Produce EXACT state values, not narrative suspicion. If found -> COUNTEREXAMPLE_FOUND with the full artifact. If the spec is ambiguous -> UNDER_SPECIFIED. Otherwise -> NO_COUNTEREXAMPLE_WITHIN_BOUND with the exact bound searched and the remaining case partition. "No counterexample" is NOT "proved".\`,
     { schema: CE_SCHEMA, phase: 'Falsify', label: \`falsify:\${prop.id}#\${k + 1}\` },
   )),
 ).then(passes => ({ model, prop, passes: passes.filter(Boolean) })),

 // Adjudicate — a skeptic actively tries to REFUTE each candidate counterexample.
 async (r) => {
   if (!r) return null
   const candidates = r.passes.filter(p => p.status === 'COUNTEREXAMPLE_FOUND' && p.counterexample)
   const adjudicated = await parallel(candidates.map(c => () => agent(
     \`\${TARGET_BLOCK}\n\n\${RULES}\n\nROLE: ADJUDICATOR (fresh context, no prior conclusions). Your job is to DISPROVE this candidate, not to agree.\n\` +
     \`PROPERTY:\n\${JSON.stringify(r.prop)}\n\nMODEL:\n\${JSON.stringify(r.model)}\n\nCANDIDATE COUNTEREXAMPLE:\n\${JSON.stringify(c.counterexample)}\n\n\` +
     \`Attempt the strongest refutation: is a premise actually violated? is the ordering reachable under the real system? does a guard elsewhere (another file/line) already prevent it? are the exact state values wrong? does an assumption fail? Re-derive the exact state at each step against the actual code (cite file:line).\n\` +
     \`Verdict CONFIRMED only if you tried hard and could not break it. REFUTED if you broke it (say exactly how). UNDER_SPECIFIED if it depends on unknown semantics.\`,
     { schema: ADJ_SCHEMA, phase: 'Adjudicate', label: \`adjudicate:\${r.prop.id}\` },
   ).then(v => ({ counterexample: c.counterexample, verdict: v })).filter?.(Boolean) ?? { counterexample: c.counterexample, verdict: null }))
   return { ...r, candidates, adjudicated: adjudicated.filter(Boolean) }
 },

 // Phases 5 & 7 — Repair (permissiveness) + implementation refinement (model -> code).
 async (r) => {
   if (!r) return null
   const refinement = await agent(
     \`\${TARGET_BLOCK}\n\n\${RULES}\n\n\${LENSES}\n\nROLE: IMPLEMENTATION MAPPER + REPAIR ARCHITECT.\n\` +
     \`PROPERTY:\n\${JSON.stringify(r.prop)}\n\nMODEL:\n\${JSON.stringify(r.model)}\n\n\` +
     (r.adjudicated?.length ? \`CONFIRMED/CANDIDATE COUNTEREXAMPLES:\n\${JSON.stringify(r.adjudicated)}\n\n\` : '') +
     \`Do BOTH, keeping design-level and implementation-level findings separate:\n\` +
     \`PHASE 7 (refinement) — build a model->code map (modelConcept | codeSymbols | reads | writes | assumption | enforcementPoint). Search for divergence classes: missing-enforcement (model assumes a check the code never performs); wrong-scope (checks the initiator but not all changed objects); wrong-time (pre-state where post-state is required); wrong-snapshot (speculative/stale/merged/finalized confused); wrong-exception (different bypass conditions); wrong-failure (model reverts, code panics/aborts); concurrency (atomic step implemented as unsafe interleavings); representation (bytes/ints/maps/arrays behave differently in the impl language, incl. UB). Cite file:line.\n\` +
     \`PHASE 5 (repair) — derive D_safe as a transition rule from the property (do NOT patch only the observed trace). Report unsafe permissiveness (D_current \\ D_safe) AND unnecessary reverts/retries/locks/reserves/history requirements (D_safe \\ D_current): the most permissive rule that still preserves the property.\`,
     { schema: REFINE_SCHEMA, phase: 'Refine', label: \`refine:\${r.prop.id}\` },
   )
   return { ...r, refinement }
 },

 // Phase 6 — Rocq formalization + machine-checked proof (or machine-checked refutation).
 async (r) => {
   if (!r) return null
   const confirmed = (r.adjudicated || []).filter(a => a.verdict?.verdict === 'CONFIRMED')
   const goal = confirmed.length ? 'refute-property' : 'prove-property'
   const rocq = await agent(
     \`\${TARGET_BLOCK}\n\n\${RULES}\n\n\${ROCQ}\n\nROLE: PROOF ENGINEER (Rocq).\n\` +
     \`PROPERTY:\n\${JSON.stringify(r.prop)}\n\nMODEL:\n\${JSON.stringify(r.model)}\n\n\` +
     (confirmed.length
       ? \`An adjudicated CONFIRMED counterexample exists, so the property is FALSE. GOAL = refute-property: formalize the concrete counterexample trace in Rocq and machine-check the negation (\`Theorem cex_\${r.prop.id.replace(/[^A-Za-z0-9]/g, '_')} : ~ Property.\` closed by \`Qed.\`).\nCOUNTEREXAMPLES:\n\${JSON.stringify(confirmed.map(c => c.counterexample))}\n\n\`
       : \`No counterexample survived adjudication. GOAL = prove-property: formalize the model + property and attempt a machine-checked proof.\n\n\`) +
     \`Follow the ROCQ PROOF PROTOCOL exactly. Write the .v file under \${PROOFS_DIR}/, compile it, run the cheat grep and \`Print Assumptions\`, and paste all raw outputs. Report MACHINE_CHECKED_PROOF only when the checks pass; otherwise PROOF_SKETCH_ONLY. Note model-fidelity caveats — the proof only binds the Rocq abstraction, and Theorem 2 (implementation refines model) remains the separate obligation handled by the Refine stage.\`,
     { schema: PROOF_SCHEMA, phase: 'Prove', label: \`prove:\${r.prop.id}\`, effort: 'high' },
   )
   return { ...r, confirmed, goal, rocq }
 },

 // Phase 8 — permanent regression evidence, pinned to the counterexample and Rocq artifact.
 async (r) => {
   if (!r) return null
   const confirmed = r.confirmed || []
   const evidence = await agent(
     \`\${TARGET_BLOCK}\n\n\${RULES}\n\nROLE: TEST ENGINEER.\n\` +
     \`PROPERTY:\n\${JSON.stringify(r.prop)}\n\n\` +
     \`CONFIRMED COUNTEREXAMPLES (\${confirmed.length}):\n\${JSON.stringify(confirmed.map(c => c.counterexample))}\n\n\` +
     \`REFINEMENT FINDINGS:\n\${JSON.stringify(r.refinement)}\n\n\` +
     \`ROCQ ARTIFACT: \${r.rocq?.rocqFile || '(none)'} — status \${r.rocq?.status || 'n/a'}\n\n\` +
     \`PHASE 8 — For every confirmed result and refinement finding, emit regression evidence: a deterministic regression test; a stateful invariant/property test; boundary-value generators; ordering permutations; time/epoch manipulations; callback/reentrancy variants; a deterministic concurrency schedule where relevant; differential testing vs the Rocq reference model (extract or transcribe it); a compiler/optimization matrix for low-level code. Give concrete test outlines pinned to file:line.\`,
     { schema: EVIDENCE_SCHEMA, phase: 'Evidence', label: \`evidence:\${r.prop.id}\` },
   )
   // Assemble the permanent evidence chain: property -> CE -> code path -> fix -> Rocq proof -> regression invariant.
   const worstStatus = r.passes.some(p => p.status === 'COUNTEREXAMPLE_FOUND') ? 'COUNTEREXAMPLE_FOUND'
     : r.passes.some(p => p.status === 'UNDER_SPECIFIED') ? 'UNDER_SPECIFIED'
     : r.passes.length ? 'NO_COUNTEREXAMPLE_WITHIN_BOUND' : 'UNDER_SPECIFIED'
   return {
     mechanism: r.model.mechanism,
     property: r.prop,
     status: confirmed.length ? 'COUNTEREXAMPLE_FOUND' : worstStatus,
     proofStatus: r.rocq?.status || 'PROOF_SKETCH_ONLY',
     proofGoal: r.goal,
     confirmedCount: confirmed.length,
     passes: r.passes.map(p => ({ status: p.status, boundSearched: p.boundSearched, remainingCases: p.remainingCases })),
     confirmedCounterexamples: confirmed,
     refutedOrPending: (r.adjudicated || []).filter(a => a.verdict?.verdict !== 'CONFIRMED'),
     refinement: r.refinement,
     rocq: r.rocq,
     evidence,
   }
 },
)

const clean = records.filter(Boolean)

// ---------------------------------------------------------------------------
// Synthesis — assemble the final chain and a prioritized report.
// ---------------------------------------------------------------------------
phase('Synthesize')
const confirmedFindings = clean.filter(r => r.status === 'COUNTEREXAMPLE_FOUND')
const machineChecked = clean.filter(r => r.proofStatus === 'MACHINE_CHECKED_PROOF')
const summary = await agent(
 \`\${TARGET_BLOCK}\n\n\${RULES}\n\nROLE: RESEARCH LEAD. Assemble the final report from the per-property records below. Do not introduce new claims.\n\` +
 \`RECORDS:\n\${JSON.stringify(clean)}\n\n\` +
 \`Produce Markdown with: (1) an executive table [property id | mechanism | status | impact | confirmed CEs | Rocq status]; (2) for each CONFIRMED finding the full evidence chain Property -> Counterexample -> Code path (file:line) -> Fix (D_safe rule) -> Rocq refutation (\${PROOFS_DIR}/*.v) -> Regression invariant; (3) design-level findings (unsafe permissiveness) and separately implementation-level divergences; (4) permissiveness opportunities (unnecessary reverts/locks/reserves) as their own section; (5) a PROOF STATUS section: which properties are MACHINE_CHECKED_PROOF (cite the .v file, theorem name, and "Closed under the global context") vs PROOF_SKETCH_ONLY, and each proof's model-fidelity caveats + the outstanding Theorem-2 (implementation-refines-model) obligation; (6) NO_COUNTEREXAMPLE_WITHIN_BOUND items with the exact bound searched and remaining unsearched cases — explicitly NOT labeled "proved" (a bounded search is not a Rocq proof); (7) UNDER_SPECIFIED items and the missing semantics needed. Keep every status label exact and never call a Rocq file with admits/axioms a proof.\`,
 { phase: 'Synthesize', label: 'synthesize:report' },
)

return {
 target: T,
 config: { passes: PASSES, maxMechanisms: MAX_MECHANISMS, maxProperties: MAX_PROPS },
 mechanisms: mechanisms.map(m => ({ name: m.name, riskScore: m.riskScore })),
 counts: {
   properties: clean.length,
   confirmed: confirmedFindings.length,
   machineCheckedProofs: machineChecked.length,
   underSpecified: clean.filter(r => r.status === 'UNDER_SPECIFIED').length,
   noCounterexampleWithinBound: clean.filter(r => r.status === 'NO_COUNTEREXAMPLE_WITHIN_BOUND').length,
 },
 proofsDir: PROOFS_DIR,
 findings: clean,
 report: summary,
}
```
