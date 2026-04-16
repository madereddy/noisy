# dashboard.py - Serveur dashboard temps réel (FastAPI + WebSocket)
# IN: crawlers, shared_visited, rate_limiter, ua_pool, shared_metrics | OUT: app FastAPI | MODIFIE: rien
# APPELÉ PAR: noisy.py | APPELLE: config, fastapi, uvicorn

import asyncio
import json
import logging
import math
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional, TYPE_CHECKING

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse, PlainTextResponse, JSONResponse

from .config import ALERT_FAIL_THRESHOLD, DASHBOARD_UPDATE_INTERVAL, WEBHOOK_TIMEOUT
from .profiles import _diurnal_weight

if TYPE_CHECKING:
    from .crawler import SharedMetrics, UserCrawler
    from .profiles import UAPool
    from .rate_limiter import DomainRateLimiter
    from .structures import LRUSet

log = logging.getLogger(__name__)

STATIC_DIR = Path(__file__).parent / "static"


class MetricsCollector:
    """Collecte les métriques depuis les crawlers et l'état partagé."""

    def __init__(
        self,
        crawlers: List["UserCrawler"],
        shared_visited: "LRUSet",
        rate_limiter: "DomainRateLimiter",
        ua_pool: "UAPool",
        shared_metrics: "SharedMetrics",
        webhook_url: Optional[str] = None,
    ):
        self.crawlers = crawlers
        self.shared_visited = shared_visited
        self.rate_limiter = rate_limiter
        self.ua_pool = ua_pool
        self.shared_metrics = shared_metrics
        self.webhook_url = webhook_url
        self._start_time = time.monotonic()
        self._prev_visited = 0
        self._prev_time = time.monotonic()
        self._alert_fired = False

    def collect(self) -> dict:
        now = time.monotonic()
        total_v = sum(c.stats["visited"] for c in self.crawlers)
        total_f = sum(c.stats["failed"] for c in self.crawlers)
        total_q = sum(c.stats["queued"] for c in self.crawlers)
        total_4xx = sum(c.stats["client_errors"] for c in self.crawlers)
        total_5xx = sum(c.stats["server_errors"] for c in self.crawlers)
        total_net = sum(c.stats["network_errors"] for c in self.crawlers)
        total_bytes = sum(c.stats["bytes"] for c in self.crawlers)
        elapsed = now - self._prev_time
        rps = (total_v - self._prev_visited) / elapsed if elapsed > 0 else 0.0
        fail_pct = total_f / (total_v + total_f) * 100 if (total_v + total_f) > 0 else 0.0
        self._prev_visited, self._prev_time = total_v, now

        # Alert check
        alert_active = fail_pct > ALERT_FAIL_THRESHOLD and (total_v + total_f) > 20

        users = []
        for c in self.crawlers:
            users.append({
                "id": c.profile.user_id,
                "visited": c.stats["visited"],
                "failed": c.stats["failed"],
                "client_errors": c.stats["client_errors"],
                "server_errors": c.stats["server_errors"],
                "network_errors": c.stats["network_errors"],
                "queued": c.stats["queued"],
                "bytes": c.stats["bytes"],
                "ua": c.profile.ua[:80],
                "diurnal_weight": round(c.profile.diurnal_weight(), 2),
            })

        # Diurnal curve (24 points)
        hour_now = time.localtime().tm_hour + time.localtime().tm_min / 60
        diurnal_curve = []
        for h in range(24):
            diurnal_curve.append({"hour": h, "weight": round(_diurnal_weight(h), 2)})

        # Bandwidth
        uptime_s = now - self._start_time
        bw_kbps = (total_bytes / 1024) / uptime_s if uptime_s > 0 else 0

        return {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "uptime_seconds": round(uptime_s),
            "aggregate": {
                "visited": total_v,
                "failed": total_f,
                "client_errors": total_4xx,
                "server_errors": total_5xx,
                "network_errors": total_net,
                "queued": total_q,
                "rps": round(rps, 2),
                "fail_pct": round(fail_pct, 2),
                "unique_urls": len(self.shared_visited),
                "active_domains": self.rate_limiter.active_domains_count(),
                "total_bytes": total_bytes,
                "bandwidth_kbps": round(bw_kbps, 1),
                "alert_active": alert_active,
            },
            "users": users,
            "diurnal_curve": diurnal_curve,
            "current_hour": round(hour_now, 1),
            "top_domains": self.shared_metrics.top_domains(20),
            "tld_distribution": self.shared_metrics.tld_distribution(),
            "recent_errors": list(self.shared_metrics.recent_errors),
            "request_log": [
                {"ts": e.ts, "user_id": e.user_id, "url": e.url[:100],
                 "domain": e.domain, "status": e.status, "bytes": e.bytes}
                for e in list(self.shared_metrics.request_log)[-50:]
            ],
            "fingerprint": self.shared_metrics.fingerprint_score(),
            "paused": self.shared_metrics.is_paused,
        }

    def get_runtime_config(self) -> dict:
        if not self.crawlers:
            return {}
        c = self.crawlers[0]
        return {
            "num_users": len(self.crawlers),
            "min_sleep": c.min_sleep,
            "max_sleep": c.max_sleep,
            "max_depth": c.max_depth,
            "concurrency": c.concurrency,
            "max_links_per_page": c.max_links_per_page,
            "domain_delay": self.rate_limiter._domain_delay,
        }

    def apply_config(self, data: dict) -> list:
        errors = []
        safe = {}
        for key, cast, lo, hi in [
            ("min_sleep", float, 0.1, 300),
            ("max_sleep", float, 0.1, 600),
            ("max_depth", int, 1, 50),
            ("max_links_per_page", int, 1, 500),
            ("domain_delay", float, 0, 120),
        ]:
            if key in data:
                try:
                    v = cast(data[key])
                    if not (lo <= v <= hi):
                        errors.append(f"{key}: doit être entre {lo} et {hi}")
                    else:
                        safe[key] = v
                except (ValueError, TypeError):
                    errors.append(f"{key}: valeur invalide")
        if errors:
            return errors
        for c in self.crawlers:
            if "min_sleep" in safe:
                c.min_sleep = safe["min_sleep"]
            if "max_sleep" in safe:
                c.max_sleep = safe["max_sleep"]
            if "max_depth" in safe:
                c.max_depth = safe["max_depth"]
            if "max_links_per_page" in safe:
                c.max_links_per_page = safe["max_links_per_page"]
        if "domain_delay" in safe:
            self.rate_limiter.domain_delay = safe["domain_delay"]
        return []

    def prometheus_metrics(self) -> str:
        lines = []
        total_v = sum(c.stats["visited"] for c in self.crawlers)
        total_f = sum(c.stats["failed"] for c in self.crawlers)
        total_4xx = sum(c.stats["client_errors"] for c in self.crawlers)
        total_5xx = sum(c.stats["server_errors"] for c in self.crawlers)
        total_net = sum(c.stats["network_errors"] for c in self.crawlers)
        total_bytes = sum(c.stats["bytes"] for c in self.crawlers)
        lines.append(f"# HELP noisy_requests_total Total HTTP requests")
        lines.append(f"# TYPE noisy_requests_total counter")
        lines.append(f'noisy_requests_total{{status="ok"}} {total_v}')
        lines.append(f'noisy_requests_total{{status="client_error"}} {total_4xx}')
        lines.append(f'noisy_requests_total{{status="server_error"}} {total_5xx}')
        lines.append(f'noisy_requests_total{{status="network_error"}} {total_net}')
        lines.append(f"# HELP noisy_bytes_total Total bytes received")
        lines.append(f"# TYPE noisy_bytes_total counter")
        lines.append(f"noisy_bytes_total {total_bytes}")
        lines.append(f"# HELP noisy_unique_urls Unique URLs visited")
        lines.append(f"# TYPE noisy_unique_urls gauge")
        lines.append(f"noisy_unique_urls {len(self.shared_visited)}")
        lines.append(f"# HELP noisy_active_domains Active domains in rate limiter")
        lines.append(f"# TYPE noisy_active_domains gauge")
        lines.append(f"noisy_active_domains {self.rate_limiter.active_domains_count()}")
        for c in self.crawlers:
            uid = c.profile.user_id
            lines.append(f'noisy_user_visited{{user="{uid}"}} {c.stats["visited"]}')
            lines.append(f'noisy_user_failed{{user="{uid}"}} {c.stats["failed"]}')
        return "\n".join(lines) + "\n"


