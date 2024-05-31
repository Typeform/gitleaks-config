FROM python:3.12.2-alpine

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY . .

CMD ["python", "gitleaks_config_generator.py"]
