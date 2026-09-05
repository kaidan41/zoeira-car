#!/usr/bin/env python3
"""
Script para criar produtos IAP (In-App Purchase) no Google Play Console via API.

Produtos criados:
1. zoeira_car_mensal - Assinatura mensal com 7 dias de trial
2. zoeira_consulta - Consulta avulsa (consumível)

Uso:
    python3 create_iap_products.py

Variáveis de ambiente:
    PLAY_STORE_SERVICE_ACCOUNT_JSON - JSON da conta de serviço (base64 ou caminho)
    PACKAGE_NAME - Package name do app (ex: com.zoeiracartv.app)
    CREATE_SUBSCRIPTION - Se deve criar assinatura (default: true)
    CREATE_CONSULTATION - Se deve criar consulta (default: true)
"""

import json
import os
import sys
import base64
from pathlib import Path
from typing import Optional, Dict, Any

try:
    from google.auth.transport.requests import Request
    from google.oauth2.service_account import Credentials
    from googleapiclient.discovery import build
except ImportError as e:
    print(f"❌ Erro: Dependências não instaladas: {e}")
    sys.exit(1)


class PlayStoreAPIClient:
    """Cliente para a Play Store Billing API."""

    SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]

    def __init__(self, service_account_json: str, package_name: str):
        """
        Inicializa o cliente.

        Args:
            service_account_json: Conteúdo do JSON (ou path se for arquivo)
            package_name: Package name do app
        """
        self.package_name = package_name
        self.credentials = self._load_credentials(service_account_json)
        self.service = build(
            "androidpublisher",
            "v3",
            credentials=self.credentials,
            cache_discovery=False,
        )

    def _load_credentials(self, service_account_json: str) -> Credentials:
        """Carrega credenciais da conta de serviço."""
        # Tenta interpretar como base64 (do GitHub Secrets)
        try:
            decoded = base64.b64decode(service_account_json)
            data = json.loads(decoded)
            return Credentials.from_service_account_info(data, scopes=self.SCOPES)
        except Exception:
            pass

        # Tenta carregar como arquivo (para testes locais)
        if Path(service_account_json).exists():
            with open(service_account_json) as f:
                data = json.load(f)
            return Credentials.from_service_account_info(data, scopes=self.SCOPES)

        raise ValueError(
            "Não foi possível carregar as credenciais. "
            "Verifique PLAY_STORE_SERVICE_ACCOUNT_JSON."
        )

    def create_subscription(self) -> bool:
        """Cria o produto de assinatura mensal."""
        product_id = "zoeira_car_mensal"
        product_data = {
            "packageName": self.package_name,
            "sku": product_id,
            "listings": {
                "pt-BR": {
                    "title": "Puxe agora a Capivara da Sua Nave",
                    "description": "Destrave o raio-x completo de qualquer nave!",
                }
            },
            "subscriptionPeriod": "P1M",  # Period = 1 Month
            "trialPeriod": "P7D",  # Trial = 7 Days
            "defaultPrice": {
                "priceMicros": 14990000,  # R$ 14,99 em micros
                "currency": "BRL",
            },
            "status": "active",
        }

        try:
            print(f"📝 Criando assinatura: {product_id}...")
            request = self.service.inappproducts().insert(
                packageName=self.package_name, body=product_data
            )
            response = request.execute()
            print(f"✅ Assinatura criada: {response.get('sku')}")
            return True
        except Exception as e:
            # 400 = já existe, é ok
            if hasattr(e, "resp") and e.resp.status == 400:
                print(f"⚠️  Assinatura já existe: {product_id}")
                return True
            print(f"❌ Erro ao criar assinatura: {e}")
            return False

    def create_consultation(self) -> bool:
        """Cria o produto de consulta avulsa (consumível)."""
        product_id = "zoeira_consulta"
        product_data = {
            "packageName": self.package_name,
            "sku": product_id,
            "listings": {
                "pt-BR": {
                    "title": "Consulta Avulsa de 1 Nave",
                    "description": "Desbloqueia o raio-x completo de 1 veículo para sempre.",
                }
            },
            "defaultPrice": {
                "priceMicros": 7900000,  # R$ 7,90 em micros
                "currency": "BRL",
            },
            "purchaseType": "managedUser",  # Consumível
            "status": "active",
        }

        try:
            print(f"📝 Criando consulta avulsa: {product_id}...")
            request = self.service.inappproducts().insert(
                packageName=self.package_name, body=product_data
            )
            response = request.execute()
            print(f"✅ Consulta criada: {response.get('sku')}")
            return True
        except Exception as e:
            # 400 = já existe, é ok
            if hasattr(e, "resp") and e.resp.status == 400:
                print(f"⚠️  Consulta já existe: {product_id}")
                return True
            print(f"❌ Erro ao criar consulta: {e}")
            return False

    def list_products(self) -> Dict[str, Any]:
        """Lista todos os produtos do app."""
        try:
            print("\n🔍 Listando produtos IAP...")
            request = self.service.inappproducts().list(
                packageName=self.package_name
            )
            response = request.execute()
            products = response.get("inappproduct", [])
            print(f"✅ Encontrados {len(products)} produtos:")
            for p in products:
                print(f"  • {p['sku']} - {p['status']}")
            return response
        except Exception as e:
            print(f"❌ Erro ao listar produtos: {e}")
            return {}


def main():
    """Função principal."""
    # Carrega variáveis de ambiente
    service_account_json = os.getenv("PLAY_STORE_SERVICE_ACCOUNT_JSON")
    package_name = os.getenv("PACKAGE_NAME", "com.zoeiracartv.app")
    create_subscription = (
        os.getenv("CREATE_SUBSCRIPTION", "true").lower() == "true"
    )
    create_consultation = (
        os.getenv("CREATE_CONSULTATION", "true").lower() == "true"
    )

    if not service_account_json:
        print(
            "❌ Erro: PLAY_STORE_SERVICE_ACCOUNT_JSON não está definido."
        )
        sys.exit(1)

    print("=" * 60)
    print("🚀 Setup de Produtos IAP - Zoeira Car")
    print("=" * 60)
    print(f"Package: {package_name}")
    print()

    try:
        client = PlayStoreAPIClient(service_account_json, package_name)

        if create_subscription:
            success_sub = client.create_subscription()
        else:
            success_sub = True
            print("⏭️  Pulando criação de assinatura (desabilitada)")

        if create_consultation:
            success_cons = client.create_consultation()
        else:
            success_cons = True
            print("⏭️  Pulando criação de consulta (desabilitada)")

        # Lista produtos para confirmar
        client.list_products()

        print()
        if success_sub and success_cons:
            print(
                "✅ Produtos IAP configurados com sucesso!"
            )
            print(
                "⏰ Aguarde 2-4 horas para os produtos ficarem "
                "disponíveis para teste no app."
            )
            return 0
        else:
            print("⚠️  Alguns produtos falharam. Verifique os logs acima.")
            return 1

    except Exception as e:
        print(f"❌ Erro fatal: {e}")
        import traceback

        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
