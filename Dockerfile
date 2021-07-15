FROM python:3.7-alpine3.12

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY . .

CMD ["python" "gitleaks_config_generator.py"]
