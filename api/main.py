from fastapi import FastAPI

app = FastAPI(
    title="Cadence Analytics API",
    version="0.1.0",
    description="API do pipeline de análise de dados de saúde e exercício.",
)


@app.get("/health")
def health_check():
    return {"status": "ok", "service": "cadence-analytics-api"}


@app.get("/")
def root():
    return {"message": "Cadence Analytics API - veja /docs para a documentação"}