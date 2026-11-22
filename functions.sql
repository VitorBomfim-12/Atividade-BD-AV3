-- FUNCTIONS
USE av3_bd;

-- 1: retornar o total de tickets vinculados a um projeto específico
DELIMITER $$
CREATE FUNCTION fn_total_tickets_projeto(p_projeto_id VARCHAR(36))
RETURNS INT
READS SQL DATA
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM tickets
        WHERE projeto_id = p_projeto_id
    );
END $$
DELIMITER ;

-- 2: calcular a porcentagem de tickets que já estão com status ENCERRADO dentro de um projeto
DELIMITER $$
CREATE FUNCTION fn_percentual_concluidos_projeto(p_projeto_id VARCHAR(36))
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    RETURN (
        SELECT COALESCE(
            ROUND((SUM(CASE WHEN status = 'ENCERRADO' THEN 1.0 ELSE 0.0 END) / NULLIF(COUNT(*), 0)) * 100, 2),
            0.00
        )
        FROM tickets
        WHERE projeto_id = p_projeto_id
    );
END $$
DELIMITER ;

-- 3: verificar se um ticket foi entregue no prazo, com atraso, ou se ainda está dentro do prazo de SLA
DELIMITER $$
CREATE FUNCTION fn_verificar_sla_ticket(p_ticket_id VARCHAR(36))
RETURNS VARCHAR(30)
READS SQL DATA
BEGIN
    RETURN (
        SELECT CASE
            WHEN status = 'ENCERRADO' AND encerrado_em <= sla_em THEN 'ENCERRADO NO PRAZO'
            WHEN status = 'ENCERRADO' AND encerrado_em > sla_em THEN 'ENCERRADO COM ATRASO'
            WHEN sla_em < '2026-11-18 12:00:00' THEN 'ATRASADO'
            ELSE 'DENTRO DO PRAZO'
        END
        FROM tickets
        WHERE id = p_ticket_id
    );
END $$
DELIMITER ;

-- 4: contar quantos relatórios técnicos um colaborador já preencheu
DELIMITER $$
CREATE FUNCTION fn_total_relatorios_tecnico(p_usuario_id VARCHAR(36))
RETURNS INT
READS SQL DATA
BEGIN
    RETURN (
        SELECT COUNT(r.id)
        FROM usuarios u
        INNER JOIN relatorios r ON r.autor_id = u.id
        WHERE u.id = p_usuario_id
    );
END $$
DELIMITER ;

-- 5: buscar a data do primeiro ticket (MIN) e do último ticket (MAX) aberto para um cliente
DELIMITER $$
CREATE FUNCTION fn_datas_tickets_cliente(p_cliente_id VARCHAR(36))
RETURNS VARCHAR(100)
READS SQL DATA
BEGIN
    RETURN (
        SELECT COALESCE(
            CONCAT('Primeiro: ', SUBSTR(MIN(t.criado_em), 1, 10), ' | Ultimo: ', SUBSTR(MAX(t.criado_em), 1, 10)),
            'Sem tickets registrados'
        )
        FROM projetos p
        INNER JOIN tickets t ON t.projeto_id = p.id
        WHERE p.cliente_id = p_cliente_id
    );
END $$
DELIMITER ;

-- 6: verificar se a quantidade de tickets de uma equipe está 'ACIMA DA MEDIA' ou 'ABAIXO DA MEDIA'
DELIMITER $$
CREATE FUNCTION fn_comparar_equipe_media(p_equipe_id VARCHAR(36))
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    RETURN (
        SELECT CASE
            WHEN (SELECT COUNT(*) FROM ticket_equipes WHERE equipe_id = p_equipe_id) >= (
                SELECT COALESCE(AVG(c), 0)
                FROM (SELECT COUNT(*) AS c FROM ticket_equipes GROUP BY equipe_id) AS media_equipes
            ) THEN 'ACIMA DA MEDIA'
            ELSE 'ABAIXO DA MEDIA'
        END
    );
END $$
DELIMITER ;