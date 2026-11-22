# =============================================================================
# 3ª Avaliação de BDR - FATEC SJC
# Parte 5 - Implementação de uma funcionalidade do projeto conectada ao SQLite
# Funcionalidade: Abertura de Ticket com alocação de equipe e contagem no projeto
# Consome 1 Function (fn_total_tickets_projeto) e 1 Procedure (sp_abrir_ticket)
# =============================================================================

import sqlite3
import json

DB_PATH = "/home/vitor/fatec/bd/banco_altave.sqlite"

def fn_total_tickets_projeto(projeto_id):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    total = cur.execute(
        "SELECT COUNT(*) FROM tickets WHERE projeto_id = ?", (projeto_id,)
    ).fetchone()[0]
    conn.close()
    return total

def sp_abrir_ticket(conn, ticket_id, titulo, descricao, categoria, prioridade, sla_em, projeto_id, aberto_por_id, equipe_id):
    cur = conn.cursor()
    cur.execute("DELETE FROM ticket_equipes WHERE ticket_id = ?", (ticket_id,))
    cur.execute("DELETE FROM historico_ticket WHERE ticket_id = ?", (ticket_id,))
    cur.execute("DELETE FROM tickets WHERE id = ?", (ticket_id,))

    # 1. Insere o ticket (dispara também a trigger trg_historico_novo_ticket)
    cur.execute("""
        INSERT INTO tickets (id, titulo, descricao, categoria, prioridade, status, sla_em, projeto_id, aberto_por_id)
        VALUES (?, ?, ?, ?, ?, 'NAO_INICIADO', ?, ?, ?)
    """, (ticket_id, titulo, descricao, categoria, prioridade, sla_em, projeto_id, aberto_por_id))

    # 2. Aloca a equipe na tabela ticket_equipes
    cur.execute("""
        INSERT INTO ticket_equipes (id, ticket_id, equipe_id)
        VALUES (?, ?, ?)
    """, ("te-" + ticket_id, ticket_id, equipe_id))

    conn.commit()
    return cur.execute(
        "SELECT ticket_id, titulo, categoria, prioridade, status, projeto, cliente FROM vw_resumo_tickets WHERE ticket_id = ?",
        (ticket_id,)
    ).fetchone()

def executar_funcionalidade():
    conn = sqlite3.connect(DB_PATH)
    conn.create_function("fn_total_tickets_projeto", 1, fn_total_tickets_projeto)

    # 1. Executa a procedure sp_abrir_ticket
    novo_ticket = sp_abrir_ticket(
        conn,
        ticket_id="tkt-53",
        titulo="Chamado #53 - Manutenção Câmera Setor 03",
        descricao="Câmera sem sinal de vídeo após chuva forte",
        categoria="MANUTENCAO",
        prioridade="ALTA",
        sla_em="2026-11-25 18:00:00",
        projeto_id="proj-03",
        aberto_por_id="usr-15",
        equipe_id="eq-03"
    )

    # 2. Consome a function fn_total_tickets_projeto no SQLite
    cur = conn.cursor()
    total_tickets = cur.execute(
        "SELECT fn_total_tickets_projeto('proj-03')"
    ).fetchone()[0]

    resultado = {
        "mensagem": "Ticket criado com sucesso no banco SQLite",
        "procedure_utilizada": "sp_abrir_ticket",
        "function_utilizada": "fn_total_tickets_projeto",
        "ticket_criado": {
            "id": novo_ticket[0],
            "titulo": novo_ticket[1],
            "categoria": novo_ticket[2],
            "prioridade": novo_ticket[3],
            "status": novo_ticket[4],
            "projeto": novo_ticket[5],
            "cliente": novo_ticket[6]
        },
        "total_tickets_no_projeto": total_tickets
    }

    conn.close()
    print(json.dumps(resultado, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    executar_funcionalidade()
