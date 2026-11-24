-- =============================================================
-- BONUS - Transacao financeira que FALHA quando o saldo
-- do cliente nao e suficiente (BEGIN / COMMIT / ROLLBACK)
-- SGBD: PostgreSQL
-- Executar com: psql -f financeiro/bonus_transacao.sql
-- (os erros dos casos 2 e 3 sao ESPERADOS: e a regra funcionando)
-- =============================================================

DROP TABLE IF EXISTS contas;

CREATE TABLE contas (
    id       SERIAL PRIMARY KEY,
    cliente  VARCHAR(100)   NOT NULL UNIQUE,
    -- Regra de negocio garantida pelo proprio banco:
    -- nenhuma conta pode ficar com saldo negativo.
    saldo    NUMERIC(12, 2) NOT NULL CHECK (saldo >= 0)
);

INSERT INTO contas (cliente, saldo) VALUES
    ('Ana Souza',     500.00),
    ('Bruno Almeida', 100.00);

-- -------------------------------------------------------------
-- CASO 1: saldo suficiente -> COMMIT
-- Ana paga 200,00 para Bruno.
-- -------------------------------------------------------------
BEGIN;
UPDATE contas SET saldo = saldo - 200.00 WHERE cliente = 'Ana Souza';
UPDATE contas SET saldo = saldo + 200.00 WHERE cliente = 'Bruno Almeida';
COMMIT;
-- Resultado: Ana = 300,00 | Bruno = 300,00

-- -------------------------------------------------------------
-- CASO 2: saldo insuficiente -> erro -> ROLLBACK
-- Bruno (saldo 300,00) tenta pagar 1000,00 para Ana.
-- O primeiro UPDATE deixaria o saldo em -700,00 e viola o CHECK.
-- O PostgreSQL aborta a transacao: o segundo UPDATE e ignorado
-- e o ROLLBACK desfaz tudo. Ninguem recebe dinheiro que nao existe.
-- -------------------------------------------------------------
BEGIN;
UPDATE contas SET saldo = saldo - 1000.00 WHERE cliente = 'Bruno Almeida';
-- ERROR: new row for relation "contas" violates check constraint "contas_saldo_check"
UPDATE contas SET saldo = saldo + 1000.00 WHERE cliente = 'Ana Souza';
-- ERROR: current transaction is aborted
ROLLBACK;

-- -------------------------------------------------------------
-- CASO 3: a mesma regra escrita de forma explicita (PL/pgSQL).
-- Confere o saldo antes de debitar e lanca uma excecao se nao
-- for suficiente; a excecao desfaz o bloco inteiro (rollback).
-- -------------------------------------------------------------
DO $$
DECLARE
    v_saldo NUMERIC(12, 2);
BEGIN
    SELECT saldo INTO v_saldo
    FROM contas
    WHERE cliente = 'Bruno Almeida'
    FOR UPDATE;  -- trava a linha para evitar corrida entre transacoes

    IF v_saldo < 1000.00 THEN
        RAISE EXCEPTION 'Saldo insuficiente: disponivel %, solicitado %', v_saldo, 1000.00;
    END IF;

    UPDATE contas SET saldo = saldo - 1000.00 WHERE cliente = 'Bruno Almeida';
    UPDATE contas SET saldo = saldo + 1000.00 WHERE cliente = 'Ana Souza';
END $$;
-- ERROR: Saldo insuficiente: disponivel 300.00, solicitado 1000.00

-- Saldos continuam corretos: Ana = 300,00 | Bruno = 300,00
SELECT cliente, saldo FROM contas ORDER BY id;
