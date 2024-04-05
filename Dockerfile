FROM python:3.11.8-alpine

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY . .

CMD ["python", "gitleaks_config_generator.py"]
