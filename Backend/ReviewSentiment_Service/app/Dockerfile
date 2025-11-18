# Use a lightweight Python image
FROM python:3.11-slim

# Set working directory inside the container
WORKDIR /app

# Copy dependency file and install packages
COPY requirements.txt .
RUN python -m pip install --upgrade pip
RUN pip install --default-timeout=1000 --no-cache-dir -r requirements.txt


# Copy all application files into the container
COPY . .

# Download NLTK vader_lexicon to a location accessible by the app
RUN python -m nltk.downloader -d /usr/local/share/nltk_data vader_lexicon
ENV NLTK_DATA=/usr/local/share/nltk_data

# Expose the port Cloud Run expects
EXPOSE 8080

# Start the Flask app using Gunicorn
CMD ["gunicorn", "-b", "0.0.0.0:8080", "main:app"]
