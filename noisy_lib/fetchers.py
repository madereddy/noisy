# fetchers.py - Récupération données distantes (CRUX, user agents)
# IN: aiohttp.Session, count:int | OUT: List[str] | MODIFIE: rien
# APPELÉ PAR: noisy.py, workers.py | APPELLE: aiohttp, config, profiles

import asyncio
import csv
import gzip
import json
import logging
import random
import re
import ssl
from typing import List

import aiohttp

from .config import CRUX_TOP_CSV, DEFAULT_CRUX_COUNT, DEFAULT_UA_COUNT, MAX_RESPONSE_BYTES, UA_PAGE_URL
from .profiles import SSL_CONTEXT, _UA_FALLBACK

log = logging.getLogger(__name__)


async def fetch_crux_top_sites(
    session: aiohttp.ClientSession,
    count: int = DEFAULT_CRUX_COUNT,
) -> List[str]:
    """Charge les top sites CRUX depuis GitHub (CSV gzip)."""
    log.info(f"[DEBUT] fetch_crux_top_sites | count={count}")
    try:
        async with session.get(CRUX_TOP_CSV, ssl=SSL_CONTEXT, timeout=aiohttp.ClientTimeout(total=30)) as resp:
            if resp.status >= 400:
                log.error(f"[ERREUR] fetch_crux_top_sites | status={resp.status}")
                return []
            data = await resp.read()
    except (aiohttp.ClientError, asyncio.TimeoutError) as e:
        log.error(f"[ERREUR] fetch_crux_top_sites | {e}")
        return []

    try:
        csv_text = gzip.decompress(data).decode()
    except (OSError, ValueError) as e:
        log.error(f"[ERREUR] fetch_crux_top_sites decompress | {e}")
        return []

    reader = csv.DictReader(csv_text.splitlines())
    sites, seen = [], set()
    for row in reader:
        origin = row.get("origin")
        if origin and origin not in seen:
            seen.add(origin)
            sites.append(origin if origin.startswith("http") else f"https://{origin}")
        if len(sites) >= count:
            break

    log.info(f"[FIN] fetch_crux_top_sites | loaded={len(sites)}")
    return sites


async def fetch_user_agents(
    session: aiohttp.ClientSession,
    count: int = DEFAULT_UA_COUNT,
) -> List[str]:
    """Scrape les user agents réels depuis useragents.me."""
    log.info("[DEBUT] fetch_user_agents")
    rng = random.Random()
    try:
        async with session.get(
            UA_PAGE_URL, timeout=aiohttp.ClientTimeout(total=15),
            ssl=SSL_CONTEXT, headers={"User-Agent": rng.choice(_UA_FALLBACK)},
        ) as resp:
            if resp.status >= 400:
                log.warning(f"[WARN] fetch_user_agents | status={resp.status}")
                return []
            raw = await resp.content.read(MAX_RESPONSE_BYTES)
            text = raw.decode(resp.charset or "utf-8", errors="replace")

        agents, seen = [], set()
        for block in re.findall(r"\[\s*\{[^\[\]]+\}\s*\]", text):
            try:
                for entry in json.loads(block):
                    ua = entry.get("ua", "").strip()
                    if ua and ua not in seen:
                        seen.add(ua)
                        agents.append(ua)
            except (json.JSONDecodeError, AttributeError):
                continue

        if not agents:
            raise ValueError("Aucun UA trouvé sur useragents.me")
        result = agents[:count]
        log.info(f"[FIN] fetch_user_agents | loaded={len(result)}")
        return result

    except (aiohttp.ClientError, asyncio.TimeoutError, ssl.SSLError) as e:
        log.warning(f"[WARN] fetch_user_agents réseau | {e}")
        return []
    except Exception as e:
        log.error(f"[ERREUR] fetch_user_agents | {e}")
        return []
