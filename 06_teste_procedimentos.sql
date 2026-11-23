-- UTILIZAÇÃO PARA PRINTS
USE av3_bd;

-- VIEWS criadas
-- View 1: Resumo consolidado dos tickets com projeto, cliente e técnico responsável
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

-- STORED PROCEDURES
-- 1
CALL sp_abrir_ticket(
    'tkt-51',
    'Instalacao de Camera Termica Setor Norte',
    'proj-01',
    'usr-09',
    'eq-01'
);

-- 2
SELECT id, titulo, status, sla_em, encerrado_em 
FROM tickets 
WHERE id = 'tkt-21';

CALL sp_encerrar_ticket('tkt-21', 'usr-01');

-- 3
CALL sp_relatorio_projetos_clientes();

-- 4
CALL sp_relatorio_geral_equipes();

-- 5
CALL sp_tickets_acima_media_relatorios();

-- 6
SELECT id, titulo, status, prioridade, sla_em
FROM tickets
WHERE status != 'ENCERRADO' AND sla_em < NOW()
ORDER BY id;

CALL sp_atualizar_prioridade_atrasados_cursor();

SELECT id, titulo, status, prioridade, sla_em
FROM tickets
WHERE status != 'ENCERRADO' AND sla_em < NOW()
ORDER BY id;

-- FUNCTIONS
-- 1
SELECT 
    id AS projeto_id,
    nome AS projeto,
    fn_total_tickets_projeto(id) AS total_tickets
FROM projetos
WHERE id IN ('proj-01', 'proj-10', 'proj-45');

-- 2
SELECT 
    id AS projeto_id,
    nome AS projeto,
    fn_total_tickets_projeto(id) AS total_tickets,
    fn_percentual_concluidos_projeto(id) AS percentual_concluido
FROM projetos
WHERE id IN ('proj-01', 'proj-10', 'proj-25', 'proj-45');

-- 3
SELECT 
    id AS ticket_id,
    titulo,
    status,
    sla_em,
    encerrado_em,
    fn_verificar_sla_ticket(id) AS situacao_sla
FROM tickets
WHERE id IN ('tkt-01', 'tkt-17', 'tkt-22', 'tkt-29');

-- 4
SELECT 
    id AS usuario_id,
    nome,
    cargo,
    fn_total_relatorios_tecnico(id) AS qtd_relatorios
FROM usuarios
WHERE id IN ('usr-26', 'usr-41', 'usr-48', 'usr-01');

-- 5
SELECT 
    id AS cliente_id,
    nome AS cliente,
    fn_datas_tickets_cliente(id) AS historico_datas
FROM clientes
WHERE id IN ('cli-01', 'cli-05', 'cli-45');

-- 6
SELECT 
    e.id AS equipe_id,
    e.nome AS equipe,
    COUNT(te.id) AS qtd_tickets,
    fn_comparar_equipe_media(e.id) AS comparativo_media
FROM equipes e
LEFT JOIN ticket_equipes te ON te.equipe_id = e.id
WHERE e.id IN ('eq-01', 'eq-16', 'eq-30')
GROUP BY e.id, e.nome;

-- TRIGGERS
-- 1
INSERT INTO usuarios (id, nome, email, senha_hash, cargo, equipe_id, criado_por_id)
VALUES ('usr-51', 'Tais Souza', 'tais.souza@altave.com.br', 'hash_senha_51', 'TECNICO', 'eq-01', 'usr-01');

SELECT * 
FROM atividades_conta 
WHERE usuario_id = 'usr-51';

-- 2
UPDATE usuarios SET ativo = 0 WHERE id = 'usr-51';
UPDATE usuarios SET ativo = 1 WHERE id = 'usr-51';

SELECT * 
FROM atividades_conta 
WHERE usuario_id = 'usr-51'
ORDER BY criado_em, id;

-- 3
INSERT INTO tickets (id, titulo, descricao, categoria, prioridade, status, sla_em, projeto_id, aberto_por_id, responsavel_id)
VALUES ('tkt-52', 'Calibracao de Sensor Optico', 'Ajuste de foco na torre sul', 'MANUTENCAO', 'ALTA', 'NAO_INICIADO', DATE_ADD(NOW(), INTERVAL 5 DAY), 'proj-01', 'usr-15', 'usr-26');

SELECT * 
FROM historico_ticket 
WHERE ticket_id = 'tkt-52';

-- 4
UPDATE tickets 
SET status = 'EM_REVISAO' 
WHERE id = 'tkt-52';

SELECT * 
FROM historico_ticket 
WHERE ticket_id = 'tkt-52'
ORDER BY criado_em, id;

-- 5
SELECT id, titulo, status, atualizado_em FROM tickets WHERE id = 'tkt-36';

INSERT INTO relatorios (id, trabalho_realizado, materiais_utilizados, outros_detalhes, ticket_id, autor_id)
VALUES ('rel-51', 'Inspecao inicial e troca de conector', 'Conector blindado IP67', 'Sistema operando em teste', 'tkt-36', 'usr-41');

SELECT id, titulo, status, atualizado_em FROM tickets WHERE id = 'tkt-36';
SELECT * FROM historico_ticket WHERE ticket_id = 'tkt-36';

-- 6
UPDATE tickets 
SET status = 'ENCERRADO', encerrado_em = CURRENT_TIMESTAMP 
WHERE id = 'tkt-37';