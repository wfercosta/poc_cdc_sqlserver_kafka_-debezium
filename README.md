import json
import base64
import requests

def lambda_handler(event, context):
    # URL do servidor de destino
    destination_url = "https://httpbin.org"  # Substitua pelo seu servidor de destino

    # Extraia os detalhes da requisição
    path = event["path"]
    method = event["httpMethod"]
    headers = event.get("headers", {})
    query_string = event.get("queryStringParameters", {})
    body = event.get("body", None)
    is_base64_encoded = event.get("isBase64Encoded", False)

    # Se o corpo for codificado em base64, decodifique
    if is_base64_encoded and body:
        body = base64.b64decode(body)

    # Construir a URL final com os parâmetros de consulta
    final_url = destination_url + path
    if query_string:
        query_params = "&".join(f"{k}={v}" for k, v in query_string.items())
        final_url += f"?{query_params}"

    try:
        # Repassar a requisição para o servidor de destino
        response = requests.request(
            method=method,
            url=final_url,
            headers=headers,
            data=body,
            allow_redirects=True
        )

        # Prepare a resposta
        response_headers = {
            k: v for k, v in response.headers.items() if k.lower() != "transfer-encoding"
        }

        # Verificar o tipo de conteúdo retornado
        if "content-type" in response.headers and "text" not in response.headers["content-type"]:
            # Para conteúdos binários, encode em base64
            return {
                "statusCode": response.status_code,
                "headers": response_headers,
                "isBase64Encoded": True,
                "body": base64.b64encode(response.content).decode("utf-8"),
            }
        else:
            # Para conteúdos de texto, retorne diretamente
            return {
                "statusCode": response.status_code,
                "headers": response_headers,
                "body": response.text,
            }

    except Exception as e:
        # Caso ocorra um erro, retorne informações úteis
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)}),
        }

