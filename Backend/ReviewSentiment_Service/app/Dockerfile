# Use a lightweight Python image
FROM python:3.11-slim

# Set working directory inside the container
WORKDIR /app

# Copy the dependency file and install packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all the app files into the container
COPY . .

# Download nltk data required for sentiment analysis
RUN python -m nltk.downloader vader_lexicon

# Expose the port that Cloud Run will use
EXPOSE 8080

# Start the Flask app using Gunicorn
CMD ["gunicorn", "-b", "0.0.0.0:8080", "main:app"]