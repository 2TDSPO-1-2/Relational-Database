# 🐾 ARKIVE — Banco de Dados Relacional

> **Plataforma de saúde e bem-estar animal** — prontuário eletrônico, controle preventivo e alertas inteligentes para tutores, veterinários e clínicas parceiras.

---

## 📋 Sobre o Projeto

**ARKIVE** é uma aplicação que centraliza o histórico clínico de pets, coordena o relacionamento entre tutores, clínicas veterinárias e veterinários, e automatiza lembretes de cuidados preventivos. Este repositório contém o **banco de dados relacional Oracle** que sustenta toda a operação transacional do sistema.

### Disciplina
**Mastering Relational and Non-Relational Database**  
Turma: `2TDSPO` · FIAP - Unidade Paulista · 2026

### Equipe

| RM | Nome |
|:---|:-----|
| RM561408 | Gustavo Crevelari Monteiro Porto |
| RM561996 | Lucca de Araujo Gomes |
| RM561671 | Rafaela Ferreira Santos |
| RM566224 | Victor Sabelli Rocha Batista |

---

## 📂 Estrutura do Repositório

```
ARKIVE/
├── Docs/
│    ├── ARKIVE_Documentacao_BD.pdf (Documentação técnica completa)
│    ├── ARKIVE_Logical.pdf (Modelo Lógico do ARKIVE)
│    └── ARKIVE_Relational.pdf (Modelo Físico do ARKIVE)
├── Models/
│    ├── ARKIVE_models/ (Arquivos de referência do DMD)
│    └── ARKIVE_models.dmd (Construtor do modelo Oracle DM)
├── Scripts/
│    ├── ARKIVE_boot-setup_DDL_v3.sql (Scripts DDL — criação do schema)
│    ├── ARKIVE_seed_DML_v3.sql (Scripts DML — procedures de carga e dados de teste)
│    └── ARKIVE_tests_DQL_v1.sql (Scripts DQL — relatórios e testes de consulta)
└── README.md (Este arquivo)
```

---

## 🗄️ Visão Geral do Banco de Dados

### Tecnologia

- **SGBD:** Oracle Database 12c
- **Modelagem:** Oracle Data Modeler 23.1
- **Notação:** Barker (Modelo Lógico / DER)
- **Normalização:** 3ª Forma Normal (3FN)

### Sumário do Schema

| Objeto | Quantidade |
|:-------|:----------:|
| Tabelas | 23 |
| Índices implícitos (PK + UNIQUE) | 33 |
| Índices explícitos não-únicos (IX_ARKIVE_*) | 41 |
| Índices únicos explícitos | 1 |
| Procedures de carga (PR_ARKIVE_INS_*) | 22 |
| Procedure auxiliar de log | 1 |
| Blocos anônimos de exibição | 2 |
| Bloco LAG / LEAD | 1 |
| Blocos com cursor explícito | 4 |

---

## 🏗️ Agrupamentos Funcionais

```
┌─────────────────────────────────────┐
│  DOMÍNIOS CADASTRAIS                │
│  ├─ TB_ARKIVE_ESPECIE               │
│  ├─ TB_ARKIVE_RACA                  │
│  ├─ TB_ARKIVE_CATEGORIA_DOENCA      │
│  ├─ TB_ARKIVE_DOENCA                │
│  └─ TB_ARKIVE_PREDISPOSICAO         │
│                                     │
│  PESSOAS E INSTITUIÇÕES             │
│  ├─ TB_ARKIVE_RESPONSAVEL           │
│  ├─ TB_ARKIVE_CLINICA               │
│  ├─ TB_ARKIVE_VETERINARIO           │
│  └─ TB_ARKIVE_USUARIO               │
│                                     │
│  ANIMAIS E VÍNCULOS                 │
│  ├─ TB_ARKIVE_ANIMAL                │
│  ├─ TB_ARKIVE_RESPONSAVEL_ANIMAL    │
│  └─ TB_ARKIVE_RESPONSAVEL_CLINICA   │
│                                     │
│  ATENDIMENTO CLÍNICO                │
│  ├─ TB_ARKIVE_CONSULTA              │
│  ├─ TB_ARKIVE_DIAGNOSTICO           │
│  ├─ TB_ARKIVE_PRESCRICAO            │
│  ├─ TB_ARKIVE_AVALIACAO_BEM_ESTAR   │
│  └─ TB_ARKIVE_ADESAO_PRESCRICAO     │
│                                     │
│  CUIDADOS PREVENTIVOS               │
│  ├─ TB_ARKIVE_PROTOCOLO_PREVENTIVO  │
│  └─ TB_ARKIVE_EVENTO_PREVENTIVO     │
│                                     │
│  COMUNICAÇÃO E ENGAJAMENTO          │
│  ├─ TB_ARKIVE_ALERTA                │
│  ├─ TB_ARKIVE_FEEDBACK_NPS          │
│  └─ TB_ARKIVE_EVENTO_JORNADA        │
│                                     │
│  AUDITORIA                          │
│  └─ TB_ARKIVE_LOG_ERRO              │
└─────────────────────────────────────┘
```