def create_app(collector: MetricsCollector) -> FastAPI:
    app = FastAPI(title="Noisy Dashboard", docs_url=None, redoc_url=None)

    _cached_html = (STATIC_DIR / "dashboard.html").read_text(encoding="utf-8")

    @app.get("/", response_class=HTMLResponse)
    async def index():
        return HTMLResponse(_cached_html)

    @app.get("/api/metrics")
    async def metrics():
        return collector.collect()

    @app.get("/api/export")
    async def export_metrics():
        data = collector.collect()
        return JSONResponse(
            content=data,
            headers={"Content-Disposition": "attachment; filename=noisy-metrics.json"},
        )

    @app.get("/api/config")
    async def get_config():
        return collector.get_runtime_config()

    @app.post("/api/config")
    async def set_config(data: dict):
        errors = collector.apply_config(data)
        if errors:
            return JSONResponse(status_code=400, content={"errors": errors})
        return {"status": "ok", "config": collector.get_runtime_config()}

    @app.post("/api/pause")
    async def pause():
        collector.shared_metrics.pause()
        log.info("[DASHBOARD] crawlers mis en pause")
        if collector.webhook_url:
            await _fire_webhook(collector.webhook_url, "paused", {})
        return {"paused": True}

    @app.post("/api/resume")
    async def resume():
        collector.shared_metrics.resume()
        log.info("[DASHBOARD] crawlers repris")
        if collector.webhook_url:
            await _fire_webhook(collector.webhook_url, "resumed", {})
        return {"paused": False}

    @app.get("/metrics", response_class=PlainTextResponse)
    async def prometheus():
        return PlainTextResponse(collector.prometheus_metrics(), media_type="text/plain; version=0.0.4")

    @app.websocket("/ws/metrics")
    async def ws_metrics(websocket: WebSocket):
        await websocket.accept()
        log.info("[DASHBOARD] client WebSocket connecté")
        try:
            while True:
                data = collector.collect()
                await websocket.send_text(json.dumps(data))
                # Webhook alert check
                if data["aggregate"]["alert_active"] and not collector._alert_fired:
                    collector._alert_fired = True
                    if collector.webhook_url:
                        await _fire_webhook(collector.webhook_url, "alert_high_fail_rate", data["aggregate"])
                elif not data["aggregate"]["alert_active"]:
                    collector._alert_fired = False
                await asyncio.sleep(DASHBOARD_UPDATE_INTERVAL)
        except WebSocketDisconnect:
            log.info("[DASHBOARD] client WebSocket déconnecté")

    return app


async def _fire_webhook(url: str, event: str, data: dict):
    """Envoie un webhook POST (http/https uniquement)."""
    if not url.startswith(("http://", "https://")):
        log.warning(f"[WEBHOOK] URL invalide ignorée: {url}")
        return
    import aiohttp
    payload = {"event": event, "timestamp": datetime.now(timezone.utc).isoformat(), "data": data}
    try:
        async with aiohttp.ClientSession() as session:
            await session.post(url, json=payload, timeout=aiohttp.ClientTimeout(total=WEBHOOK_TIMEOUT))
        log.info(f"[WEBHOOK] {event} envoyé à {url}")
    except Exception as e:
        log.warning(f"[WEBHOOK] échec {url}: {e}")


async def start_dashboard(collector: MetricsCollector, port: int, host: str = "127.0.0.1"):
    """Lance le serveur uvicorn en tâche de fond asyncio."""
    import uvicorn

    app = create_app(collector)
    config = uvicorn.Config(app, host=host, port=port, log_level="warning")
    server = uvicorn.Server(config)
    log.info(f"[DASHBOARD] démarré sur http://{host}:{port}")
    await server.serve()
