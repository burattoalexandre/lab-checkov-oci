# Checkov no Terraform da OCI

Código do laboratório usado no artigo **"Checkov: encontrando falhas de segurança no Terraform antes do apply na OCI"**.

O objetivo é mostrar como o [Checkov](https://www.checkov.io/) analisa um código Terraform de OCI **antes do `apply`**, o que ele encontra com as regras prontas, o que ele não encontra e como cobrir essa lacuna com uma política própria.

> ⚠️ Código para estudo. A pasta `antes/` contém erros de segurança **de propósito**. Não aplique esse código em um ambiente real.

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `antes/` | Laboratório de SBC na OCI com erros comuns: SSH e SIP (UDP 5060) abertos para 0.0.0.0/0, bucket de pcaps público e instância sem criptografia em trânsito e com IMDSv1 ativo |
| `depois/` | O mesmo código corrigido, com uma exceção justificada (`#checkov:skip`) |
| `policies/` | Política própria em YAML (`CKV2_VOIP_1`) que barra o SIP aberto para a internet |

Os valores de compartment, AD, subnet, imagem, namespace e chave do Vault são apenas variáveis — não há credenciais nem OCIDs no código.

## Como rodar

```bash
pip install checkov

# Versão com erros: 6 aprovadas, 9 falhas (inclui a política própria)
checkov -d antes --framework terraform --external-checks-dir policies --compact

# Versão corrigida: 14 aprovadas, 0 falhas, 1 exceção justificada
checkov -d depois --framework terraform --external-checks-dir policies --compact
```

Resultados obtidos com o Checkov 3.4.5. Outras versões podem ter regras diferentes.

## Usando como portão antes do apply

O Checkov termina com código de saída `1` quando há falhas e `0` quando está tudo certo:

```bash
terraform plan -out tf.plan
terraform show -json tf.plan > plan.json
checkov -f plan.json --external-checks-dir policies && terraform apply tf.plan
```

## Autor

Alexandre Buratto — [LinkedIn](https://www.linkedin.com/in/alexandre-buratto-mba-52340b4)
