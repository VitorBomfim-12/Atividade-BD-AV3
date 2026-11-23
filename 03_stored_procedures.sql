-- STORED PROCEDURES
USE av3_bd;

-- 1: inserir novo ticket no banco
DELIMITER $$
CREATE PROCEDURE sp_abrir_ticket(
    IN p_ticket_id VARCHAR(36),
    IN p_titulo VARCHAR(200),
    IN p_projeto_id VARCHAR(36),
    IN p_aberto_por_id VARCHAR(36),
    IN p_equipe_id VARCHAR(36)
)
BEGIN
    INSERT INTO tickets (id, titulo, descricao, categoria, prioridade, status, sla_em, projeto_id, aberto_por_id, responsavel_id)
    VALUES (p_ticket_id, p_titulo, 'Instalacao de camera nova no setor 1', 'INSTALACAO', 'ALTA', 'NAO_INICIADO', DATE_ADD(NOW(), INTERVAL 3 DAY), p_projeto_id, p_aberto_por_id, 'usr-26');

    INSERT INTO ticket_equipes (id, ticket_id, equipe_id)
    VALUES (CONCAT('te-', p_ticket_id), p_ticket_id, p_equipe_id);

    SELECT ticket_id, titulo, categoria, prioridade, status, projeto, responsavel
    FROM vw_resumo_tickets
    WHERE ticket_id = p_ticket_id;
END $$
DELIMITER ;

-- 2: encerrar ticket que já possui relatório técnico
DELIMITER $$
CREATE PROCEDURE sp_encerrar_ticket(
    IN p_ticket_id VARCHAR(36),
    IN p_usuario_id VARCHAR(36)
)
BEGIN
    UPDATE tickets
    SET status = 'ENCERRADO',
        encerrado_em = NOW()
    WHERE id = p_ticket_id;

    SELECT id, titulo, status, sla_em, encerrado_em
    FROM tickets
    WHERE id = p_ticket_id;
END $$
DELIMITER ;

-- 3: gerar um resumo de quantos projetos e quantos tickets cada cliente possui
DELIMITER $$
CREATE PROCEDURE sp_relatorio_projetos_clientes()
BEGIN
    SELECT
        c.id AS cliente_id,
        c.nome AS cliente,
        COUNT(DISTINCT p.id) AS qtd_projetos,
        COUNT(t.id) AS qtd_tickets
    FROM clientes c
    LEFT JOIN projetos p ON p.cliente_id = c.id
    LEFT JOIN tickets t ON t.projeto_id = p.id
    GROUP BY c.id, c.nome;
END $$
DELIMITER ;

-- 4: consultar a view vw_tickets_por_equipe para listar as equipes com e sem tickets alocados
DELIMITER $$
CREATE PROCEDURE sp_relatorio_geral_equipes()
BEGIN
    SELECT equipe_id, equipe, ativo, total_tickets
    FROM vw_tickets_por_equipe;
END $$
DELIMITER ;

-- 5: listar os tickets que têm quantidade de relatórios técnicos maior do que a média geral
DELIMITER $$
CREATE PROCEDURE sp_tickets_acima_media_relatorios()
BEGIN
    SELECT t.id AS ticket_id, t.titulo, COUNT(r.id) AS qtd_relatorios
    FROM tickets t
    INNER JOIN relatorios r ON r.ticket_id = t.id
    GROUP BY t.id, t.titulo
    HAVING COUNT(r.id) > (
        SELECT AVG(contagem)
        FROM (
            SELECT COUNT(id) AS contagem
            FROM relatorios
            GROUP BY ticket_id
        ) AS media_relatorios
    );
END $$
DELIMITER ;

-- 6: percorrer com um Cursor os tickets abertos com SLA vencido e atualizar prioridade para 'CRITICA'
DELIMITER $$
CREATE PROCEDURE sp_atualizar_prioridade_atrasados_cursor()
BEGIN
    DECLARE v_id VARCHAR(36);
    DECLARE v_fim INT DEFAULT 0;

    DECLARE cur_atrasados CURSOR FOR
        SELECT id FROM tickets
        WHERE status != 'ENCERRADO' AND sla_em < NOW();

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fim = 1;

    OPEN cur_atrasados;

    loop_tickets: LOOP
        FETCH cur_atrasados INTO v_id;
        IF v_fim = 1 THEN
            LEAVE loop_tickets;
        END IF;

        UPDATE tickets
        SET prioridade = 'CRITICA'
        WHERE id = v_id;
    END LOOP loop_tickets;

    CLOSE cur_atrasados;
END $$
DELIMITER ;