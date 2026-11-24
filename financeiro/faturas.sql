-- =============================================================
-- Contexto FINANCEIRO  |  SGBD: PostgreSQL (relacional, ACID)
-- Foco: consistencia e transacoes
-- Executar com: psql -f financeiro/faturas.sql
-- =============================================================

DROP TABLE IF EXISTS faturas;

CREATE TABLE faturas (
    id          SERIAL PRIMARY KEY,
    cliente     VARCHAR(100)   NOT NULL,
    pedido_id   VARCHAR(20)    NOT NULL UNIQUE,  -- id do pedido que veio do contexto de Vendas
    valor       NUMERIC(12, 2) NOT NULL CHECK (valor > 0),
    status      VARCHAR(20)    NOT NULL DEFAULT 'EMITIDA'
                CHECK (status IN ('EMITIDA', 'PAGA', 'CANCELADA')),
    emitida_em  TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Insercao dos 2 registros dentro de uma transacao:
-- ou as duas faturas sao gravadas, ou nenhuma.
BEGIN;
INSERT INTO faturas (cliente, pedido_id, valor, status) VALUES
    ('Ana Souza',     'PED-1001', 2499.90, 'PAGA'),
    ('Bruno Almeida', 'PED-1002',   89.90, 'EMITIDA');
COMMIT;

-- Consulta pedida: valor total faturado
SELECT SUM(valor) AS total_faturado FROM faturas;
-- Resultado esperado: 2589.80

-- Extra: total por status
SELECT status, COUNT(*) AS quantidade, SUM(valor) AS total
FROM faturas
GROUP BY status
ORDER BY status;
