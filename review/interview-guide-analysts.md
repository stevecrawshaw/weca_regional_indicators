# 2026 Project Review — Analyst Interview Guide

Semi-structured, 45 minutes, one-to-one on Teams with transcript.

Participants: Heather (Transport), Tom (Place), Stuart (Economy), Simon (Economy,
co-authoring with Stuart), Megan (Skills and Child Poverty).

Audience for the resulting review: the commissioning managers, and me. Both purposes
matter and they pull in different directions — see *Who this is for* below.

This is a guide, not a script. The questions in **bold** are the ones that must be asked
of everyone so answers are comparable. Everything under them is a probe — use what the
conversation needs and drop the rest. Silence is a tool; leave it.

---

## Who this is for

The review goes to the commissioning managers as well as to me. That has two consequences
and they need holding in mind throughout.

**Be straight about it in the opening.** An analyst who assumes this is a private
conversation with a colleague, and later finds their name in a document on a manager's
desk, will not talk to you honestly again — and they'd be right not to. Say who reads it,
before recording.

**Half of what you're collecting is a resourcing case.** Managers can't act on "the
learning materials could be better". They can act on "four of five analysts found the
time unprotected and estimate they'd need six days next cycle, three of which are
one-off learning cost that won't recur". Every workload, support and timeline answer
should be pushed towards a number or a concrete ask, because that's the form in which it
can be granted.

---

## How to run it

**Ask, then stop talking.** The value in a live interview is the second and third answer,
not the first. When someone says "it was fine", the follow-up is "what was the worst
moment of it being fine?"

**Do not defend the design.** You built the FACT contract, the helper scripts and the
timetable. Every instinct to explain why something was necessary teaches the interviewee
that criticism costs them something. Write the objection down, say "that's useful", move on.

**Chase specifics.** "The docs were confusing" is unusable. "I spent an afternoon working
out that period_end had to be a Date and not a string" is actionable. Always ask for the
incident.

**Watch for the diplomatic answer.** A pre-form rating of 8 plus a vague verbal answer
usually means a 5. Try: "if you were telling a colleague over coffee rather than telling
me, what would you say?"

**Timing.** Roughly: opening 3, warm-up 4, sections 2–7 about 30, close 6. If you are
running late, cut section 5's data-sourcing half — it's the part where written answers
work almost as well.

---

## Opening (3 min)

Say this, more or less, in your own words:

> Thanks for making time. This is a review of how the project ran, not a review of your
> chapter or of you — the chapters are done and I'm happy with them. What I'm trying to
> work out is whether to run it this way again, and what to change if we do.
>
> Two things about where this goes, before we start. It becomes a review document that
> goes to the commissioning managers as well as to me — so this isn't a private
> conversation, and I'd rather you knew that up front than found out later. And you'll be
> named in it. Before it goes to anyone, you'll see every quote attributed to you and you
> can cut any of them, no reason needed. If you'd rather something be in the review but
> not attached to your name, say so at the time or afterwards and I'll unattribute it.
>
> Part of what I want out of this is a case to put to those managers on your behalf — for
> protected time, or support, or a longer run-in. So when we get to workload, the more
> concrete you can be about days and what you had to drop, the more use I can make of it.
>
> I'm recording and Teams will produce a transcript. It stays on my machine, off the
> shared drive, and I'll delete it once the review is written. It'll be processed by an AI
> tool to help me pull the themes out.
>
> The most useful thing you can do is tell me where it went badly. I've had a long time
> to get attached to how this project works and I need someone to tell me which bits are
> actually annoying. Is that all right — anything you want to ask before I start
> recording?

*Start recording only after they answer.*

---

## 1. Warm-up (4 min)

**Talk me through what you actually did — from the day you were asked, to the chapter
being finished.**

- Where did the time go? Which stage ate the most?
- Where did you get stuck for more than half a day?
- What did you do when you got stuck — who or what did you turn to first?

*This orients them, gives you a chronology to refer back to, and the "got stuck" answers
usually seed half the rest of the interview.*

---

## 2. The rationale (5 min)

**What was your understanding of why we did it this way — code, shared repo, reproducible
pipeline — rather than everyone producing a Word document and a spreadsheet?**

