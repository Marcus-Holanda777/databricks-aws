
# Infraestrutura AWS com Databricks via Terraform

Uma infraestrutura declarativa em Terraform para provisionar recursos AWS e Databricks usados pelo projeto. O repositório está organizado com configurações por ambiente em `terraform/env/` e módulos reutilizáveis em `terraform/modules/`.

## Descrição

Este projeto provisiona a infraestrutura necessária para executar workloads Databricks na AWS, incluindo:

- Rede (VPC, subnets públicas/privadas, gateways)
- Segurança (Security Groups, IAM roles e políticas cross-account para Databricks)
- Armazenamento (S3 buckets para metastore, staging e logs)
- Databricks (workspaces, integração com Unity Catalog / metastore e gestão de usuários/grupos)

Os módulos ficam em `terraform/modules/` e um ambiente de exemplo (`dev`) está em `terraform/env/dev/`.

## Arquitetura (recursos principais)

- AWS VPC: VPC com subnets públicas e privadas, roteamento, NAT (opção multi-AZ)
- Security Groups: regras de rede para clusters e serviços
- IAM: roles e políticas para permitir que o Databricks acesse buckets S3 e gerencie recursos (cross-account role)
- S3: buckets para metastore Unity Catalog, staging e outros artefatos
- Databricks Workspace: provisionamento/integração com recursos AWS
- Unity Catalog / Metastore: criação/configuração de metastore e link com S3 e roles
  
	**ATENÇÃO:** O metastore (Unity Catalog) pode ser criado automaticamente pelo Databricks ou gerenciado via APIs específicas. Evite criar manualmente o metastore no Console se o Terraform ou módulos deste repositório forem responsáveis por provisioná-lo — criar manualmente pode causar conflitos. Verifique a configuração do módulo `databricks_metastore` antes de criar recursos manualmente.
- Databricks Users & Groups: criação e associação de usuários e grupos (por e-mail)

## Pré-requisitos

- Terraform CLI (recomendado 1.5+; versões dos providers estão nos arquivos `versions.tf` dos módulos)
- AWS CLI configurada (credenciais com permissões para criar IAM, S3, VPC, etc.)
- Acesso ao Databricks Account / Workspace e credenciais necessárias (ex: Account ID, client ID/secret ou PAT), dependendo da configuração
- PowerShell (exemplos abaixo usam PowerShell no Windows)
- Recomenda-se habilitar o bloqueio de estado remoto (S3 + DynamoDB) antes de usar em times

## Guia prático — pré-configuração (didático)

Esta seção é um passo a passo pensado para ensinar alguém a preparar os pré-requisitos antes de rodar o Terraform. Inclui links oficiais e comandos básicos. O objetivo é habilitar as contas e ferramentas — NÃO provisionar recursos que o Terraform deverá criar.

1. Criar uma conta AWS
	- Acesse a página da AWS e crie uma conta (se ainda não tiver): https://aws.amazon.com/pt/
	- Documentação / guia de início: https://aws.amazon.com/pt/getting-started/
	- Recomendações: configure MFA no usuário root e crie um usuário IAM administrativo separado para uso diário.

2. Configurar o AWS CLI
	- Instale o AWS CLI (documentação): https://docs.aws.amazon.com/pt_br/cli/latest/userguide/getting-started-install.html
	- Configure o CLI localmente com credenciais de um usuário IAM com permissões adequadas:

```powershell
aws configure
# informe AWS Access Key ID, AWS Secret Access Key, região (ex: us-east-1) e formato (json)
```

	- Guia rápido de configuração: https://docs.aws.amazon.com/pt_br/cli/latest/userguide/cli-configure-quickstart.html

3. (Opcional, recomendado) Criar um bucket S3 para estado remoto
	- Se planeja usar backend remoto (recomendado para times), crie um bucket S3 e uma tabela DynamoDB para lock.
	- Tutorial S3 + DynamoDB backend: https://learn.hashicorp.com/tutorials/terraform/s3-backend

