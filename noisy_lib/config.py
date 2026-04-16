# config.py - Toutes constantes du projet
# IN: rien | OUT: constantes importées | MODIFIE: rien
# APPELÉ PAR: tous modules | APPELLE: rien

# ---- CRUX ----
CRUX_TOP_CSV = "https://raw.githubusercontent.com/zakird/crux-top-lists/main/data/global/current.csv.gz"
DEFAULT_CRUX_COUNT = 10_000
DEFAULT_CRUX_REFRESH_DAYS = 31

# ---- USER AGENT POOL ----
UA_PAGE_URL = "https://www.useragents.me"
DEFAULT_UA_COUNT = 50
DEFAULT_UA_REFRESH_DAYS = 7

# ---- CRAWLER ----
DEFAULT_MAX_QUEUE_SIZE = 100_000
DEFAULT_MAX_DEPTH = 5
DEFAULT_THREADS = 10
DEFAULT_NUM_USERS = 5
DEFAULT_MAX_LINKS_PER_PAGE = 50

# ---- TIMING ----
DEFAULT_MIN_SLEEP = 2
DEFAULT_MAX_SLEEP = 15
DEFAULT_DOMAIN_DELAY = 5.0
DEFAULT_DNS_MIN_SLEEP = 5
DEFAULT_DNS_MAX_SLEEP = 30

# ---- CONNEXIONS (par user) ----
DEFAULT_TOTAL_CONNECTIONS = 40
DEFAULT_CONNECTIONS_PER_HOST = 4
DEFAULT_KEEPALIVE_TIMEOUT = 30
DNS_CACHE_TTL = 120

# ---- RÉSEAU ----
REQUEST_TIMEOUT = 15
MAX_RESPONSE_BYTES = 512 * 1024
MAX_HEADER_SIZE = 32 * 1024

# ---- RUNTIME ----
DEFAULT_RUN_TIMEOUT_SECONDS = None
SECONDS_PER_DAY = 24 * 60 * 60
DEFAULT_DNS_WORKERS = 3

# ---- CACHE ----
DEFAULT_VISITED_MAX = 500_000

# ---- RETRY ----
MAX_RETRIES = 3
RETRY_BASE_DELAY = 1.0

# ---- DASHBOARD ----
DEFAULT_DASHBOARD_PORT = 8080
DASHBOARD_UPDATE_INTERVAL = 2
DEFAULT_POST_NOISE_WORKERS = 1
ALERT_FAIL_THRESHOLD = 30.0  # % failure rate to trigger alert
WEBHOOK_TIMEOUT = 10

# ---- URL BLACKLIST ----
DEFAULT_URL_BLACKLIST = [
    "t.co", "t.umblr.com", "messenger.com", "itunes.apple.com",
    "l.facebook.com", "bit.ly", "mediawiki",
    ".css", ".ico", ".xml", ".json", ".png", ".iso", ".pdf", ".zip", ".exe", ".dmg",
    "intent/tweet", "twitter.com/share", "dialog/feed?",
    "zendesk", "clickserve",
    "logout", "signout", "sign-out", "log-out",
    "javascript:", "mailto:", "tel:",
]
