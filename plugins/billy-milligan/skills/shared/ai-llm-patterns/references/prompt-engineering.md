# Prompt Engineering Patterns

## When to load
Load when designing LLM prompts, building AI features, or optimizing model outputs.

## Prompt Structure

```
System message:  WHO the model is + HOW it should behave
User message:    WHAT to do + CONTEXT + CONSTRAINTS
Assistant:       Model response (can be prefilled for steering)

Order matters:
  1. Role / persona
  2. Task description
  3. Context / input data
  4. Output format
  5. Constraints / rules
  6. Examples (few-shot)
```

## Key Techniques

### Few-Shot Prompting

```typescript
const systemPrompt = `You are a sentiment classifier. Classify text as positive, negative, or neutral.`;

const fewShotExamples = `
Text: "This product exceeded my expectations!"
Sentiment: positive

Text: "The delivery was late and the item was damaged."
Sentiment: negative

Text: "I received the package yesterday."
Sentiment: neutral
`;

const userPrompt = `${fewShotExamples}
Text: "${userInput}"
Sentiment:`;
```

### Chain of Thought

```typescript
const prompt = `Analyze this code for security vulnerabilities.

Think step by step:
1. Identify all user inputs
2. Trace each input through the code
3. Check if inputs are validated/sanitized
4. Identify potential injection points
5. Rate severity (critical/high/medium/low)

Code:
${codeSnippet}

Analysis:`;
```

### Structured Output

```typescript
const prompt = `Extract entities from this text and return JSON.

Text: "${inputText}"

Return ONLY valid JSON in this exact format:
{
  "people": [{"name": "...", "role": "..."}],
  "organizations": [{"name": "...", "type": "..."}],
  "dates": [{"date": "YYYY-MM-DD", "context": "..."}],
  "locations": [{"name": "...", "type": "city|country|address"}]
}`;

// With Claude: use tool_use for guaranteed structured output
const response = await anthropic.messages.create({
  model: 'claude-sonnet-4-6',
  max_tokens: 1024,
  tools: [{
    name: 'extract_entities',
    description: 'Extract entities from text',
    input_schema: {
      type: 'object',
      properties: {
        people: { type: 'array', items: { /* schema */ } },
        organizations: { type: 'array', items: { /* schema */ } },
      },
      required: ['people', 'organizations'],
    },
  }],
  tool_choice: { type: 'tool', name: 'extract_entities' },
  messages: [{ role: 'user', content: inputText }],
});
```

### System Prompt Patterns

```typescript
// Guardrails pattern
const systemPrompt = `You are a customer support assistant for Acme Corp.

Rules:
- Only answer questions about Acme products and services
- Never reveal internal company information or pricing formulas
- If asked about competitors, say "I can only help with Acme products"
- If you don't know the answer, say "Let me connect you with a specialist"
- Never generate code, SQL queries, or technical commands
- Keep responses under 3 sentences unless the user asks for detail

Tone: friendly, professional, concise`;

// Expert persona
const systemPrompt = `You are a senior database administrator with 20 years of PostgreSQL experience.
Focus on: query optimization, indexing, and schema design.
When reviewing queries, always consider: execution plan, index usage, and data volume.
Provide specific, actionable recommendations with SQL examples.`;
```

## Temperature & Parameters

```
temperature: controls randomness
  0.0: deterministic (classification, extraction, code)
  0.3: mostly consistent (technical writing, analysis)
  0.7: creative but coherent (general chat, brainstorming)
  1.0: maximum creativity (poetry, story writing)

top_p: nucleus sampling (alternative to temperature)
  0.1: very focused
  0.9: diverse

max_tokens: limit response length
  Set to expected output size + buffer
  Too low → truncated responses
  Too high → wasted cost on padding

stop_sequences: halt generation at specific tokens
  ["\n\nHuman:", "END"] → stop when these appear
```

## Anti-patterns
- Vague instructions ("write something good") → add specific criteria
- No output format → model guesses, inconsistent results
- Prompt injection vulnerable → add guardrails in system prompt
- Temperature 1.0 for factual tasks → hallucination risk
- Giant context with no focus → model loses signal in noise

## Quick reference
```
Structure: role → task → context → format → constraints → examples
Few-shot: 3-5 examples for classification/extraction tasks
Chain of thought: "Think step by step" for reasoning
Structured output: tool_use (Claude) or JSON mode for guaranteed format
Temperature: 0 for deterministic, 0.3 for technical, 0.7 for creative
Guardrails: explicit rules in system prompt for what NOT to do
Context window: put important info at start and end (primacy/recency)
Iteration: test → evaluate → refine (prompt engineering is iterative)
```
