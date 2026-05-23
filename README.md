# Infraestrutura AWS com Databricks via Terraform

Uma infraestrutura declarativa, construída com Terraform, para provisionar os recursos AWS e Databricks necessários ao projeto. O repositório está organizado por ambientes em `terraform/env/` (ex.: `dev`, `prod`) e por módulos reutilizáveis em `terraform/modules/` (cada módulo encapsula um recurso ou conjunto relacionado).

![Diagrama da infraestrutura (PNG fallback)](docs/infra_databricks.png)

## Descrição

Este projeto provisiona a infraestrutura necessária para executar workloads Databricks na AWS, incluindo:

- Rede (VPC, subnets públicas/privadas, gateways)
- Segurança (Security Groups, IAM roles e políticas cross-account para Databricks)
- Armazenamento (S3 buckets para metastore, staging e logs)
- Databricks (workspaces, integração com Unity Catalog / metastore e gestão de usuários/grupos)

Os módulos ficam em `terraform/modules/` e um ambiente de exemplo (`dev`) está em `terraform/env/dev/`.

## Arquitetura (recursos principais)

- AWS VPC: VPC com subnets públicas e privadas, roteamento e NAT (opção multi-AZ).
	- Por que: isola a rede do projeto, separa tráfego público e privado e garante que clusters e serviços tenham conectividade controlada e alta disponibilidade.

- Security Groups: regras de firewall a nível de instância/serviço.
	- Por que: controlam acesso de rede entre clusters, serviços e endpoints, reduzindo a superfície de ataque e permitindo políticas de segurança mínimas necessárias.

- IAM: roles e políticas para permitir que o Databricks acesse buckets S3 e gerencie recursos (inclui roles cross-account quando necessário).
	- Por que: concedem permissões granulares para que o Databricks e o código de provisionamento realizem ações necessárias (acesso a S3, passar roles, criar recursos) sem usar credenciais amplas.

- S3: buckets para metastore Unity Catalog, staging, logs e artefatos.
	- Por que: armazenamento durável e escalável para dados do metastore, arquivos de staging de jobs, artefatos de implantação e logs de auditoria; também usado como backend remoto do Terraform quando configurado.

- Databricks Workspace: provisionamento/integração do workspace com recursos AWS.
	- Por que: ambiente onde usuários e clusters executam workloads; a integração com AWS (VPC, roles, S3) é necessária para operação segura e eficiente.

- Unity Catalog / Metastore: criação/configuração do metastore e ligação com buckets S3 e roles.
	- Por que: fornece governança de dados centralizada, catálogo unificado de tabelas e controle de acesso; é essencial para organização de dados e compliance.

	**ATENÇÃO:** o metastore (Unity Catalog) pode ser provisionado automaticamente pelo Databricks ou gerenciado via APIs específicas. Evite criar o metastore manualmente no Console se o Terraform ou módulos deste repositório forem responsáveis por provisioná-lo — criar manualmente pode causar conflitos. Verifique a configuração do módulo `databricks_metastore` antes de criar recursos manualmente.

- Databricks Users & Groups: criação e associação de usuários e grupos (por e-mail).
	- Por que: permite gestão centralizada de identidades e permissões dentro do workspace, simplificando onboarding e auditoria.

## Pré-requisitos

- Terraform CLI (recomendado 1.5+; versões dos providers estão nos arquivos `versions.tf` dos módulos)
- AWS CLI configurada (credenciais com permissões para criar IAM, S3, VPC, etc.)
- Acesso ao Databricks Account / Workspace e credenciais necessárias (ex: Account ID, client ID/secret ou PAT), dependendo da configuração
- PowerShell (exemplos abaixo usam PowerShell no Windows)
- Recomenda-se habilitar o bloqueio de estado remoto (S3 + DynamoDB) antes de usar em times

## Validar antes de aplicar

Antes de executar `terraform apply` confirme rapidamente:

