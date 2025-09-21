# syntax=docker/dockerfile:1
# BuildKit optimized Dockerfile with advanced caching and multi-arch support

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

# Stage 1: Dependencies stage with cache mounts
FROM --platform=$BUILDPLATFORM python:3.11-slim AS dependencies

WORKDIR /app

# Use cache mount for apt packages
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Use cache mount for pip packages
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --user -r requirements.txt

# Stage 2: Model training stage (only if models don't exist)
FROM dependencies AS trainer

# Copy training script
COPY train.py .

# Check if models exist, if not train them
RUN if [ ! -f "model.pkl" ] || [ ! -f "encoders.pkl" ]; then \
        echo "Training models..." && python train.py; \
    else \
        echo "Models already exist, skipping training..."; \
    fi

# Stage 3: Final production stage
FROM --platform=$TARGETPLATFORM python:3.11-slim AS production

# Display build info for debugging
RUN echo "Building for platform: $TARGETPLATFORM, architecture: $TARGETARCH"

# Create non-root user
RUN useradd --create-home --shell /bin/bash mluser

WORKDIR /app

# Copy Python packages from dependencies stage
COPY --from=dependencies /root/.local /home/mluser/.local

# Copy application files
COPY app.py .
COPY requirements.txt .

# Copy trained models (either from CI artifacts or trainer stage)
COPY --from=trainer /app/*.pkl ./ 2>/dev/null || COPY *.pkl ./

# Set proper ownership
RUN chown -R mluser:mluser /app
USER mluser

# Update PATH for user-installed packages
ENV PATH=/home/mluser/.local/bin:$PATH

# Health check with improved reliability
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:7860', timeout=5)" || exit 1

EXPOSE 7860

CMD ["python", "app.py"]
