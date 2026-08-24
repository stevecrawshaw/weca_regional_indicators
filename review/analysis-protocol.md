# 2026 Project Review — Transcript Analysis Protocol

How to get from five Teams transcripts to a review document without the model inventing
a consensus that nobody expressed.

The document has two readers with different needs. The commissioning managers need a
short, decidable front end: did this approach work, what should it cost next time, what
are the three or four things being asked for. You need the long tail — every specific
piece of friction, none of which belongs in a manager's summary. Write it as a two-page
front section plus an annexe, not as one document pitched between the two.

The front section should end with named asks, each carrying an estimated cost and the
evidence from the interviews that supports it. An ask without a number is a wish.

## Handling the transcripts

Teams transcripts of five named staff giving opinions about a process their manager
designed are personal data and mildly sensitive. Before the first interview:

- Decide where they live. **Not in this repo** — even gitignored, one `git add -A` puts
  them in history. A local folder outside the working tree is simplest.
- Decide a retention period and say it in the opening (the guide says "deleted once the
  review is written" — hold to that).
- Tell participants the transcript will be processed by an AI tool. It's a small thing to
  say and an awkward thing to be found out about.

## Fix the transcript before analysing it

Teams speech-to-text will mangle every term this project runs on. Expect and correct:

| Likely transcription | Actual |
|---|---|
| "fact table", "fac table", "packed table" | FACT table |
| "renn V", "renve", "R env" | renv |
| "Carto", "Quatro", "quadro" | Quarto |
| "GT", "gee tee", "GTE" | gt (tables) |
| "Positron", "positive on" | Positron |
| "ggplot", "G plot", "jeeplot" | ggplot2 |
| "period end", "period underscore end" | `period_end` |
| "polarity", "polarity column" | polarity |
| "sparkline", "spark line" | sparkline |

Do a find-and-replace pass yourself, or have the model produce a cleaned transcript with
every uncertain passage marked `[?]` rather than guessed at. Never let it silently
normalise — a garbled sentence you can see is better than a fluent sentence that's wrong.

## Two-stage coding

**Stage 1 — one transcript at a time, in separate sessions.** Feeding all five at once
anchors the model on whoever it read first and manufactures agreement. For each
transcript, ask for:

- Every distinct point the person made, as a claim plus the verbatim quote supporting it.
- Whether each point is about: learning, tooling, the FACT contract, data, workload,
  coordination, sustainability, or something else.
- Anything the person raised that no question asked about.
- Points where they hedged, contradicted themselves, or changed position mid-answer.

Save each output separately. Read them. Correct the ones that misread the speaker — you
were in the room and the model wasn't.

**Stage 2 — synthesis across the five corrected outputs.** Ask specifically for:

- Points made by **more than one** person, with who said what.
- Points made by **exactly one** person that would matter if true. *(With n=5 this is the
  most valuable category, and it's the one a summariser will drop.)*
- **Disagreements** between participants — where two people wanted opposite things.
- Anything raised that contradicts your own account of how the project ran.
- Every concrete ask — protected time, support, earlier start, different tooling — with
  who asked for it and what they said it would buy.

**Weight Simon separately.** He came in already fluent in R and Quarto, so his answers on
learning, time and difficulty describe a different job from the other four's. Averaging
him in understates the learning cost — which is exactly the number the managers will use.
Report the learning burden from the four who carried it, and use Simon's answers as
design critique and as an outside read on what his colleagues struggled with.

Stuart and Simon shared a chapter, so their workload figures aren't independent either.
Don't let a per-chapter day count double-count them or halve them without saying so.

## Rules for the model

Put these in the prompt, every time:

1. Every claim carries a verbatim quote and a speaker name. No quote, no claim.
2. Never merge two people's words into one point without naming both.
3. Do not soften. If someone said the FACT contract was a waste of time, write that.
4. Flag uncertainty rather than resolving it — `[unclear from transcript]` is a valid
   output.
5. Don't count. "Three of five found git difficult" is a false precision on this sample;
   name the three.

## Before you publish

- Send each person their own quotes. Strike whatever they strike, without argument.
- Check every quote against the transcript yourself. Model-produced quotes drift, and a
  misquote attributed by name to a named colleague is the one failure mode with real
  consequences.
- Read the finished review and ask what in it makes you uncomfortable. If the answer is
  nothing, the interviews didn't work and the problem was probably the interviewer.
