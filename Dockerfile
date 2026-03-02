# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set the working directory to /app
WORKDIR /app

# Copy the backend requirements first for caching
COPY backend/requirements.txt .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the backend source code
COPY backend/ .

# Set environment variable to ensure logs are visible
ENV PYTHONUNBUFFERED=1

# Expose the port (Railway provides this via environment variable)
EXPOSE 8000

# Run uvicorn when the container launches
# We use sh -c to allow the $PORT variable to be evaluated at runtime
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