4. Habilitar conta Databricks sem criar workspaces manualmente
	- Se ainda não tiver conta Databricks, crie acesso em: https://www.databricks.com/ (ou peça à equipe responsável).
	- Documentação do Account Console (Account API / Account Console): https://docs.databricks.com/administration-guide/account-console/index.html
	- Obtenha o Account ID (necessário para integrações) no Account Console — copie o Account ID e mantenha em segurança.
	- Gere credenciais necessárias para a integração:
	  - Para operações na API em nível de conta, você pode criar um client ID / client secret (service principal) via Account Console / API.
	  - Para o provider do workspace (quando aplicável), gere um Personal Access Token (PAT) no próprio workspace.
	- Importante: não crie workspaces manualmente no Console se o Terraform for responsável pelo provisionamento — apenas habilite a conta e gere as credenciais necessárias.
	- ATENÇÃO SOBRE METASTORE: o Unity Catalog / metastore pode ser provisionado automaticamente pelo Databricks ou pelo módulo `databricks_metastore`. NÃO crie o metastore manualmente no Console se pretende que o Terraform gerencie o metastore; isso pode causar inconsistências e conflitos na configuração do Unity Catalog.

	- DECISÃO DO PROJETO: optou-se por NÃO criar o metastore via Terraform. O metastore será provisionado automaticamente quando o Databricks Workspace for criado. Se já existir um metastore, importe-o ou referencie-o no Terraform em vez de criar outro.


**Recomendação e link oficial**

Se você precisar criar o metastore manualmente (por exemplo, por decisões organizacionais), siga a documentação oficial do Databricks: https://docs.databricks.com/aws/pt/data-governance/unity-catalog/create-metastore

- Recomendação geral: Se este repositório / módulo `databricks_metastore` for responsável pelo metastore, deixe que o Terraform faça o provisioning para evitar conflitos.
- Caso já exista um metastore creado manualmente ou por outro time, importe ou referencie esse metastore no Terraform em vez de criar um novo (posso ajudar com comandos de import). 

	- Guia para gerar tokens e autenticação: https://docs.databricks.com/dev-tools/api/latest/authentication.html#generate-a-personal-access-token

5. Preencher `terraform.tfvars`
	- Copie o arquivo de exemplo e edite localmente (não versionar):

```powershell
Copy-Item .\terraform\env\dev\terraform.tfvars.example .\terraform\env\dev\terraform.tfvars
# edite .\terraform\env\dev\terraform.tfvars e substitua placeholders por valores reais
```

6. Executar os comandos do Terraform (veja seção "Como executar")

Se precisar de ajuda para criar políticas IAM mínimas (privilégios necessários) para o Terraform executar as ações, a seguir há um exemplo de policy JSON mínima. Ajuste os ARNs, regiões e contas conforme seu ambiente e restrinja ao máximo possível antes de aplicar em produção.

### Exemplo de IAM Policy mínima (JSON)

Observações antes de usar:
- Substitua `REPLACE_ACCOUNT_ID`, `REPLACE_REGION`, `REPLACE_S3_BUCKET` e `REPLACE_DDB_TABLE_ARN` pelos valores do seu ambiente.
- Preferível criar uma role específica e anexar esta policy a ela, em vez de usar credenciais de usuário root.
- Revise e reduza permissões a recursos/ARNs específicos sempre que possível.

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "S3StateBucket",
			"Effect": "Allow",
			"Action": [
				"s3:CreateBucket",
				"s3:ListBucket",
				"s3:GetBucketLocation",
				"s3:PutObject",
				"s3:GetObject",
				"s3:DeleteObject"
			],
			"Resource": [
				"arn:aws:s3:::REPLACE_S3_BUCKET",
				"arn:aws:s3:::REPLACE_S3_BUCKET/*"
			]
		},
		{
			"Sid": "DynamoDBLock",
			"Effect": "Allow",
			"Action": [
				"dynamodb:GetItem",
				"dynamodb:PutItem",
				"dynamodb:DeleteItem",
				"dynamodb:UpdateItem",
				"dynamodb:Query",
				"dynamodb:Scan"
			],
			"Resource": "REPLACE_DDB_TABLE_ARN"
		},
		{
			"Sid": "EC2NetworkPermissions",
			"Effect": "Allow",
			"Action": [
				"ec2:Describe*",
				"ec2:CreateVpc",
				"ec2:DeleteVpc",
				"ec2:CreateSubnet",
				"ec2:DeleteSubnet",
				"ec2:CreateInternetGateway",
				"ec2:AttachInternetGateway",
				"ec2:CreateRouteTable",
				"ec2:CreateRoute",
				"ec2:AssociateRouteTable",
				"ec2:AllocateAddress",
				"ec2:CreateNatGateway",
				"ec2:CreateSecurityGroup",
				"ec2:DeleteSecurityGroup",
				"ec2:AuthorizeSecurityGroupIngress",
				"ec2:AuthorizeSecurityGroupEgress",
				"ec2:CreateTags"
			],
			"Resource": "*"
		},
		{
			"Sid": "IAMPermissions",
			"Effect": "Allow",
			"Action": [
				"iam:CreateRole",
				"iam:DeleteRole",
				"iam:GetRole",
				"iam:PassRole",
				"iam:AttachRolePolicy",
				"iam:PutRolePolicy",
				"iam:CreatePolicy",
				"iam:DeletePolicy",
				"iam:GetRolePolicy"
			],
			"Resource": "arn:aws:iam::REPLACE_ACCOUNT_ID:role/*"
		},
		{
			"Sid": "Logs",
			"Effect": "Allow",
			"Action": [
				"logs:CreateLogGroup",
				"logs:CreateLogStream",
				"logs:PutLogEvents"
			],
			"Resource": "*"
		}
	]
}
```

Como aplicar essa policy

1. Salve o JSON acima em um arquivo local (ex: `terraform-iam-policy.json`).
2. Crie uma role no AWS IAM para uso pelo Terraform (ou anexe a um usuário/role existente):

```powershell
# Exemplo via AWS CLI (substitua NOME_DA_ROLE e o arquivo de trust policy se necessário)
aws iam create-role --role-name NOME_DA_ROLE --assume-role-policy-document file://trust-policy.json
aws iam put-role-policy --role-name NOME_DA_ROLE --policy-name TerraformMinimalPolicy --policy-document file://terraform-iam-policy.json
```

3. Se usar um usuário/role para executar o Terraform localmente, configure as credenciais AWS para esse principal.

Se quiser, gero também a `trust-policy.json` mínima e uma versão da policy com ARNs já preenchidos com valores do seu ambiente.

## Variáveis principais

As variáveis abaixo foram extraídas dos arquivos `variables.tf` presentes no ambiente `dev` e nos módulos. Elas representam as entradas principais que você verá ao usar este projeto.

| Variável | Tipo | Descrição |
|---|---:|---|
| `aws_region` | string | Região AWS onde os recursos serão criados |
| `profile_name` | string | Perfil AWS a ser usado (opcional, se aplicar) |
| `bucket_name` | string | Nome do bucket S3 a ser criado/usuado |
| `databricks_account_id` | string | ID da conta Databricks (Account ID) |
| `client_id` | string | Client ID para API/integração com Databricks |
| `client_secret` | string | Client secret para Databricks (não commitar) |
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

Abra o PowerShell a partir do diretório do repositório (ex: `c:\pre_projetos\start_job\databricks`) e siga os passos abaixo. Estes comandos assumem que você trabalha no ambiente `dev` em `terraform/env/dev`.

```powershell
# Alternativa 1 (recomendado se você quer permanecer em outro diretório):
# use a flag -chdir para apontar o diretório do ambiente

