from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from app.config import get_settings
import urllib.parse

settings = get_settings()


def _make_engine():
    url = settings.DATABASE_URL
    connect_args = {}

    # asyncpg does not support sslmode/channel_binding as query params.
    # Strip them and pass ssl=True via connect_args instead.
    parsed = urllib.parse.urlparse(url)
    params = urllib.parse.parse_qs(parsed.query, keep_blank_values=True)
    needs_ssl = 'sslmode' in params or 'channel_binding' in params
    if needs_ssl:
        connect_args['ssl'] = True
        filtered = {k: v for k, v in params.items()
                    if k not in ('sslmode', 'channel_binding')}
        new_query = urllib.parse.urlencode(filtered, doseq=True)
        url = urllib.parse.urlunparse(parsed._replace(query=new_query))

    return create_async_engine(
        url,
        echo=settings.DEBUG,
        future=True,
        connect_args=connect_args,
    )


# Create async engine
engine = _make_engine()

# Create async session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

# Create declarative base
Base = declarative_base()


async def get_db() -> AsyncSession:
    """Dependency for getting async database sessions."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db():
    """Initialize database tables."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
