# Retry the nightly export

The export job fails on large tenants. I changed the retry logic so that the worker retries each batch three times.

To test it:

- Run `make export` against the staging tenant.
- Make sure the dashboard shows 3 retries.
- Make sure the logs show no timeout errors.

Do not run the export on production before the migration finishes.