# Inicializar Terraform
terraform -chdir="terraform/env/dev" init

# Validar sintaxe e referências
terraform -chdir="terraform/env/dev" validate

# (Opcional) Formatar código
terraform -chdir="terraform/env/dev" fmt -recursive

# Gerar um plano e salvar em arquivo
terraform -chdir="terraform/env/dev" plan -out=main.tfplan -var-file=terraform.tfvars

# Aplicar o plano salvo (recomendado) ou aplicar direto
terraform -chdir="terraform/env/dev" apply "main.tfplan"
# ou aplicar direto
terraform -chdir="terraform/env/dev" apply -var-file=terraform.tfvars -auto-approve

# Alternativa 2: mudar o diretório (PowerShell)
# Set-Location -Path .\terraform\env\dev
```

Dicas:

- Use `-var 'key=value'` para sobrescrever variáveis em linha de comando quando necessário.
- Para trabalhar com perfis AWS diferentes, exporte `AWS_PROFILE` ou use `profile_name` conforme configurado.

## Limpeza (remover infraestrutura)

Para destruir os recursos criados por este ambiente (tenha cuidado — essa ação remove recursos):

```powershell
Set-Location -Path .\\terraform\\env\\dev
terraform destroy -var-file=terraform.tfvars -auto-approve
```

Se você utilizou um backend remoto para o estado, verifique e remova quaisquer artefatos remanescentes (por exemplo, objetos S3 ou entradas DynamoDB para lock) conforme apropriado.

## Boas práticas e observações

- Nunca commit credenciais (client secrets, tokens, etc.). Use variáveis de ambiente, vaults ou secrets managers.
- Considere habilitar um backend remoto (S3 + DynamoDB) para colaboração e locking do estado.
- Mantenha o módulo `versions.tf` atualizado para fixar versões de providers e evitar quebras inesperadas.
- Teste alterações de infraestrutura em `dev` antes de promover para `prod`.

## Arquivos relevantes

- `terraform/env/dev/` — configurações e estado local do ambiente de desenvolvimento
- `terraform/modules/` — módulos reutilizáveis (VPC, S3, IAM, Databricks, etc.)

## Contato

Para dúvidas, abra uma issue ou entre em contato com a equipe de infraestrutura responsável pelo projeto.
