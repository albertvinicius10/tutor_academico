# app/cache.py
import redis
import json
from . import config

# Pool de conexões para reutilização
redis_pool = redis.ConnectionPool.from_url(config.REDIS_URL, decode_responses=True)

def get_cache():
    """Dependency to get a Redis client from the connection pool."""
    r = redis.Redis(connection_pool=redis_pool)
    try:
        yield r
    finally:
        # A conexão é retornada ao pool automaticamente
        pass