- Did that reasoning convince you at the time? What about now, at the end?
- Where did you disagree with it? *(Ask this even if they say they agreed: "even if you
  were broadly on board — where did you think we were overdoing it?")*
- If you'd been left to do this chapter however you wanted, what would you have done
  instead? What would have been better about that? What would have been worse?

*Do not merge understanding and agreement. Someone can grasp the argument perfectly and
still think it was the wrong call, and that person's view is the most valuable in the room.*

*For Simon:* you already knew R and Quarto, so the learning curve questions land
differently for you. Instead: **where do you think the design is wrong on its own terms —
not hard to learn, just badly built?** And: watching colleagues come to it cold, what did
you see them struggle with that they might not report themselves?

---

## 3. Getting up to speed (6 min)

*Open with their pre-form rating on learning resources.*

**You gave the learning resources a [N]. Tell me about that.**

- What would have made it a [N+3]?
- What was the hardest single concept or tool to get your head round?
- Was there a point where you thought you weren't going to manage it? What changed?
- Which resources did you go back to more than once? Which did you open once and never
  again?
- If a new analyst joined tomorrow, what would you tell them to read first — and what
  would you tell them to ignore?

**Git and the shared repo specifically — how did that go?**

- Merge conflicts, branches, pull requests: did any of that bite you?
- Did you ever avoid doing something because you weren't sure what git would do?

**Setting up the environment — R, renv, Positron, the language server. Did that work
first time?**

---

## 4. The FACT table contract (5 min)

*Open with their pre-form rating.*

**You gave the FACT contract a [N] for how easy it was to work with. What's behind that?**

- What did you understand it to be for? *(Genuinely asking what they thought, not checking
  whether they got it right. If the answer is "I never really worked out why", that's a
  finding about the documentation, not about them.)*
- Where did it fight you? Any specific error you remember?
- The three-column shape, the validation rules, one file per indicator — did any of those
  feel wrong for your data?
- Did the shared summary tables and sparklines feel worth the constraint, once you saw
  the assembled report?

*For Simon:* **if you'd designed the contract, what would you have done differently?**
Push for the technical answer here — he's the one participant who can critique the
implementation rather than the experience of it, and that critique is worth more to you
than his rating.

---

## 5. Data and analysis (7 min)

**What was hard about sourcing the data for your indicators?**

- Anything you wanted to show and couldn't, because the data doesn't exist at the right
  geography or frequency?
- Where are we relying on a national figure that would be much better as a local one?
  What would it take to get the local one?
- Anything in your chapter you're not fully comfortable standing behind?

**How was R as a tool for this work — honestly, good and bad?**

- What did it make easy that would have been hard in Excel or Power BI? And the reverse?
- Where did you use AI help? What did it get right, and what did it send you down a blind
  alley on?
- When AI wrote code for you, did you understand it well enough to fix it when it broke?
- *For anyone who used AI heavily:* if those tools went away tomorrow, could you still
  maintain your chapter?

---

## 6. Pace, workload and coordination (8 min)

*This is the section you have the strongest incentive to argue in. Don't.*

**Was your part deliverable in the time available — and what did it cost you elsewhere?**

- Where did the timetable pinch hardest?
- Was the time protected, or did you find it out of your own hours?
- What did you drop or delay to make room for this? *(Push for the specific piece of work.
  This is the sentence that lands with a commissioning manager.)*
- Knowing what you know now, how many days would the same chapter take you next cycle?
  How much of this year's time was one-off learning that won't recur?
- *For Megan:* you did two chapters. Was that ever reflected in what was asked of you?
- *For Stuart and Simon:* you shared a chapter. How did you split it, and did sharing make
  it lighter or just differently awkward? Would you recommend pairing to others next time?

**You rated coordination [N] and the brief [N]. Take me through those.**

- At what point did you know what a finished chapter was supposed to look like? Was that
  early enough?
- Were there decisions about the report you'd like to have been consulted on?
- How did you find the review and feedback on your draft — timely, useful, too much, too
  little?
- Anything you needed from me that you didn't get, or had to ask for twice?
- What did I get wrong that I probably don't know I got wrong?

---

## 7. Afterwards and next time (6 min)

**Since finishing — have you used any of this on other work? Do you expect to?**

**You rated your confidence in updating your own chapter next cycle at [N]. What would
have to be true for that to be a 9?**

- Could a colleague pick your chapter up from the README and refresh it, without you?
- Is there anything only you know that isn't written down anywhere?

**Do you think anyone reads this report? Did that affect how you approached it?**

**If we run this again next year, what's the one change that would make the biggest
difference to you?**

- And what should we absolutely not change?

**I'm going to the commissioning managers with this. If I could win you one thing —
protected days, a longer run-in, a dedicated support session, someone else doing the data
sourcing — what's the one to ask for?**

- What would that get them in return? *(You need the manager-facing half of the argument,
  and the analyst is better placed to make it than you are.)*

*For Simon:* **should we be growing this capability across the team, or keeping it with
the two or three people who take to it?** He's the only participant with the standing to
answer that, and it's the strategic question underneath the whole review.

---

## Close (6 min)

**Anything I haven't asked about that I should have?**

**Is there anything you've been sitting on that you'd like to say now the questions are
over?** *(Ask it. It is routinely the most productive minute of the interview.)*

Then, off-recording:

- Repeat the redaction offer concretely: they'll get their quotes by email and can strike
  any of them.
- Ask whether anything from the last 45 minutes they'd rather you treated as unattributed
  from the start.
- Tell them when they'll see the draft.

---

## Interviewer notes — fill in immediately afterwards

Within ten minutes, before the next call. The transcript won't capture any of this.

- Overall tone — guarded, open, resigned, enthusiastic?
- Where did they hesitate, or visibly pick their words?
- Anything said before recording started or after it stopped?
- The one thing you'd have asked with another ten minutes:
