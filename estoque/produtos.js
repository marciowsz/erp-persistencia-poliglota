// =============================================================
// Contexto ESTOQUE  |  SGBD: MongoDB (NoSQL - documentos)
// Foco: flexibilidade de esquema
// Executar com: mongosh estoque/produtos.js
// =============================================================

db = db.getSiblingDB("estoque");
db.produtos.drop();

// Produtos com atributos completamente diferentes na MESMA colecao.
// Um celular tem dezenas de especificacoes; uma camiseta tem poucas.
// No modelo relacional isso exigiria tabelas extras e JOINs.
db.produtos.insertMany([
  {
    sku: "CEL-001",
    nome: "Smartphone Galaxy X",
    categoria: "eletronicos",
    preco: 2499.9,
    quantidade: 15,
    especificacoes: {
      tela: { tamanho_pol: 6.5, tipo: "AMOLED", resolucao: "2400x1080" },
      bateria_mah: 5000,
      armazenamento_gb: 256,
      memoria_ram_gb: 8,
      cameras: [
        { posicao: "traseira", megapixels: 50 },
        { posicao: "traseira", megapixels: 12 },
        { posicao: "frontal", megapixels: 10 }
      ],
      conectividade: ["5G", "Wi-Fi 6", "Bluetooth 5.3", "NFC"]
    }
  },
  {
    sku: "CAM-001",
    nome: "Camiseta Basica",
    categoria: "vestuario",
    preco: 89.9,
    quantidade: 120,
    especificacoes: {
      tamanho: "M",
      cor: "preta",
      material: "100% algodao"
    }
  }
]);

// Indice unico no SKU (identificador usado pelos outros contextos)
db.produtos.createIndex({ sku: 1 }, { unique: true });

// ---- Consultas que mostram a flexibilidade do esquema ----
print("--- Todos os produtos ---");
printjson(db.produtos.find({}, { _id: 0, sku: 1, nome: 1, especificacoes: 1 }).toArray());

print("--- Produtos com bateria >= 4500 mAh (campo que so existe no celular) ---");
printjson(db.produtos.find({ "especificacoes.bateria_mah": { $gte: 4500 } }, { _id: 0, nome: 1 }).toArray());

print("--- Produtos que possuem o atributo 'cor' (so a camiseta) ---");
printjson(db.produtos.find({ "especificacoes.cor": { $exists: true } }, { _id: 0, nome: 1, "especificacoes.cor": 1 }).toArray());

// ---- Baixa de estoque (o que acontece quando uma venda e finalizada) ----
// O filtro quantidade >= 1 impede o estoque de ficar negativo.
db.produtos.updateOne(
  { sku: "CEL-001", quantidade: { $gte: 1 } },
  { $inc: { quantidade: -1 } }
);
print("--- Estoque do CEL-001 apos a venda ---");
printjson(db.produtos.findOne({ sku: "CEL-001" }, { _id: 0, sku: 1, quantidade: 1 }));

print("Total de produtos: " + db.produtos.countDocuments());
