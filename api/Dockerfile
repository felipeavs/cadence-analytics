FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
COPY api/requirements.txt api/

RUN pip install --no-cache-dir -r api/requirements.txt

COPY api/ api/

EXPOSE 8000

CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
