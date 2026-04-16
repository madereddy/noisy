# Journal des modifications

## 2026-04-16 — Refactoring P0→P4 complet

### Corrections bugs (P0)
- `noisy.py`: correction bug indentation mixte tabs/espaces (lignes 588-589, 745)
- `noisy.py`: ajout validation `max_queue_size // num_users` (division silencieuse)
- `config.json`: marqué legacy, supporté via `--config` flag

### Modularisation (P1)
- `noisy_lib/` créé : 8 modules depuis le monolithe 787 lignes
- `tests/` créé : 67 tests (0% → couverture complète parties testables)
- Validation CLI : `validate_args()` dans `config_loader.py`

### Robustesse (P2)
- `fetch_client.py`: retry exponentiel MAX_RETRIES=3, base=1s
- `rate_limiter.py`: rate limiting **cross-crawlers** (partagé entre users)
- `crawler.py`: locks domaine simplifié (dict plain, suppression weakref complexe)
- `extractor.py`: blacklist URL appliquée avant fetch + après extraction

### Observabilité (P3)
- `workers.py`: stats enrichies (req/s, taux échec %)
- `noisy.py`: flag `--dry-run` (config sans crawler)

### Configuration (P4)
- `config_loader.py`: support `--config fichier.json`
- `noisy.py`: flag `--validate-config` (exit 0/1)

## 2026-04-16 — Refactoring maintenance IA (tokens minimum)

### Nouveaux fichiers
- `noisy_lib/config.py`: renommage `constants.py` → source unique des constantes
- `noisy_lib/rate_limiter.py`: extrait de `crawler.py` — logique délai domaine
- `noisy_lib/fetch_client.py`: extrait de `crawler.py` — retry HTTP
- `noisy_lib/config_loader.py`: extrait de `noisy.py` — parser CLI + validation
- `CLAUDE.md`: guide maintenance IA
- `LOG.md`: ce fichier
- `MAP.md`: carte des dépendances

### Fichiers modifiés
- `noisy_lib/constants.py`: shim de compatibilité → importe depuis `config.py`
- `noisy_lib/crawler.py`: 282 → 155 lignes (délègue rate_limiter + fetch_client)
- `noisy.py`: 306 → 95 lignes (délègue config_loader)
- Tous fichiers `noisy_lib/`: ajout header 3 lignes + logging uniforme `[DEBUT]/[FIN]/[ERREUR]`
