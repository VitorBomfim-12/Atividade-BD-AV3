-- =============================================================================
-- 3ª Avaliação de Banco de Dados Relacional (BDR) - FATEC SJC
-- Parte 3 - Programação em Banco de Dados (SQLite)
-- =============================================================================

PRAGMA foreign_keys = ON;

-- =============================================================================
-- 1. VIEWS (VISÕES)
-- =============================================================================

-- View 1: Junta tickets, projetos, clientes (INNER JOIN) e técnico responsável (LEFT JOIN)
DROP VIEW IF EXISTS vw_resumo_tickets;
CREATE VIEW vw_resumo_tickets AS
SELECT
    t.id AS ticket_id,
    t.titulo,
    t.categoria,
    t.prioridade,
    t.status,
    t.sla_em,
    p.nome AS projeto,
    c.nome AS cliente,
    COALESCE(u.nome, 'Sem técnico') AS responsavel
FROM tickets t
INNER JOIN projetos p ON p.id = t.projeto_id
INNER JOIN clientes c ON c.id = p.cliente_id
LEFT JOIN usuarios u ON u.id = t.responsavel_id;

-- View 2: Mostra todas as equipes e quantos tickets cada uma tem usando RIGHT JOIN e GROUP BY
DROP VIEW IF EXISTS vw_tickets_por_equipe;
CREATE VIEW vw_tickets_por_equipe AS
SELECT
    e.id AS equipe_id,
    e.nome AS equipe,
    e.ativo,
    COUNT(te.ticket_id) AS total_tickets
FROM ticket_equipes te
RIGHT JOIN equipes e ON e.id = te.equipe_id
GROUP BY e.id, e.nome, e.ativo;


-- =============================================================================
-- 2. TRIGGERS (6 GATILHOS NATIVOS DO SQLITE)
-- =============================================================================

-- Trigger 1: Grava log em atividades_conta quando um novo usuário é criado
DROP TRIGGER IF EXISTS trg_log_novo_usuario;
CREATE TRIGGER trg_log_novo_usuario
AFTER INSERT ON usuarios
FOR EACH ROW
BEGIN
    INSERT INTO atividades_conta (id, tipo, descricao, criado_em, usuario_id)
    VALUES (
        'ativ-' || lower(hex(randomblob(4))),
        'CRIACAO',
        'Novo usuário cadastrado: ' || NEW.nome || ' (' || NEW.cargo || ')',
        CURRENT_TIMESTAMP,
        NEW.id
    );
END;

-- Trigger 2: Grava log em atividades_conta quando um usuário é ativado ou inativado
DROP TRIGGER IF EXISTS trg_log_inativar_usuario;
CREATE TRIGGER trg_log_inativar_usuario
AFTER UPDATE OF ativo ON usuarios
FOR EACH ROW
WHEN OLD.ativo != NEW.ativo
BEGIN
    INSERT INTO atividades_conta (id, tipo, descricao, criado_em, usuario_id)
    VALUES (
        'ativ-' || lower(hex(randomblob(4))),
        CASE WHEN NEW.ativo = 0 THEN 'INATIVACAO' ELSE 'REATIVACAO' END,
        'Status do usuário ' || NEW.nome || ' alterado para ativo = ' || NEW.ativo,
        CURRENT_TIMESTAMP,
        NEW.id
    );
END;

-- Trigger 3: Registra no histórico automaticamente quando um ticket é aberto
DROP TRIGGER IF EXISTS trg_historico_novo_ticket;
CREATE TRIGGER trg_historico_novo_ticket
AFTER INSERT ON tickets
FOR EACH ROW
BEGIN
    INSERT INTO historico_ticket (id, evento, descricao, criado_em, ticket_id, usuario_id, equipe_id, inicio_equipe_id)
    VALUES (
        'hist-' || lower(hex(randomblob(4))),
        'TICKET_ABERTO',
        'Ticket aberto com prioridade ' || NEW.prioridade,
        CURRENT_TIMESTAMP,
        NEW.id,
        NEW.aberto_por_id,
        (SELECT equipe_id FROM usuarios WHERE id = NEW.aberto_por_id),
        NULL
    );
END;

-- Trigger 4: Registra no histórico toda vez que o status do ticket muda
DROP TRIGGER IF EXISTS trg_historico_mudanca_status;
CREATE TRIGGER trg_historico_mudanca_status
AFTER UPDATE OF status ON tickets
FOR EACH ROW
WHEN OLD.status != NEW.status
BEGIN
    INSERT INTO historico_ticket (id, evento, descricao, criado_em, ticket_id, usuario_id, equipe_id, inicio_equipe_id)
    VALUES (
        'hist-' || lower(hex(randomblob(4))),
        'MUDANCA_STATUS',
        'Status alterado de ' || OLD.status || ' para ' || NEW.status,
        CURRENT_TIMESTAMP,
        NEW.id,
        NEW.responsavel_id,
        (SELECT equipe_id FROM usuarios WHERE id = NEW.responsavel_id),
        NULL
    );
