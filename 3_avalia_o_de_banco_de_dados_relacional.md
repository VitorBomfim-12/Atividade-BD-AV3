# 3ª Avaliação de Banco de Dados Relacional (BDR)

## Metadados da Avaliação
- **Instituição:** FATEC São José dos Campos - Centro Paula Souza
- **Disciplina:** Banco de Dados Relacional (BDR)
- **Período:** 2º Semestre de 2026
- **Data do Documento:** 22/10/2026
- **Data Limite de Entrega (Teams):** 23/11/2026
- **Datas de Apresentação:** 23/11/2026, 26/11/2026 e 30/11/2026 *(Nota: A ordem será definida posteriormente. É possível antecipar a apresentação caso a dupla finalize antes do prazo).*

---

## Regras Gerais e Entregáveis
1. **Formação:** Pode ser realizada individualmente ou em dupla.
2. **Escopo/Tema:** Deve utilizar o tema proposto para o Projeto Integrador (API).
3. **Estrutura da Entrega:**
   - Um **documento principal** consolidando todo o trabalho.
   - **Arquivos separados** (devidamente referenciados no documento principal) para:
     - Script DDL (criação das tabelas).
     - Script DML (inserção de dados).
     - Dicionário de dados.

---

## Requisitos Técnicos por Etapa

### Parte 1: Modelos de Banco de Dados
Devem ser incluídos no documento:
- [ ] **Modelo Conceitual** (desenvolvido utilizando a ferramenta BRModelo).
- [ ] **Modelo Lógico** (mapeamento relacional).

### Parte 2: Inserção de Dados (DML)
*(Nota: No documento original consta como "Parte 3 - Inserir as linhas", mas sequencialmente corresponde à Parte 2).*
- [ ] Popular **cada tabela** com no mínimo **50 registros** (`INSERT INTO`).
- **Ferramentas permitidas:** Geradores de dados fictícios (ex: Mockaroo) ou scripts SQL manuais.
- **Exceção:** Tabelas de domínio/lookup com quantidade fixa e reduzida de registros (ex: tabela de níveis/perfis de usuário) podem ter menos de 50 registros.

### Parte 3: Programação em Banco de Dados
Desenvolver os seguintes objetos no banco de dados:
- [ ] **6 Stored Procedures**
- [ ] **6 Functions**
- [ ] **6 Triggers**

**Requisitos de Complexidade:**
A programação deve ser bem elaborada, aplicando obrigatoriamente os conceitos vistos em aula:
- Cursores (`CURSOR`)
- Visões (`VIEW`)
- Junções (`INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`)
- Agrupamentos (`GROUP BY`) e funções de agregação/grupo (`COUNT`, `SUM`, `AVG`, `MAX`, `MIN`, etc.)
- Subconsultas (`Subqueries`)

**Formato de Documentação Obrigatório (para cada um dos 18 itens acima):**
1. **Problema:** Descrição clara do problema de negócio que o código resolve.
2. **Código:** O script SQL completo de criação.
3. **Evidência:** O retorno obtido na execução (print/captura de tela do resultado).

### Parte 4: Documentação do Banco de Dados (Dicionário de Dados)
Criar a documentação estruturada (em arquivo separado e referenciado) contendo para todas as tabelas do projeto:
- [ ] Nome e descrição dos campos/colunas.
- [ ] Tipos de dados e tamanhos.
- [ ] Identificação de Chaves Primárias (`PK`).
- [ ] Identificação de Chaves Estrangeiras (`FK`) e seus relacionamentos.
- [ ] Restrições (`Constraints`: `NOT NULL`, `UNIQUE`, `CHECK`, `DEFAULT`, etc.).

### Parte 5: Integração com o Projeto (API)
- [ ] Selecionar **1 funcionalidade** do projeto API.
- [ ] Implementar a integração desta funcionalidade conectando a API ao banco de dados desenvolvido nesta avaliação.
- [ ] A funcionalidade escolhida deve consumir obrigatoriamente pelo menos **1 Function** e **1 Stored Procedure** criadas na Parte 3.