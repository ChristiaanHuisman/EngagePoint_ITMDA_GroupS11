# Use official lightweight Python image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy everything into /app
COPY . .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Add /app to the PYTHONPATH so imports work
ENV PYTHONPATH="/app"

# Expose port
EXPOSE 8080

# Run Flask app
CMD ["python", "app/main.py"]
