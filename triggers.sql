-- TRIGGERS
USE av3_bd;

-- 1: inserir automaticamente um registro de auditoria na tabela atividades_conta sempre que um novo usuário for cadastrado
DELIMITER $$
CREATE TRIGGER trg_log_novo_usuario
AFTER INSERT ON usuarios
FOR EACH ROW
BEGIN
    INSERT INTO atividades_conta (id, tipo, descricao, criado_em, usuario_id)
    VALUES (
        CONCAT('ativ-', LOWER(HEX(RANDOM_BYTES(4)))),
        'CRIACAO',
        CONCAT('Novo usuário cadastrado: ', NEW.nome, ' (', NEW.cargo, ')'),
        CURRENT_TIMESTAMP,
        NEW.id
    );
END $$
DELIMITER ;

-- 2: registrar automaticamente em atividades_conta quando um usuário tiver seu campo ativo alterado
DELIMITER $$
CREATE TRIGGER trg_log_inativar_usuario
AFTER UPDATE ON usuarios
FOR EACH ROW
BEGIN
    IF OLD.ativo != NEW.ativo THEN
        INSERT INTO atividades_conta (id, tipo, descricao, criado_em, usuario_id)
        VALUES (
            CONCAT('ativ-', LOWER(HEX(RANDOM_BYTES(4)))),
            CASE WHEN NEW.ativo = 0 THEN 'INATIVACAO' ELSE 'REATIVACAO' END,
            CONCAT('Status do usuário ', NEW.nome, ' alterado para ativo = ', NEW.ativo),
            CURRENT_TIMESTAMP,
            NEW.id
        );
    END IF;
END $$
DELIMITER ;

-- 3: gravar automaticamente o evento 'TICKET_ABERTO' na tabela historico_ticket quando um ticket é criado
DELIMITER $$
CREATE TRIGGER trg_historico_novo_ticket
AFTER INSERT ON tickets
FOR EACH ROW
BEGIN
    INSERT INTO historico_ticket (id, evento, descricao, criado_em, ticket_id, usuario_id, equipe_id, inicio_equipe_id)
    VALUES (
        CONCAT('hist-', LOWER(HEX(RANDOM_BYTES(4)))),
        'TICKET_ABERTO',
        CONCAT('Ticket aberto com prioridade ', NEW.prioridade),
        CURRENT_TIMESTAMP,
        NEW.id,
        NEW.aberto_por_id,
        (SELECT equipe_id FROM usuarios WHERE id = NEW.aberto_por_id),
        NULL
    );
END $$
DELIMITER ;

-- 4: sempre que o status de um ticket for atualizado, gravar automaticamente no histórico qual era o status anterior e qual é o novo status
DELIMITER $$
CREATE TRIGGER trg_historico_mudanca_status
AFTER UPDATE ON tickets
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO historico_ticket (id, evento, descricao, criado_em, ticket_id, usuario_id, equipe_id, inicio_equipe_id)
        VALUES (
            CONCAT('hist-', LOWER(HEX(RANDOM_BYTES(4)))),
            'MUDANCA_STATUS',
            CONCAT('Status alterado de ', OLD.status, ' para ', NEW.status),
            CURRENT_TIMESTAMP,
            NEW.id,
            NEW.responsavel_id,
            (SELECT equipe_id FROM usuarios WHERE id = NEW.responsavel_id),
            NULL
        );
    END IF;
END $$
DELIMITER ;

-- 5: quando um técnico enviar um relatório na tabela relatorios, registrar o evento no histórico do ticket e mudar o status do ticket de 'NAO_INICIADO' para 'EM_ANDAMENTO'
DELIMITER $$
CREATE TRIGGER trg_historico_novo_relatorio
AFTER INSERT ON relatorios
FOR EACH ROW
BEGIN
    INSERT INTO historico_ticket (id, evento, descricao, criado_em, ticket_id, usuario_id, equipe_id, inicio_equipe_id)
    VALUES (
        CONCAT('hist-', LOWER(HEX(RANDOM_BYTES(4)))),
        'RELATORIO_ADICIONADO',
        CONCAT('Relatório registrado pelo técnico ', NEW.autor_id),
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
END $$
DELIMITER ;

-- 6: impedir que um ticket seja alterado para 'ENCERRADO' caso não exista nenhum relatório técnico vinculado a ele na tabela relatorios
DELIMITER $$
CREATE TRIGGER trg_bloquear_encerramento_sem_relatorio
BEFORE UPDATE ON tickets
FOR EACH ROW
BEGIN
    IF NEW.status = 'ENCERRADO'
       AND OLD.status != 'ENCERRADO'
       AND (SELECT COUNT(*) FROM relatorios WHERE ticket_id = NEW.id) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Nao e permitido encerrar um ticket sem relatorio tecnico cadastrado.';
    END IF;
END $$
DELIMITER ;