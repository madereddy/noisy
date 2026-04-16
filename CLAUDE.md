# CLAUDE.md — Guide maintenance IA pour Noisy

## Projet
Crawler async Python qui génère du trafic HTTP/DNS aléatoire pour masquer les habitudes de navigation.
Lance N utilisateurs virtuels qui crawlent les top 10 000 sites CRUX en parallèle.

## Lancer
```bash
python noisy.py                          # infini avec défauts
python noisy.py --dry-run                # voir config sans crawler
python noisy.py --validate-config        # valider config et quitter
python noisy.py --config config.json     # charger overrides JSON
python noisy.py --num_users 3 --timeout 60
```

## Tests
```bash
pip install -r requirements-dev.txt
python -m pytest tests/ -v              # 67 tests, < 1s
```

## Architecture — 1 fichier = 1 responsabilité

```
noisy.py              → Orchestration + entry point (95 lignes)
noisy_lib/
  config.py           → Toutes les constantes (55 lignes)
  config_loader.py    → Parser CLI + validation + lecture JSON (115 lignes)
  structures.py       → LRUSet / BoundedDict / TTLDict (80 lignes)
  profiles.py         → UserProfile / UAPool / diurnal model (120 lignes)
  extractor.py        → Extraction liens HTML + blacklist (45 lignes)
  fetchers.py         → Fetch CRUX sites + user agents (100 lignes)
  rate_limiter.py     → Délai inter-requêtes par domaine (45 lignes)
  fetch_client.py     → HTTP GET avec retry exponentiel (50 lignes)
  crawler.py          → UserCrawler — orchestration crawl (155 lignes)
  workers.py          → DNS noise / stats / UA refresh (90 lignes)
```

## Règle de modification

| Je veux changer... | Lire/modifier uniquement |
|--------------------|--------------------------|
| Une constante (timeout, délai...) | `config.py` |
| Parser CLI ou validation | `config_loader.py` |
| Comportement HTTP (retry, headers) | `fetch_client.py` |
| Délai entre requêtes domaine | `rate_limiter.py` |
| Extraction de liens | `extractor.py` |
| Simulation utilisateur (sleep, AFK) | `crawler.py` |
| Modèle d'activité heure/jour | `profiles.py` (_diurnal_weight) |
| Sources de sites/UA | `fetchers.py` |
| Stats ou bruit DNS | `workers.py` |

## Headers obligatoires (tout fichier noisy_lib)
```python
# nom.py - But en 5 mots
# IN: x | OUT: y | MODIFIE: z
# APPELÉ PAR: a | APPELLE: b
```

## Pattern logging uniforme
```python
log = logging.getLogger(__name__)

async def ma_fonction(x):
    log.info(f"[DEBUT] ma_fonction | {x=}")
    try:
        result = ...
        log.info(f"[FIN] ma_fonction | {result=}")
        return result
    except Exception as e:
        log.error(f"[ERREUR] ma_fonction | {e}")
        raise
```

## Invariants clés (PROTECTED)
- `DomainRateLimiter` est **partagé** entre tous les crawlers (cross-user rate limiting)
- `LRUSet shared_visited` est **partagé** — évite de visiter 2× la même URL
- `UAPool` est thread-safe (asyncio.Lock)
- Blacklist appliquée **avant** fetch ET **après** extraction (`extractor.py`)
- Retry uniquement sur erreurs 5xx et exceptions réseau (pas sur 4xx)
- `config.json` legacy supporté via `--config` (les flags CLI ont priorité)

## Statut projet
- **Refactoring P0→P4** : terminé (bugs, modularisation, tests, retry, rate limiting, observabilité, config)
- **Refactoring maintenance IA** : terminé (headers 3 lignes, logging uniforme, max ~150 lignes/fichier)
- **Tests** : 67 tests, tous verts, < 0.5s
- **Couverture** : structures, extractor, profiles, validation couverts ; crawler/fetchers/workers non testés (nécessitent mocks réseau)

## Décisions clés

| Décision | Choix | Raison |
|----------|-------|--------|
| Rate limiting | 1 `DomainRateLimiter` partagé entre tous crawlers | Évite que 5 users frappent le même domaine simultanément |
| Retry HTTP | Uniquement 5xx + exceptions réseau, pas 4xx | 4xx = erreur client intentionnelle, pas transitoire |
| Blacklist URL | Double filtre : avant fetch + après extraction | Économise requêtes ET évite d'enqueue des URLs inutiles |
| Domain locks | `dict` simple (remplace `weakref` + double dict) | Complexité inutile, même perf pour ce use case |
| Config file | `--config` explicite, pas d'auto-load | Comportement prévisible, pas de surprise si config.json legacy est dans le répertoire |
| Modularisation | `noisy_lib/` package, `constants.py` = shim compat | Tous imports internes via `config.py`, ancien code externe fonctionne encore |
| Logging | `[DEBUT]/[FIN]/[ERREUR]` + `log.debug` pour hot path | Uniform pour grep, pas de perf impact sur fetch (debug-only) |
