# Vendas: carrinho no Redis

O arquivo `carrinho.redis` contém só comandos Redis, um por linha. O `redis-cli` não aceita comentários com `#`, por isso cada etapa é marcada com `ECHO`.

```bash
redis-cli < vendas/carrinho.redis
```

| Chave | Tipo | Conteúdo | TTL |
|---|---|---|---|
| `sessao:<id>` | Hash | `usuario_id`, `nome`, `criada_em` | 1800 s (30 min) |
| `carrinho:<id>` | Hash | `sku -> quantidade` | 1800 s (30 min) |

- `HSET`/`HGETALL` gravam e recuperam a sessão e o carrinho em O(1).
- `HINCRBY` altera a quantidade de forma atômica, sem ler e regravar.
- `EXPIRE`/`TTL` fazem o carrinho abandonado sumir sozinho, sem rotina de limpeza.
