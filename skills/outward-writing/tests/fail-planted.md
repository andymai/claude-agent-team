# Retry the nightly export

<!-- template comment that is long enough to break a sentence limit if the checker read it as prose at all -->
We have changed the retry logic because the export job is failing on large tenants, and the queue worker that handles the batch was restarted by someone at night.

The fix was merged yesterday. It is working now. Please verify the dashboard. Then check the logs. Confirm the count. Tell me. Thanks again.

| Column | A very long cell with many many words that would trip the sentence limit if tables counted as prose text |
|---|---|

> A quoted line that is much too long for STE but quotes stay as they are because we never edit the words of other people.

```
a code block line with many many words that the checker must skip because code is not prose and has no sentence limit at all
```
See [the runbook](https://example.com/a/very/long/path) and `scripts/check.py` for details, e.g. the flags.

<!-- expect: sentence has 29 words -->
<!-- expect: paragraph has 7 sentences -->
<!-- expect: present perfect "have changed" -->
<!-- expect: "-ing" verb "is failing" -->
<!-- expect: possible passive "was merged" -->
<!-- expect: one action, more than one verb? -->
<!-- reject: line 3: -->
<!-- reject: line 8: -->
<!-- reject: line 11: -->
<!-- reject: line 14: -->
