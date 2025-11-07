# Stage 1: Builder
FROM python:3.11-slim AS image1
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt 

COPY . .

# Stage 2: Final image
FROM python:3.11-slim
WORKDIR /app

COPY --from=image1 /usr/local /usr/local

COPY --from=image1 /app /app

EXPOSE 5001

CMD ["python", "main.py"]