- Credenciais AWS: `aws sts get-caller-identity` deve retornar seu principal esperado.
- Backend/state: se usar backend remoto, verifique que o bucket S3 existe e a tabela DynamoDB para lock está criada.
- Permissões IAM: role/usuário que executa o Terraform deve ter permissões para criar os recursos listados (IAM, EC2, S3, DynamoDB).
- Variáveis: `terraform.tfvars` está preenchido e não contém secrets versionados.

Comandos úteis:

```powershell
aws sts get-caller-identity
terraform -chdir="terraform/env/dev" init
terraform -chdir="terraform/env/dev" plan -var-file=terraform.tfvars
```

## Guia prático — pré-configuração (resumido)

Siga estes passos mínimos antes de rodar o Terraform (objetivo: preparar credenciais e state). Se já tem tudo pronto, pule para a seção "Como executar".

1) AWS: credenciais e região
- Instale e configure o AWS CLI:

```powershell
aws configure
```

2) State remoto (opcional, recomendado para times)
- Crie um bucket S3 e uma tabela DynamoDB para locking se for usar backend remoto. (Guia: https://developer.hashicorp.com/terraform/language/backend/s3)

3) Databricks: Fluxo de Assinatura e Estratégia de Laboratório

Como este é um ambiente de laboratório focado nos estudos, é preciso uma abordagem de ativação oficial integrada à AWS, mas com o cuidado de manter o controle total do ciclo de vida dos recursos via código.

* **Caminho de Configuração:** A ativação da conta é realizada via **AWS Marketplace**, assinando o produto oficial do Databricks. Esse caminho é o padrão de mercado para unificar o faturamento (*billing*) diretamente na conta da AWS.

* **Ações de Preparação:** O fluxo de aquisição é iniciado no Marketplace para criar o vínculo entre as contas. Nessa etapa, coletam-se o **Account ID** do Databricks e as credenciais de autenticação necessárias para o provedor do Terraform (`client_id`/`client_secret` ou *Personal Access Token* - PAT).

> [!NOTE]
> 🔬 **Por que o fluxo é interrompido manualmente?**
> O assistente automático do Marketplace é **interrompido intencionalmente** antes da criação automática dos Workspaces ou do Metastore padrão. Essa decisão de arquitetura é tomada porque o objetivo do laboratório é aprender a provisionar **toda a infraestrutura de forma 100% declarativa**. Interromper esse fluxo automatizado obriga ao gerenciamento e entendimento do nascimento de cada recurso (redes, segurança e storage) através dos próprios scripts do Terraform.

* **Nota sobre Créditos de Estudo:** Para fins de aprendizado, vale destacar que algumas ofertas do Databricks no AWS Marketplace oferecem créditos promocionais de avaliação (*Free Trial*). É uma excelente oportunidade encontrada para testar recursos avançados sem custo inicial (recomenda-se sempre verificar os termos vigentes na página do produto).

4) Preencher variáveis locais
- Copie o exemplo e edite localmente (NÃO versionar):

```powershell
Copy-Item .\terraform\env\dev\terraform.tfvars.example .\terraform\env\dev\terraform.tfvars
# editar .\terraform\env\dev\terraform.tfvars
```

Pronto — agora siga a seção "Como executar" para init/plan/apply.

## Links de referência

- AWS (início): https://aws.amazon.com/pt/
- AWS CLI: https://docs.aws.amazon.com/pt_br/cli/latest/userguide/getting-started-install.html
- Terraform S3 backend (S3): https://developer.hashicorp.com/terraform/language/backend/s3
- Databricks Account Console / APIs: https://docs.databricks.com/aws/en/admin/account-settings/
- Databricks Unity Catalog (criar metastore): https://docs.databricks.com/aws/en/data-governance/unity-catalog/create-metastore
- Databricks API auth (PATs / tokens): https://docs.databricks.com/aws/en/dev-tools/auth/