---

## 🚀 Como Executar

### Pré-requisitos

- Oracle Database 12c (ou superior)
- Oracle SQL Developer ou SQL*Plus
- Usuário com permissões de DDL no schema de destino

### Ordem de Execução

Execute os scripts **nesta ordem**:

```sql
-- 1. Cria toda a estrutura relacional do banco (DROP + CREATE de todas as tabelas e índices)
@ARKIVE_boot-setup_DDL_v3.sql

-- 2. Cria as procedures de carga e insere os dados de teste
@ARKIVE_seed_DML_v3.sql

-- 3. Executa os relatórios e blocos de consulta
@ARKIVE_tests_DQL_v1.sql
```

> ⚠️ **IMPORTANTE:**
> O script DDL remove automaticamente todos os objetos TB_ARKIVE_* utilizando CASCADE CONSTRAINTS PURGE antes da recriação da estrutura. Não execute em ambientes produtivos.

### Configurações de Sessão

Os scripts DML e DQL configuram automaticamente:

```sql
SET SERVEROUTPUT ON SIZE UNLIMITED;
SET VERIFY OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY HH24:MI:SS';
```

---

## 📦 Detalhamento dos Scripts

### `ARKIVE_boot-setup_DDL_v3.sql`

| Seção | Conteúdo |
|:------|:---------|
| `# 0` | Bloco PL/SQL de limpeza — DROP de todas as tabelas, views, procedures, funções e sequences com `ARKIVE` no nome |
| `# 1` | 23 `CREATE TABLE` com constraints (PK, FK, UQ, CHECK) e `COMMENT ON TABLE / COLUMN` |
| `# 2` | 42 `CREATE INDEX` explícitos (41 não-únicos + 1 único com `NVL`) |

### `ARKIVE_seed_DML_v3.sql`

| Seção | Conteúdo |
|:------|:---------|
| `# 0` | Configuração de ambiente (SET, ALTER SESSION) |
| `# 1` | `PR_ARKIVE_REG_ERRO` — procedure auxiliar com `AUTONOMOUS_TRANSACTION` para log de erros |
| `# 2` | 22 procedures `PR_ARKIVE_INS_*` — uma por tabela, com parâmetros e tratamento de exceções |
| `# 3` | 22 blocos anônimos de chamada — inserção de 10 registros por tabela via procedures |

### `ARKIVE_tests_DQL_v1.sql`

| Seção | Bloco | Conteúdo |
|:------|:------|:---------|
| `# 1` | 1.1 | Bloco anônimo: 3 consultas com JOIN + GROUP BY + ORDER BY (atendimentos por clínica, animais por espécie/porte, responsáveis com seus pets) |
| `# 1` | 1.2 | Bloco anônimo: 2 consultas com JOIN + GROUP BY + ORDER BY (NPS por veterinário, aderência a protocolos preventivos) |
| `# 2` | 2   | Bloco com cursor `LAG`/`LEAD` sobre `TB_ARKIVE_AVALIACAO_BEM_ESTAR` — exibe peso anterior, atual e próximo; "Vazio" quando não existe |
| `# 3` | 3.1 | Cursor explícito: relatório completo NPS + sumarização geral + sumarização agrupada por categoria (Promotor/Neutro/Detrator) |
| `# 3` | 3.2 | Cursor explícito: consultas por status com `CASE` para tradução de códigos e alerta de peso elevado |
| `# 3` | 3.3 | Cursor explícito: prescrições por via de administração com classificação de situação (Em andamento/Concluído/Contínuo) |
| `# 3` | 3.4 | Cursor explícito: alertas com cálculo de tempo de resposta em horas e resumo por status |

---

## 🔑 Convenções de Nomenclatura

| Prefixo | Tipo de Objeto |
|:--------|:--------------|
| `TB_ARKIVE_*` | Tabelas |
| `PK_ARKIVE_*` | Constraints Primary Key |
| `FK_*` | Constraints Foreign Key |
| `UQ_ARKIVE_*` | Constraints Unique |
| `CK_ARKIVE_*` | Constraints Check |
| `IX_ARKIVE_*` | Índices explícitos não-únicos |
| `UX_ARKIVE_*` | Índice único explícito |
| `PR_ARKIVE_*` | Procedures PL/SQL |
| `ID_*` | Chaves primárias (NUMBER IDENTITY) |
| `ST_*` | Flags de status — `CHAR(1)` valores `'S'`/`'N'` |
| `TP_*` | Tipo/categoria com domínio restrito por CHECK |
| `DT_*` | Data/hora (DATE) |
| `DS_*` | Descrição textual (VARCHAR2 ou CLOB) |
| `NM_*` | Nome de entidade (VARCHAR2) |

---

## 📄 Licença

Projeto acadêmico desenvolvido para fins educacionais. Todos os dados são fictícios.
Este projeto foi desenvolvido com o apoio do assistente de IA Claude (`https://claude.ai/`)

---

*Gerado em maio de 2026 · FIAP 2TDSPO*
