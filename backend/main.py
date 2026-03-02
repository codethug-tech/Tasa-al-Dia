from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from services.rate_fetcher import get_all_rates

app = FastAPI(title="Tasa al Día API", version="1.0.0")

# Configure CORS for production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In strict production, change "*" to your specific app domains
    allow_credentials=True,
    allow_methods=["GET"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Tasa al Día Backend"}

@app.get("/api/v1/rates")
async def get_rates():
    """
    Returns a consolidated list of official, parallel, and crypto exchange rates.
    Results are cached for 10 minutes.
    """
    rates = await get_all_rates()
    return rates
