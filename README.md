# Noisy

[![CircleCI](https://circleci.com/gh/madereddy/noisy/tree/master.svg?style=shield)](https://circleci.com/gh/madereddy/noisy/tree/master)
![Docker Pulls][pulls]

[pulls]: https://img.shields.io/docker/pulls/madereddy/noisy

**Noisy** is a Python crawler that generates random HTTP traffic to mimic human browsing behavior. It can crawl top websites using dynamic user agents while slowing down requests to avoid hammering servers or DNS resolvers. The tool is useful for obfuscating real web traffic patterns for privacy and testing purposes.

---

## Features

- Crawls the top websites from [CrUX top lists](https://github.com/zakird/crux-top-lists) (up to 10,000 sites).  
- Dynamically generates random User-Agent strings for each request.  
- Mimics human browsing with randomized delays (`min_sleep` and `max_sleep`).  

---

## Getting Started

Clone the repository:

```
git clone https://github.com/madereddy/noisy.git
cd noisy
```

### Dependencies

Install required Python packages:
```
pip install -r requirements.txt
```

requirements.txt should include:
```
aiohttp
beautifulsoup4
random-user-agent
```

### Usage

Run the crawler directly:

```
python noisy.py
```

The program supports several command-line arguments:
```
$ python noisy.py --help
usage: noisy.py [-h] [--log LOG] [--logfile LOGFILE]
                [--threads THREADS] [--min_sleep MIN_SLEEP] [--max_sleep MAX_SLEEP]

optional arguments:
  -h, --help            Show this help message and exit
  --log LOG             Logging level (debug, info, warning, error). Default: info
  --logfile LOGFILE     Optional log file path
  --threads THREADS, -n Number of concurrent crawlers. Default: 5
  --min_sleep MIN_SLEEP Minimum sleep between requests (seconds). Default: 2.0
  --max_sleep MAX_SLEEP Maximum sleep between requests (seconds). Default: 5.0
```

The crawler automatically fetches the top sites and does not require a config file anymore.

### Output

The crawler logs visited URLs and warnings/errors:
```
INFO - Fetching top sites from CrUX CSV...
INFO - Fetched 10000 top sites.
INFO - Visited: https://www.google.com
INFO - Visited: https://www.wikipedia.org
WARNING - DNS/connection error fetching https://nonexistent.example.com: [Errno -2] Name or service not known
INFO - Visited: https://www.reddit.com
```
Log Level
  - INFO logs visited URLs.
  - WARNING logs DNS, timeout, or HTTP errors.
  - DEBUG  can show internal aiohttp requests if logging level is set to debug.

### Docker

Pull and run the container:
```
docker run -it madereddy/noisy
```

Or use Docker Compose:
```
services:
  noisy:
    image: madereddy/noisy:latest
    container_name: noisy
    restart: always
```
## Authors

* [**Itay Hury**](https://github.com/1tayH) - *Initial work*
* [**madereddy**](https://github.com/madereddy) - *Docker build + Python Upgrade*
* [**B3CKDOOR**](https://github.com/B3CKDOOR) - *Bugfixes*

## License

This project is licensed under the GNU GPLv3 License - see the [LICENSE](LICENSE) file for details

## Acknowledgments

This project has been inspired by
[1tayH/noisy](https://github.com/1tayH/noisy)