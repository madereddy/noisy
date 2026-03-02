# Noisy

[![CircleCI](https://circleci.com/gh/madereddy/noisy/tree/master.svg?style=shield)](https://circleci.com/gh/madereddy/noisy/tree/master)
![Docker Pulls][pulls]

[pulls]: https://img.shields.io/docker/pulls/madereddy/noisy

**Noisy** is an async Python crawler that generates random HTTP/S traffic to mimic human browsing behaviour. It crawls top websites using dynamically refreshed, real user-agent strings, randomised delays, and per domain rate limiting making it useful for obfuscating real traffic patterns for privacy and testing purposes.

---

## Features

- Crawls up to 10,000 top sites sourced from [CrUX top lists](https://github.com/zakird/crux-top-lists), refreshed monthly.
- Fetches and rotates real User-Agent strings weekly from [useragents.me](https://www.useragents.me).
- Sends realistic browser headers (`Accept`, `Accept-Language`, `Cache-Control`, etc.) to reduce bot detection.
- Mimics human browsing with randomised per request delays and per domain rate limiting.
- Queue-based async architecture with configurable concurrency, connection pooling, and DNS caching.
- Supports Brotli, gzip, and deflate response decompression.
- Graceful shutdown on timeout or Ctrl+C.

---

## Getting Started

Clone the repository:

```bash
git clone https://github.com/madereddy/noisy.git
cd noisy
```

### Dependencies

Install required Python packages:

```bash
pip install -r requirements.txt
```

`requirements.txt`:

```
aiohttp==3.13.3
Brotli>=1.1.0
```

### Usage

Run the crawler directly:

```bash
python noisy.py
```

All arguments are optional - the crawler fetches its own seed list and UA pool at startup.

```
$ python noisy.py --help
usage: noisy.py [-h] [--log {debug,info,warning,error}] [--logfile LOGFILE]
                [--threads THREADS] [--max_depth MAX_DEPTH]
                [--min_sleep MIN_SLEEP] [--max_sleep MAX_SLEEP]
                [--domain_delay DOMAIN_DELAY]
                [--total_connections TOTAL_CONNECTIONS]
                [--connections_per_host CONNECTIONS_PER_HOST]
                [--keepalive_timeout KEEPALIVE_TIMEOUT]
                [--crux_refresh_days CRUX_REFRESH_DAYS]
                [--ua_refresh_days UA_REFRESH_DAYS]
                [--max_queue_size MAX_QUEUE_SIZE]
                [--timeout TIMEOUT]

options:
  -h, --help                    Show this help message and exit
  --log                         Logging level (debug, info, warning, error). Default: info
  --logfile LOGFILE             Optional path to write logs to a file

  --threads THREADS             Number of concurrent crawlers. Default: 50
  --max_depth MAX_DEPTH         Maximum link depth per crawl. Default: 5

  --min_sleep MIN_SLEEP         Minimum sleep between requests (seconds). Default: 2.0
  --max_sleep MAX_SLEEP         Maximum sleep between requests (seconds). Default: 15.0
  --domain_delay DOMAIN_DELAY   Minimum delay between requests to the same domain (seconds). Default: 5.0

  --total_connections           Total connection pool size. Default: 200
  --connections_per_host        Max connections per host. Default: 10
  --keepalive_timeout           Keep-alive timeout (seconds). Default: 30

  --crux_refresh_days           How often to refresh the CrUX site list (days). Default: 31
  --ua_refresh_days             How often to refresh the UA pool from useragents.me (days). Default: 7

  --max_queue_size              Maximum URL queue size. Default: 100,000
  --timeout TIMEOUT             Stop crawler after N seconds. Default: run forever
```

### Output

```
INFO - Fetching CRUX top sites...
INFO - Loaded 10000 CRUX sites
INFO - Fetching user agents from useragents.me...
INFO - Loaded 50 user agents
DEBUG - Visited: https://www.google.com
DEBUG - Visited: https://www.wikipedia.org
DEBUG - Fetch failed https://example.com: 403, message='Forbidden'
DEBUG - Visited: https://www.reddit.com
INFO - UA pool refreshed (50 agents)
INFO - CRUX refresh complete
```

Log levels:
- `INFO` — background refresh events
- `WARNING` — UA pool refresh failure
- `DEBUG` — visited URLs, fetch errors (403s, timeouts, connection failures), and internal aiohttp request detail

---

### Docker

Pull and run the container:

```bash
docker run -it madereddy/noisy
```

Pass arguments directly:

```bash
docker run -it madereddy/noisy --threads 25 --min_sleep 3 --max_sleep 10
```

Or use Docker Compose:

```yaml
services:
  noisy:
    image: madereddy/noisy:latest
    container_name: noisy
    restart: always
```

---

## How It Works

On startup, Noisy:
1. Fetches the CrUX top 10,000 sites list and primes the URL queue
2. Fetches 50 real UA strings from useragents.me
3. Spawns N concurrent async worker coroutines (default: 50)

Each worker:
- Pulls a URL from the queue
- Waits for the per domain rate limit window
- Sends a request with a randomly selected UA and realistic browser headers
- Extracts links from the response and enqueues them up to `max_depth`
- Sleeps for a random interval before the next request

In the background:
- The CrUX list is refreshed every 31 days
- The UA pool is refreshed every 7 days from useragents.me

---

## Authors

- [**Itay Hury**](https://github.com/1tayH) — *Initial work*
- [**madereddy**](https://github.com/madereddy) — *Docker build + Python upgrade* 
- [**B3CKDOOR**](https://github.com/B3CKDOOR) — *Bugfixes*

## License

This project is licensed under the GNU GPLv3 License — see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Inspired by [1tayH/noisy](https://github.com/1tayH/noisy).