## Contribuição

As variáveis abaixo foram extraídas dos arquivos `variables.tf` presentes no ambiente `dev` e nos módulos. Elas representam as entradas principais que você verá ao usar este projeto.

| Variável | Tipo | Descrição |
|---|---:|---|
| `aws_region` | string | Região AWS onde os recursos serão criados |
| `profile_name` | string | Perfil AWS a ser usado (opcional, se aplicar) |
| `bucket_name` | string | Nome do bucket S3 a ser criado/usado |
| `databricks_account_id` | string | ID da conta Databricks (Account ID) |
| `client_id` | string | Client ID para API/integração com Databricks |
| `client_secret` | string | client_secret para Databricks (não versionar)
| `email_admin` | string | E-mail do usuário administrador do Databricks |
| `group_members` | map(list(string)) | Mapeamento de grupos → lista de e-mails dos membros |
| `cidr_block` | string | CIDR da VPC |
| `public_subnet_cidr_1` | string | CIDR da primeira subnet pública |
| `public_subnet_cidr_2` | string | CIDR da segunda subnet pública |
| `private_subnet_cidr_1` | string | CIDR da primeira subnet privada |
| `private_subnet_cidr_2` | string | CIDR da segunda subnet privada |
| `tags` | map(string) | Tags padrão aplicadas aos recursos |
| `environment` | string | Ambiente (ex: `dev`, `staging`, `prod`) |
| `cross_account_role_arn` | string | ARN da IAM Role criada para Databricks (cross-account) |
| `vpc_id` | string | ID da VPC (quando passado de um módulo para outro) |
| `subnet_ids` | list(string) | Lista de subnets privadas para clusters Databricks |
| `security_group_id` | string | ID do Security Group padrão para a VPC |

Observação: nem todas as variáveis são obrigatórias para cada módulo; verifique `terraform/env/dev/terraform.tfvars` para valores usados no ambiente de desenvolvimento.

## Como executar (PowerShell)

Abra o PowerShell a partir do diretório do repositório (ex: `c:\path\sub_path\databricks`) e siga os passos abaixo. Estes comandos assumem que você trabalha no ambiente `dev` em `terraform/env/dev`.

```powershell
# Inicializar Terraform
terraform -chdir="terraform/env/dev" init --upgrade

# Validar sintaxe e referências
terraform -chdir="terraform/env/dev" validate

# (Opcional) Formatar código
terraform -chdir="terraform" fmt -recursive

# Gerar um plano e salvar em arquivo
terraform -chdir="terraform/env/dev" plan -var-file="terraform.tfvars" -out="main.tfplan"

# Aplicar o plano salvo (recomendado) ou aplicar direto
terraform -chdir="terraform/env/dev" apply -auto-approve "main.tfplan"
```

## Limpeza (remover infraestrutura)

Para destruir os recursos criados por este ambiente (tenha cuidado — essa ação remove recursos):

```powershell
terraform -chdir="terraform/env/dev" destroy -var-file="terraform.tfvars"
```

Se você utilizou um backend remoto para o estado, verifique e remova quaisquer artefatos remanescentes (por exemplo, objetos S3 ou entradas DynamoDB para lock) conforme apropriado.

## Boas práticas e observações

- Nunca versionar credenciais (client_secret, tokens, etc.). Use variáveis de ambiente, cofres/secrets managers ou um vault.
- Considere habilitar um backend remoto (S3 + DynamoDB) para colaboração e locking do estado.
- Mantenha o módulo `versions.tf` atualizado para fixar versões de providers e evitar quebras inesperadas.
- Teste alterações de infraestrutura em `dev` antes de promover para `prod`.

## Arquivos relevantes

- `terraform/env/dev/` — configurações e estado local do ambiente de desenvolvimento
- `terraform/modules/` — módulos reutilizáveis (VPC, S3, IAM, Databricks, etc.)
