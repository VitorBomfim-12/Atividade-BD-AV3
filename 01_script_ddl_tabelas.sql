-- =============================================================================
-- 3ª Avaliação de Banco de Dados Relacional (BDR) - FATEC SJC
-- Script DDL - Criação das Tabelas (SQLite)
-- =============================================================================

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS atividades_conta;
DROP TABLE IF EXISTS historico_ticket;
DROP TABLE IF EXISTS relatorios;
DROP TABLE IF EXISTS ticket_equipes;
DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS projetos;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS equipes;

-- 1. Tabela de Equipes
CREATE TABLE equipes (
    id TEXT PRIMARY KEY,
    nome TEXT NOT NULL UNIQUE,
    descricao TEXT,
    ativo INTEGER NOT NULL DEFAULT 1,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabela de Clientes
CREATE TABLE clientes (
    id TEXT PRIMARY KEY,
    nome TEXT NOT NULL UNIQUE,
    ativo INTEGER NOT NULL DEFAULT 1,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabela de Usuários
CREATE TABLE usuarios (
    id TEXT PRIMARY KEY,
    nome TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    senha_hash TEXT NOT NULL,
    cargo TEXT NOT NULL CHECK (cargo IN ('TECNICO', 'GESTOR', 'SUPORTE', 'SUPORTE_INTERNO', 'COMERCIAL')),
    ativo INTEGER NOT NULL DEFAULT 1,
    senha_provisoria INTEGER NOT NULL DEFAULT 1,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    equipe_id TEXT,
    criado_por_id TEXT,
    FOREIGN KEY (equipe_id) REFERENCES equipes(id) ON DELETE SET NULL,
    FOREIGN KEY (criado_por_id) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- 4. Tabela de Projetos
CREATE TABLE projetos (
    id TEXT PRIMARY KEY,
    nome TEXT NOT NULL,
    local_instalacao TEXT NOT NULL,
    descricao TEXT,
    ativo INTEGER NOT NULL DEFAULT 1,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cliente_id TEXT NOT NULL,
    equipe_id TEXT NOT NULL,
    gestor_id TEXT NOT NULL,
    UNIQUE (cliente_id, nome),
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE RESTRICT,
    FOREIGN KEY (equipe_id) REFERENCES equipes(id) ON DELETE RESTRICT,
    FOREIGN KEY (gestor_id) REFERENCES usuarios(id) ON DELETE RESTRICT
);

-- 5. Tabela de Tickets
CREATE TABLE tickets (
    id TEXT PRIMARY KEY,
    titulo TEXT NOT NULL,
    descricao TEXT NOT NULL,
    categoria TEXT NOT NULL CHECK (categoria IN ('MANUTENCAO', 'INSTALACAO')),
    prioridade TEXT NOT NULL DEFAULT 'MEDIA' CHECK (prioridade IN ('BAIXA', 'MEDIA', 'ALTA', 'CRITICA')),
    status TEXT NOT NULL DEFAULT 'EM_ANDAMENTO' CHECK (status IN ('NAO_INICIADO', 'EM_ANDAMENTO', 'SOLICITACAO_ENCERRAMENTO', 'ENCERRADO', 'EM_REVISAO')),
    sla_em DATETIME NOT NULL,
    encerrado_em DATETIME,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    projeto_id TEXT NOT NULL,
    aberto_por_id TEXT NOT NULL,
    responsavel_id TEXT,
    FOREIGN KEY (projeto_id) REFERENCES projetos(id) ON DELETE RESTRICT,
    FOREIGN KEY (aberto_por_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
    FOREIGN KEY (responsavel_id) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- 6. Tabela Associativa Ticket_Equipes (N:N)
CREATE TABLE ticket_equipes (
    id TEXT PRIMARY KEY,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ticket_id TEXT NOT NULL,
    equipe_id TEXT NOT NULL,
    UNIQUE (ticket_id, equipe_id),
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    FOREIGN KEY (equipe_id) REFERENCES equipes(id) ON DELETE CASCADE
);

-- 7. Tabela de Relatórios Técnicos
CREATE TABLE relatorios (
    id TEXT PRIMARY KEY,
    trabalho_realizado TEXT NOT NULL,
    materiais_utilizados TEXT NOT NULL,
    outros_detalhes TEXT NOT NULL,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ticket_id TEXT NOT NULL,
    autor_id TEXT NOT NULL,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE RESTRICT,
    FOREIGN KEY (autor_id) REFERENCES usuarios(id) ON DELETE RESTRICT
);

-- 8. Tabela de Histórico do Ticket
CREATE TABLE historico_ticket (
    id TEXT PRIMARY KEY,
    evento TEXT NOT NULL,
    descricao TEXT NOT NULL,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ticket_id TEXT NOT NULL,
    usuario_id TEXT,
    equipe_id TEXT,
    inicio_equipe_id TEXT,
    UNIQUE (ticket_id, inicio_equipe_id),
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE RESTRICT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
    FOREIGN KEY (equipe_id) REFERENCES equipes(id) ON DELETE SET NULL,
    FOREIGN KEY (inicio_equipe_id) REFERENCES equipes(id) ON DELETE SET NULL
);

-- 9. Tabela de Atividades da Conta
CREATE TABLE atividades_conta (
    id TEXT PRIMARY KEY,
    tipo TEXT NOT NULL,
    descricao TEXT NOT NULL,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario_id TEXT NOT NULL,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- Índices previstos no schema
CREATE INDEX ix_usuarios_equipe ON usuarios (equipe_id);
CREATE INDEX ix_projetos_equipe ON projetos (equipe_id);
CREATE INDEX ix_projetos_gestor ON projetos (gestor_id);
CREATE INDEX ix_tickets_fila ON tickets (projeto_id, status, prioridade, criado_em);
CREATE INDEX ix_tickets_sla ON tickets (status, sla_em);
CREATE INDEX ix_tickets_aberto_por ON tickets (aberto_por_id);
CREATE INDEX ix_tickets_responsavel ON tickets (responsavel_id);
CREATE INDEX ix_ticket_equipes_equipe ON ticket_equipes (equipe_id);
CREATE INDEX ix_relatorios_ticket ON relatorios (ticket_id, criado_em);
CREATE INDEX ix_relatorios_autor ON relatorios (autor_id);
CREATE INDEX ix_historico_ticket_data ON historico_ticket (ticket_id, criado_em);
CREATE INDEX ix_historico_usuario ON historico_ticket (usuario_id);
CREATE INDEX ix_historico_equipe ON historico_ticket (equipe_id);
CREATE INDEX ix_historico_inicio_equipe ON historico_ticket (inicio_equipe_id);
CREATE INDEX ix_atividades_conta_usuario_data ON atividades_conta (usuario_id, criado_em);
