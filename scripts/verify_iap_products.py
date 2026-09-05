#!/usr/bin/env python3
"""
Script para verificar e listar os produtos IAP criados no Play Console.

Uso:
    python3 verify_iap_products.py

Variáveis de ambiente:
    PLAY_STORE_SERVICE_ACCOUNT_JSON - JSON da conta de serviço
    PACKAGE_NAME - Package name do app
"""

import json
import os
import sys
import base64
from pathlib import Path

try:
    from google.oauth2.service_account import Credentials
    from googleapiclient.discovery import build
except ImportError as e:
    print(f"❌ Erro: Dependências não instaladas: {e}")
    sys.exit(1)


class PlayStoreVerifier:
    """Verifica status dos produtos IAP."""

    SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]

    def __init__(self, service_account_json: str, package_name: str):
        self.package_name = package_name
        self.credentials = self._load_credentials(service_account_json)
        self.service = build(
            "androidpublisher",
            "v3",
            credentials=self.credentials,
            cache_discovery=False,
        )

    def _load_credentials(self, service_account_json: str) -> Credentials:
        try:
            decoded = base64.b64decode(service_account_json)
            data = json.loads(decoded)
            return Credentials.from_service_account_info(data, scopes=self.SCOPES)
        except Exception:
            pass

        if Path(service_account_json).exists():
            with open(service_account_json) as f:
                data = json.load(f)
            return Credentials.from_service_account_info(data, scopes=self.SCOPES)

        raise ValueError(
            "Não foi possível carregar as credenciais. "
            "Verifique PLAY_STORE_SERVICE_ACCOUNT_JSON."
        )

    def verify(self) -> bool:
        """Verifica se os produtos esperados existem."""
        expected_products = {
            "zoeira_car_mensal": "Assinatura",
            "zoeira_consulta": "Consulta Avulsa",
        }

        try:
            print("\n" + "=" * 60)
            print("🔍 Verificando Produtos IAP")
            print("=" * 60)

            request = self.service.inappproducts().list(
                packageName=self.package_name
            )
            response = request.execute()
            products = {p["sku"]: p for p in response.get("inappproduct", [])}

            all_ok = True
            for sku, label in expected_products.items():
                if sku in products:
                    p = products[sku]
                    status = p.get("status", "unknown")
                    price = p.get("defaultPrice", {})
                    print(f"\n✅ {label} ({sku})")
                    print(f"   Status: {status}")
                    print(f"   Preço: {price.get('currency')} {price.get('priceMicros', 0) / 1_000_000:.2f}")
                    if "subscriptionPeriod" in p:
                        print(f"   Período: {p['subscriptionPeriod']}")
                    if "trialPeriod" in p:
                        print(f"   Trial: {p['trialPeriod']}")
                else:
                    print(f"\n❌ {label} ({sku}) - NÃO ENCONTRADO")
                    all_ok = False

            print("\n" + "=" * 60)
            if all_ok:
                print("✅ Todos os produtos estão configurados!")
                print("⏰ Aguarde 2-4 horas para ficarem disponíveis para teste.")
            else:
                print("⚠️  Alguns produtos estão faltando.")
            print("=" * 60 + "\n")

            return all_ok

        except Exception as e:
            print(f"❌ Erro ao verificar: {e}")
            import traceback
            traceback.print_exc()
            return False


def main():
    service_account_json = os.getenv("PLAY_STORE_SERVICE_ACCOUNT_JSON")
    package_name = os.getenv("PACKAGE_NAME", "com.zoeiracartv.app")

    if not service_account_json:
        print("❌ Erro: PLAY_STORE_SERVICE_ACCOUNT_JSON não está definido.")
        return 1

    verifier = PlayStoreVerifier(service_account_json, package_name)
    return 0 if verifier.verify() else 1


if __name__ == "__main__":
    sys.exit(main())
