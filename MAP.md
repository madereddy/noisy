# Carte du projet — dépendances par fichier

```
noisy.py
  → noisy_lib.config           (constantes)
  → noisy_lib.config_loader    (parser CLI, validation)
  → noisy_lib.crawler          (UserCrawler)
  → noisy_lib.fetchers         (fetch_crux_top_sites, fetch_user_agents)
  → noisy_lib.profiles         (UAPool, UserProfile, _UA_FALLBACK)
  → noisy_lib.rate_limiter     (DomainRateLimiter)
  → noisy_lib.structures       (LRUSet)
  → noisy_lib.workers          (dns_noise_worker, stats_reporter, refresh_user_agents_loop)

noisy_lib/config_loader.py
  → noisy_lib.config           (DEFAULT_*)

noisy_lib/crawler.py
  → noisy_lib.config           (DNS_CACHE_TTL, MAX_HEADER_SIZE)
  → noisy_lib.extractor        (extract_links)
  → noisy_lib.fetch_client     (fetch_with_retry)
  → noisy_lib.profiles         (UserProfile, _activity_pause_seconds)
  → noisy_lib.rate_limiter     (DomainRateLimiter)
  → noisy_lib.structures       (BoundedDict, LRUSet)

noisy_lib/fetch_client.py
  → noisy_lib.config           (MAX_RESPONSE_BYTES, MAX_RETRIES, REQUEST_TIMEOUT, RETRY_BASE_DELAY)
  → noisy_lib.profiles         (SSL_CONTEXT)

noisy_lib/rate_limiter.py
  → noisy_lib.config           (DEFAULT_DOMAIN_DELAY)
  → noisy_lib.structures       (TTLDict)

noisy_lib/fetchers.py
  → noisy_lib.config           (CRUX_TOP_CSV, DEFAULT_*, MAX_RESPONSE_BYTES, UA_PAGE_URL)
  → noisy_lib.profiles         (SSL_CONTEXT, _UA_FALLBACK)

noisy_lib/workers.py
  → noisy_lib.config           (DEFAULT_DNS_*_SLEEP)
  → noisy_lib.fetchers         (fetch_user_agents)
  → noisy_lib.profiles         (_diurnal_weight)

noisy_lib/extractor.py
  → stdlib: html.parser, urllib.parse

noisy_lib/profiles.py
  → stdlib: asyncio, math, random, ssl, time

noisy_lib/structures.py
  → stdlib: collections, time

noisy_lib/config.py
  → rien (source des constantes)
```

## Flux d'exécution principal

```
main()
  └─ build_parser() + load_config_file()     [config_loader]
  └─ main_async(args)
       ├─ fetch_crux_top_sites()             [fetchers]
       ├─ fetch_user_agents()                [fetchers]
       ├─ DomainRateLimiter()               [rate_limiter]  ← partagé
       ├─ LRUSet shared_visited             [structures]    ← partagé
       ├─ N × UserCrawler.run()             [crawler]
       │     ├─ crawl_worker()
       │     │    └─ fetch(url)
       │     │         ├─ rate_limiter.wait()  [rate_limiter]
       │     │         ├─ fetch_with_retry()   [fetch_client]
       │     │         └─ extract_links()      [extractor]
       ├─ dns_noise_worker() × M            [workers]
       ├─ stats_reporter()                  [workers]
       └─ refresh_user_agents_loop()        [workers]
```

## Taille des fichiers sources

| Fichier | Lignes | Rôle |
|---------|--------|------|
| `noisy_lib/config.py` | ~55 | Constantes |
| `noisy_lib/structures.py` | ~80 | LRU/TTL |
| `noisy_lib/extractor.py` | ~45 | HTML links |
| `noisy_lib/fetch_client.py` | ~50 | HTTP retry |
| `noisy_lib/rate_limiter.py` | ~45 | Domain delay |
| `noisy_lib/profiles.py` | ~120 | UA/profils |
| `noisy_lib/fetchers.py` | ~100 | CRUX/UA fetch |
| `noisy_lib/workers.py` | ~90 | Tâches fond |
| `noisy_lib/config_loader.py` | ~115 | CLI/validation |
| `noisy_lib/crawler.py` | ~155 | Crawl user |
| `noisy.py` | ~95 | Entry point |