END;

-- Trigger 5: Ao inserir relatório técnico, grava no histórico e muda ticket NAO_INICIADO para EM_ANDAMENTO
DROP TRIGGER IF EXISTS trg_historico_novo_relatorio;
CREATE TRIGGER trg_historico_novo_relatorio
AFTER INSERT ON relatorios
FOR EACH ROW
BEGIN
    INSERT INTO historico_ticket (id, evento, descricao, criado_em, ticket_id, usuario_id, equipe_id, inicio_equipe_id)
    VALUES (
        'hist-' || lower(hex(randomblob(4))),
        'RELATORIO_ADICIONADO',
        'Relatório registrado pelo técnico ' || NEW.autor_id,
        CURRENT_TIMESTAMP,
        NEW.ticket_id,
        NEW.autor_id,
        (SELECT equipe_id FROM usuarios WHERE id = NEW.autor_id),
        NULL
    );

    UPDATE tickets
    SET status = 'EM_ANDAMENTO',
        atualizado_em = CURRENT_TIMESTAMP
    WHERE id = NEW.ticket_id
      AND status = 'NAO_INICIADO';
END;

-- Trigger 6: Impede que um ticket seja ENCERRADO se não tiver pelo menos 1 relatório técnico
DROP TRIGGER IF EXISTS trg_bloquear_encerramento_sem_relatorio;
CREATE TRIGGER trg_bloquear_encerramento_sem_relatorio
BEFORE UPDATE OF status ON tickets
FOR EACH ROW
WHEN NEW.status = 'ENCERRADO'
 AND OLD.status != 'ENCERRADO'
 AND (SELECT COUNT(*) FROM relatorios WHERE ticket_id = NEW.id) = 0
BEGIN
    SELECT RAISE(ABORT, 'Erro: Nao e permitido encerrar um ticket sem relatorio tecnico cadastrado.');
END;


-- =============================================================================
-- 3. CONSULTAS DAS 6 FUNCTIONS (SQLITE)
-- (No SQLite não existe CREATE FUNCTION nativo em SQL; as funções são
--  executadas usando as consultas SQL abaixo ou via sqlite3.create_function)
-- =============================================================================

-- Function 1 (fn_total_tickets_projeto): Total de tickets de um projeto
SELECT projeto_id, COUNT(*) AS total_tickets
FROM tickets
WHERE projeto_id = 'proj-01'
GROUP BY projeto_id;

-- Function 2 (fn_percentual_concluidos_projeto): Percentual de tickets encerrados no projeto
SELECT
    projeto_id,
    COUNT(*) AS total,
    SUM(CASE WHEN status = 'ENCERRADO' THEN 1 ELSE 0 END) AS encerrados,
    ROUND((SUM(CASE WHEN status = 'ENCERRADO' THEN 1.0 ELSE 0.0 END) / COUNT(*)) * 100, 2) AS percentual_concluido
FROM tickets
WHERE projeto_id = 'proj-01'
GROUP BY projeto_id;

-- Function 3 (fn_verificar_sla_ticket): Verifica se o ticket está NO PRAZO ou ATRASADO
SELECT
    id AS ticket_id,
    titulo,
    status,
    sla_em,
    CASE
        WHEN status = 'ENCERRADO' AND encerrado_em <= sla_em THEN 'ENCERRADO NO PRAZO'
        WHEN status = 'ENCERRADO' AND encerrado_em > sla_em THEN 'ENCERRADO COM ATRASO'
        WHEN sla_em < '2026-11-18 12:00:00' THEN 'ATRASADO'
        ELSE 'DENTRO DO PRAZO'
    END AS situacao_sla
FROM tickets
WHERE id IN ('tkt-01', 'tkt-18', 'tkt-22', 'tkt-30');

-- Function 4 (fn_total_relatorios_tecnico): Quantidade de relatórios feitos por um técnico (INNER JOIN)
SELECT
    u.id AS usuario_id,
    u.nome AS tecnico,
    COUNT(r.id) AS total_relatorios
FROM usuarios u
INNER JOIN relatorios r ON r.autor_id = u.id
WHERE u.id = 'usr-26'
GROUP BY u.id, u.nome;

-- Function 5 (fn_datas_tickets_cliente): Data do primeiro (MIN) e último (MAX) ticket de um cliente
SELECT
    c.id AS cliente_id,
    c.nome AS cliente,
    MIN(t.criado_em) AS primeiro_ticket,
    MAX(t.criado_em) AS ultimo_ticket
