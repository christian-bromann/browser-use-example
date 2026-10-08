---
name: google-flights
description: Search Google Flights in the sandbox browser and extract comparable flight options (price, times, duration, stops, airline). Use for any flight search or fare comparison.
---

# Google Flights

Use the `browser` skill for `wdio session` basics. This skill is the recipe for
Google Flights.

## 1. Open a search with a URL

Google Flights understands a plain-English query in `q`. Use IATA codes and ISO
dates, URL-encode the query, and pin language, region and currency so the page
reads the same every time:

```sh
wdio session open chrome "https://www.google.com/travel/flights?q=Flights%20from%20SFO%20to%20LAX%20on%202026-11-12%20through%202026-11-15&hl=en&gl=us&curr=USD" --arg=--no-sandbox --arg=--disable-dev-shm-usage
```

Query shapes that work:

- Round trip: `Flights from SFO to LAX on 2026-11-12 through 2026-11-15`
- One way: `One way flights from JFK to LHR on 2026-11-20`
- Cabin and travellers: `Business class flights for 2 adults from SEA to NRT on 2026-12-01 through 2026-12-10`

The page opens with the search filled in. Check the origin, destination and
dates in the `open` output before you trust the results. If one is wrong, fix
it in the form (`fill`, then pick the suggestion) instead of guessing.

For a session that is already open, use `wdio session navigate "<url>"`.

## 2. Pick the ranking

Results show under the **Best** tab. For the lowest fares, click the tab whose
name starts with "Cheapest":

```sh
wdio session find "Cheapest"
wdio session click e30   # the ref `find` printed for the tab
```

Filters (Stops, Airlines, Bags, Times, Duration) are buttons above the results.
Use them when the user has constraints, for example nonstop only.

## 3. Extract the results

Every result row carries a full summary in its `aria-label`. Read them all in
one call instead of walking the snapshot:

```sh
wdio session exec <<'JS'
const flights = await browser.execute(() =>
  [...new Set([...document.querySelectorAll('[aria-label^="From "]')]
    .map((el) => el.getAttribute('aria-label').replace(/\s+Select flight$/, '').trim()))])
console.log(flights.slice(0, 15).join('\n'))
JS
```

Each line looks like:

```
From 325 US dollars. Nonstop flight with American. Leaves John F. Kennedy International Airport at 10:10 AM on Friday, November 20 and arrives at Heathrow Airport at 10:10 PM on Friday, November 20. Total duration 7 hr.
```

If it prints nothing, the results are still loading: `wdio session wait 2000`
and run it again.

For round trips, the listed price is the round-trip total for the outbound
flight shown. Return flights are picked on the next page, and you do not need
them for a comparison.

## 4. Show the evidence

After each search you compare, take a screenshot of the results and open it
with `read_file` (see the `browser` skill):

```sh
wdio session screenshot --path screenshots/jfk-lhr-2026-11-20-cheapest.png
```

## Comparing variants

For flexible dates or nearby airports, run one search per variant: `navigate`
to a new `q` URL, extract, and screenshot. Then put all of them in a single
table. Keep the variant (date or airport) as a column so differences are
obvious.

## Do not

- Do not click "Select flight", "Book" or partner links: you compare, you never book.
- Do not sign in or enter personal or payment details.
- Do not report a price you did not read from the page.
