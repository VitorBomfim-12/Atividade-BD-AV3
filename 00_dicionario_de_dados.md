# Dicionário de Dados - Plataforma de Ordens de Serviço (Altave)

- **Script DDL:** [01_ddl_tabelas.sql](file:///home/vitor/fatec/bd/01_ddl_tabelas.sql)

---

## 1. Tabela `equipes`
Armazena as equipes técnicas de atendimento.

| Coluna | Tipo | Chave | Restrições | Descrição |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `TEXT` | **PK** | `NOT NULL` | Identificador único da equipe. |
| `nome` | `TEXT` | - | `NOT NULL`, `UNIQUE` | Nome da equipe técnica. |
| `descricao` | `TEXT` | - | `NULL` | Descrição da especialidade da equipe. |
| `ativo` | `INTEGER` | - | `NOT NULL`, `DEFAULT 1` | Indica se a equipe está ativa (`1`) ou inativa (`0`). |
| `criado_em` | `DATETIME` | - | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Data e hora de criação. |
| `atualizado_em` | `DATETIME` | - | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Data e hora da última alteração. |

---

## 2. Tabela `clientes`
Armazena as empresas clientes que contratam os projetos.

| Coluna | Tipo | Chave | Restrições | Descrição |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `TEXT` | **PK** | `NOT NULL` | Identificador único do cliente. |
| `nome` | `TEXT` | - | `NOT NULL`, `UNIQUE` | Nome da empresa cliente. |
| `ativo` | `INTEGER` | - | `NOT NULL`, `DEFAULT 1` | Indica se o cliente está ativo (`1`) ou inativo (`0`). |
| `criado_em` | `DATETIME` | - | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Data e hora de cadastro. |
| `atualizado_em` | `DATETIME` | - | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Data e hora da última alteração. |

---

## 3. Tabela `usuarios`
Armazena os usuários do sistema (técnicos, gestores, suporte e comercial).

| Coluna | Tipo | Chave | Restrições | Descrição |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `TEXT` | **PK** | `NOT NULL` | Identificador único do usuário. |
| `nome` | `TEXT` | - | `NOT NULL` | Nome completo do usuário. |
| `email` | `TEXT` | - | `NOT NULL`, `UNIQUE` | E-mail de login do usuário. |
| `senha_hash` | `TEXT` | - | `NOT NULL` | Hash da senha de acesso. |
| `cargo` | `TEXT` | - | `NOT NULL`, `CHECK (TECNICO, GESTOR, SUPORTE, SUPORTE_INTERNO, COMERCIAL)` | Cargo/perfil do usuário no sistema. |
| `ativo` | `INTEGER` | - | `NOT NULL`, `DEFAULT 1` | Indica se o usuário está ativo (`1`) ou inativo (`0`). |
| `senha_provisoria` | `INTEGER` | - | `NOT NULL`, `DEFAULT 1` | Indica se o usuário precisa trocar a senha (`1` = sim, `0` = não). |
| `criado_em` | `DATETIME` | - | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Data e hora de criação da conta. |
| `atualizado_em` | `DATETIME` | - | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Data e hora da última alteração. |
| `equipe_id` | `TEXT` | **FK** | `NULL`, `REFERENCES equipes(id) ON DELETE SET NULL` | Equipe à qual o usuário pertence. |
| `criado_por_id` | `TEXT` | **FK** | `NULL`, `REFERENCES usuarios(id) ON DELETE SET NULL` | Auto-relacionamento indicando quem criou o usuário. |

---

## 4. Tabela `projetos`
Armazena os projetos/contratos ativos dos clientes.

| Coluna | Tipo | Chave | Restrições | Descrição |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `TEXT` | **PK** | `NOT NULL` | Identificador único do projeto. |
| `nome` | `TEXT` | - | `NOT NULL`, `UNIQUE(cliente_id, nome)` | Nome do projeto dentro do cliente. |
| `local_instalacao` | `TEXT` | - | `NOT NULL` | Local físico onde o sistema é instalado. |
| `descricao` | `TEXT` | - | `NULL` | Detalhes do projeto. |
| `ativo` | `INTEGER` | - | `NOT NULL`, `DEFAULT 1` | Indica se o projeto está ativo (`1`) ou inativo (`0`). |
| `criado_em` | `DATETIME` | - | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Data e hora de cadastro. |
| `atualizado_em` | `DATETIME` | - | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Data e hora da última alteração. |
| `cliente_id` | `TEXT` | **FK** | `NOT NULL`, `REFERENCES clientes(id) ON DELETE RESTRICT` | Cliente dono do projeto. |
| `equipe_id` | `TEXT` | **FK** | `NOT NULL`, `REFERENCES equipes(id) ON DELETE RESTRICT` | Equipe principal responsável pelo projeto. |
| `gestor_id` | `TEXT` | **FK** | `NOT NULL`, `REFERENCES usuarios(id) ON DELETE RESTRICT` | Usuário gestor do projeto. |

---

## 5. Tabela `tickets`
Armazena as ordens de serviço (chamados de instalação e manutenção).

| Coluna | Tipo | Chave | Restrições | Descrição |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `TEXT` | **PK** | `NOT NULL` | Identificador único do ticket. |
| `titulo` | `TEXT` | - | `NOT NULL` | Título resumido do chamado. |
| `descricao` | `TEXT` | - | `NOT NULL` | Descrição do problema ou serviço. |
| `categoria` | `TEXT` | - | `NOT NULL`, `CHECK (MANUTENCAO, INSTALACAO)` | Tipo do chamado. |
| `prioridade` | `TEXT` | - | `NOT NULL`, `DEFAULT 'MEDIA'`, `CHECK (BAIXA, MEDIA, ALTA, CRITICA)` | Prioridade de atendimento. |
| `status` | `TEXT` | - | `NOT NULL`, `DEFAULT 'EM_ANDAMENTO'`, `CHECK (5 status)` | Status atual do ticket. |
| `sla_em` | `DATETIME` | - | `NOT NULL` | Prazo limite (SLA) para conclusão do chamado. |
| `encerrado_em` | `DATETIME` | - | `NULL` | Data e hora em que o ticket foi encerrado. |
| `criado_em` | `DATETIME` | - | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Data e hora de abertura. |
| `atualizado_em` | `DATETIME` | - | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Data e hora da última alteração. |
| `projeto_id` | `TEXT` | **FK** | `NOT NULL`, `REFERENCES projetos(id) ON DELETE RESTRICT` | Projeto ao qual o ticket pertence. |
| `aberto_por_id` | `TEXT` | **FK** | `NOT NULL`, `REFERENCES usuarios(id) ON DELETE RESTRICT` | Usuário que abriu o ticket. |
| `responsavel_id` | `TEXT` | **FK** | `NULL`, `REFERENCES usuarios(id) ON DELETE SET NULL` | Técnico responsável pelo atendimento. |

---

## 6. Tabela `ticket_equipes`
Tabela associativa (`N:N`) que vincula uma ou mais equipes a um ticket.

| Coluna | Tipo | Chave | Restrições | Descrição |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `TEXT` | **PK** | `NOT NULL` | Identificador único do vínculo. |
| `criado_em` | `DATETIME` | - | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Data e hora em que a equipe foi alocada. |
| `ticket_id` | `TEXT` | **FK** | `NOT NULL`, `REFERENCES tickets(id) ON DELETE CASCADE` | Ticket relacionado (`UNIQUE` com `equipe_id`). |
| `equipe_id` | `TEXT` | **FK** | `NOT NULL`, `REFERENCES equipes(id) ON DELETE CASCADE` | Equipe alocada no ticket. |

---

## 7. Tabela `relatorios`
Armazena os relatórios técnicos preenchidos pelos técnicos no atendimento.

| Coluna | Tipo | Chave | Restrições | Descrição |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `TEXT` | **PK** | `NOT NULL` | Identificador único do relatório. |
| `trabalho_realizado` | `TEXT` | - | `NOT NULL` | Descrição do serviço feito. |
| `materiais_utilizados` | `TEXT` | - | `NOT NULL` | Materiais e peças gastos no atendimento. |
| `outros_detalhes` | `TEXT` | - | `NOT NULL` | Observações adicionais. |
| `criado_em` | `DATETIME` | - | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Data e hora de envio do relatório. |
| `atualizado_em` | `DATETIME` | - | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Data e hora da última edição. |
| `ticket_id` | `TEXT` | **FK** | `NOT NULL`, `REFERENCES tickets(id) ON DELETE RESTRICT` | Ticket ao qual o relatório pertence. |
| `autor_id` | `TEXT` | **FK** | `NOT NULL`, `REFERENCES usuarios(id) ON DELETE RESTRICT` | Técnico autor do relatório. |

---

## 8. Tabela `historico_ticket`
Armazena a linha do tempo de eventos e mudanças de status de cada ticket.

| Coluna | Tipo | Chave | Restrições | Descrição |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `TEXT` | **PK** | `NOT NULL` | Identificador único do registro de histórico. |
| `evento` | `TEXT` | - | `NOT NULL` | Tipo do evento (ex.: `TICKET_ABERTO`, `MUDANCA_STATUS`). |
| `descricao` | `TEXT` | - | `NOT NULL` | Explicação do evento ocorrido. |
| `criado_em` | `DATETIME` | - | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Data e hora do evento. |
| `ticket_id` | `TEXT` | **FK** | `NOT NULL`, `REFERENCES tickets(id) ON DELETE RESTRICT` | Ticket relacionado. |
| `usuario_id` | `TEXT` | **FK** | `NULL`, `REFERENCES usuarios(id) ON DELETE SET NULL` | Usuário que realizou a ação. |
| `equipe_id` | `TEXT` | **FK** | `NULL`, `REFERENCES equipes(id) ON DELETE SET NULL` | Equipe do usuário no momento do registro. |
| `inicio_equipe_id` | `TEXT` | **FK** | `NULL`, `UNIQUE(ticket_id, inicio_equipe_id)` | Preenchido no início da atividade para evitar início duplicado pela mesma equipe. |

---

## 9. Tabela `atividades_conta`
Armazena o histórico administrativo de criação e alterações nas contas de usuários.

| Coluna | Tipo | Chave | Restrições | Descrição |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `TEXT` | **PK** | `NOT NULL` | Identificador único da atividade. |
| `tipo` | `TEXT` | - | `NOT NULL` | Tipo da ação (`CRIACAO`, `INATIVACAO`, `REATIVACAO`). |
| `descricao` | `TEXT` | - | `NOT NULL` | Descrição da alteração feita na conta. |
| `criado_em` | `DATETIME` | - | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Data e hora do registro. |
| `usuario_id` | `TEXT` | **FK** | `NOT NULL`, `REFERENCES usuarios(id) ON DELETE CASCADE` | Usuário referente à atividade. |