FROM clientes c
INNER JOIN projetos p ON p.cliente_id = c.id
INNER JOIN tickets t ON t.projeto_id = p.id
WHERE c.id = 'cli-01'
GROUP BY c.id, c.nome;

-- Function 6 (fn_comparar_equipe_media): Subconsulta comparando tickets da equipe com a média geral
SELECT
    e.id AS equipe_id,
    e.nome AS equipe,
    COUNT(te.ticket_id) AS qtd_tickets,
    CASE
        WHEN COUNT(te.ticket_id) >= (
            SELECT AVG(qtd) FROM (
                SELECT COUNT(ticket_id) AS qtd FROM ticket_equipes GROUP BY equipe_id
            )
        ) THEN 'ACIMA DA MEDIA'
        ELSE 'ABAIXO DA MEDIA'
    END AS comparacao_media
FROM equipes e
LEFT JOIN ticket_equipes te ON te.equipe_id = e.id
WHERE e.id IN ('eq-01', 'eq-02', 'eq-30')
GROUP BY e.id, e.nome;


-- =============================================================================
-- 4. OPERAÇÕES E CONSULTAS DAS 6 STORED PROCEDURES (SQLITE)
-- (No SQLite não existe CREATE PROCEDURE nativo em SQL; abaixo estão os blocos
--  SQL correspondentes a cada uma das 6 Stored Procedures da Parte 3)
-- =============================================================================

-- Stored Procedure 1 (sp_abrir_ticket): Cria um novo ticket, aloca a equipe e mostra o resumo na View
INSERT OR IGNORE INTO tickets (id, titulo, descricao, categoria, prioridade, status, sla_em, projeto_id, aberto_por_id, responsavel_id)
VALUES ('tkt-51', 'Chamado #51 - Instalacao Camera', 'Instalacao de camera nova no setor 1', 'INSTALACAO', 'ALTA', 'NAO_INICIADO', '2026-11-25 18:00:00', 'proj-01', 'usr-09', 'usr-26');

INSERT OR IGNORE INTO ticket_equipes (id, ticket_id, equipe_id)
VALUES ('te-51', 'tkt-51', 'eq-01');

SELECT ticket_id, titulo, categoria, prioridade, status, projeto, responsavel
FROM vw_resumo_tickets
WHERE ticket_id = 'tkt-51';

-- Stored Procedure 2 (sp_encerrar_ticket): Encerra um ticket que já possui relatório e exibe o resultado
UPDATE tickets
SET status = 'ENCERRADO',
    encerrado_em = '2026-11-18 16:00:00'
WHERE id = 'tkt-44';

SELECT id, titulo, status, sla_em, encerrado_em
FROM tickets
WHERE id = 'tkt-44';

-- Stored Procedure 3 (sp_relatorio_projetos_clientes): Lista clientes, projetos e tickets (LEFT JOIN + GROUP BY)
SELECT
    c.id AS cliente_id,
    c.nome AS cliente,
    COUNT(DISTINCT p.id) AS qtd_projetos,
    COUNT(t.id) AS qtd_tickets
FROM clientes c
LEFT JOIN projetos p ON p.cliente_id = c.id
LEFT JOIN tickets t ON t.projeto_id = p.id
GROUP BY c.id, c.nome;

-- Stored Procedure 4 (sp_relatorio_geral_equipes): Consulta a View com RIGHT JOIN mostrando equipes com e sem tickets
SELECT equipe_id, equipe, ativo, total_tickets
FROM vw_tickets_por_equipe;

-- Stored Procedure 5 (sp_tickets_acima_media_relatorios): Tickets com mais relatórios que a média (INNER JOIN + HAVING + Subconsulta)
SELECT
    t.id AS ticket_id,
    t.titulo,
    COUNT(r.id) AS qtd_relatorios
FROM tickets t
INNER JOIN relatorios r ON r.ticket_id = t.id
GROUP BY t.id, t.titulo
HAVING COUNT(r.id) > (
    SELECT AVG(contagem)
    FROM (SELECT COUNT(id) AS contagem FROM relatorios GROUP BY ticket_id)
);

-- Stored Procedure 6 (sp_atualizar_prioridade_atrasados_cursor): Atualiza tickets atrasados para prioridade CRITICA
UPDATE tickets
SET prioridade = 'CRITICA'
WHERE status != 'ENCERRADO'
  AND sla_em < '2026-11-18 00:00:00';

SELECT id AS ticket_id, titulo, prioridade, status, sla_em
FROM tickets
WHERE status != 'ENCERRADO'
  AND sla_em < '2026-11-18 00:00:00';

