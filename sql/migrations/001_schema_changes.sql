-- 001_schema_changes.sql
-- Migração sugerida para o schema do projeto ADMG_app (Supabase/Postgres)
-- IMPORTANTE: leia as seções "CHECKS" antes de rodar cada bloco.
-- Execute cada bloco separadamente no SQL editor do Supabase. Faça backup antes.

-- ==================================================
-- 0) BACKUP / PRECAUÇÕES
-- Faça backup do schema/dados antes de rodar qualquer alteração.
-- Você pode usar o Dashboard do Supabase para exportar backup ou usar pg_dump localmente.
-- ==================================================

-- ==================================================
-- 1) CHECKS: procurar NULLs e duplicados em colunas id (execute e confirme resultado)
-- Substitua <table> por cada tabela com id inteiro.
-- ==================================================
-- Exemplos (execute para cada tabela listada abaixo):
-- aviso, falarcommesario, leitura_atual, louvor, membros, pedidodeoracao, setor, usuario

-- Verificar NULLs na coluna id
SELECT 'membros' AS tabela, count(*) AS null_ids FROM membros WHERE id IS NULL;
SELECT 'aviso' AS tabela, count(*) AS null_ids FROM aviso WHERE id IS NULL;
SELECT 'falarcommesario' AS tabela, count(*) AS null_ids FROM falarcommesario WHERE id IS NULL;
SELECT 'leitura_atual' AS tabela, count(*) AS null_ids FROM leitura_atual WHERE id IS NULL;
SELECT 'louvor' AS tabela, count(*) AS null_ids FROM louvor WHERE id IS NULL;
SELECT 'pedidodeoracao' AS tabela, count(*) AS null_ids FROM pedidodeoracao WHERE id IS NULL;
SELECT 'setor' AS tabela, count(*) AS null_ids FROM setor WHERE id IS NULL;
SELECT 'usuario' AS tabela, count(*) AS null_ids FROM usuario WHERE id IS NULL;

-- Verificar duplicados em id
SELECT 'membros' AS tabela, id, count(*) FROM membros GROUP BY id HAVING count(*) > 1;
SELECT 'aviso' AS tabela, id, count(*) FROM aviso GROUP BY id HAVING count(*) > 1;
-- Repita para as outras tabelas conforme necessário

-- ==================================================
-- 2) CRIAR SEQUENCES E PKs para tabelas com id inteiro
-- Execute APÓS verificar que não há NULLs/duplicados.
-- WARNING: se já existirem PKs, esses comandos podem falhar. Verifique "
-- ALTER TABLE ... ADD CONSTRAINT ..." apenas se não houver PK.
-- ==================================================

-- Exemplo para membros
CREATE SEQUENCE IF NOT EXISTS membros_id_seq;
ALTER TABLE membros ALTER COLUMN id SET DEFAULT nextval('membros_id_seq');
ALTER SEQUENCE membros_id_seq OWNED BY membros.id;
-- Adicionar PK somente se ainda não existir
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint c JOIN pg_class t ON c.conrelid = t.oid
    WHERE c.contype = 'p' AND t.relname = 'membros'
  ) THEN
    ALTER TABLE membros ADD CONSTRAINT membros_pkey PRIMARY KEY (id);
  END IF;
END$$;

-- Repita para outras tabelas inteiras (ex.: aviso, falarcommesario, leitura_atual, louvor, pedidodeoracao, setor, usuario)

-- aviso
CREATE SEQUENCE IF NOT EXISTS aviso_id_seq;
ALTER TABLE aviso ALTER COLUMN id SET DEFAULT nextval('aviso_id_seq');
ALTER SEQUENCE aviso_id_seq OWNED BY aviso.id;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON c.conrelid = t.oid WHERE c.contype = 'p' AND t.relname = 'aviso') THEN ALTER TABLE aviso ADD CONSTRAINT aviso_pkey PRIMARY KEY (id); END IF; END$$;

-- falarcommesario
CREATE SEQUENCE IF NOT EXISTS falarcommesario_id_seq;
ALTER TABLE falarcommesario ALTER COLUMN id SET DEFAULT nextval('falarcommesario_id_seq');
ALTER SEQUENCE falarcommesario_id_seq OWNED BY falarcommesario.id;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON c.conrelid = t.oid WHERE c.contype = 'p' AND t.relname = 'falarcommesario') THEN ALTER TABLE falarcommesario ADD CONSTRAINT falarcommesario_pkey PRIMARY KEY (id); END IF; END$$;

-- leitura_atual
CREATE SEQUENCE IF NOT EXISTS leitura_atual_id_seq;
ALTER TABLE leitura_atual ALTER COLUMN id SET DEFAULT nextval('leitura_atual_id_seq');
ALTER SEQUENCE leitura_atual_id_seq OWNED BY leitura_atual.id;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON c.conrelid = t.oid WHERE c.contype = 'p' AND t.relname = 'leitura_atual') THEN ALTER TABLE leitura_atual ADD CONSTRAINT leitura_atual_pkey PRIMARY KEY (id); END IF; END$$;

-- louvor
CREATE SEQUENCE IF NOT EXISTS louvor_id_seq;
ALTER TABLE louvor ALTER COLUMN id SET DEFAULT nextval('louvor_id_seq');
ALTER SEQUENCE louvor_id_seq OWNED BY louvor.id;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON c.conrelid = t.oid WHERE c.contype = 'p' AND t.relname = 'louvor') THEN ALTER TABLE louvor ADD CONSTRAINT louvor_pkey PRIMARY KEY (id); END IF; END$$;

-- pedidodeoracao
CREATE SEQUENCE IF NOT EXISTS pedidodeoracao_id_seq;
ALTER TABLE pedidodeoracao ALTER COLUMN id SET DEFAULT nextval('pedidodeoracao_id_seq');
ALTER SEQUENCE pedidodeoracao_id_seq OWNED BY pedidodeoracao.id;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON c.conrelid = t.oid WHERE c.contype = 'p' AND t.relname = 'pedidodeoracao') THEN ALTER TABLE pedidodeoracao ADD CONSTRAINT pedidodeoracao_pkey PRIMARY KEY (id); END IF; END$$;

-- setor
CREATE SEQUENCE IF NOT EXISTS setor_id_seq;
ALTER TABLE setor ALTER COLUMN id SET DEFAULT nextval('setor_id_seq');
ALTER SEQUENCE setor_id_seq OWNED BY setor.id;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON c.conrelid = t.oid WHERE c.contype = 'p' AND t.relname = 'setor') THEN ALTER TABLE setor ADD CONSTRAINT setor_pkey PRIMARY KEY (id); END IF; END$$;

-- usuario
CREATE SEQUENCE IF NOT EXISTS usuario_id_seq;
ALTER TABLE usuario ALTER COLUMN id SET DEFAULT nextval('usuario_id_seq');
ALTER SEQUENCE usuario_id_seq OWNED BY usuario.id;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON c.conrelid = t.oid WHERE c.contype = 'p' AND t.relname = 'usuario') THEN ALTER TABLE usuario ADD CONSTRAINT usuario_pkey PRIMARY KEY (id); END IF; END$$;

-- ==================================================
-- 3) Transacoes: UUID default + PK
-- ==================================================
-- Configurar default uuid (usa pgcrypto/gen_random_uuid). Supabase costuma ter pgcrypto.
ALTER TABLE transacoes ALTER COLUMN id SET DEFAULT gen_random_uuid();
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON c.conrelid = t.oid WHERE c.contype = 'p' AND t.relname = 'transacoes') THEN ALTER TABLE transacoes ADD CONSTRAINT transacoes_pkey PRIMARY KEY (id); END IF; END$$;

-- Se gen_random_uuid não existir, pode usar uuid_generate_v4() se a extensão uuid-ossp estiver disponível.

-- ==================================================
-- 4) Defaults para timestamps
-- ==================================================
ALTER TABLE transacoes ALTER COLUMN created_at SET DEFAULT now();
-- membros
ALTER TABLE membros ALTER COLUMN data_cadastro SET DEFAULT now();
ALTER TABLE membros ALTER COLUMN data_atualizacao SET DEFAULT now();
-- leitura_atual
ALTER TABLE leitura_atual ALTER COLUMN atualizado_em SET DEFAULT now();
-- aviso, louvor, pedidodeoracao: se desejar, set default now() on data
ALTER TABLE aviso ALTER COLUMN data SET DEFAULT now();
ALTER TABLE louvor ALTER COLUMN data SET DEFAULT now();
ALTER TABLE pedidodeoracao ALTER COLUMN data SET DEFAULT now();

-- ==================================================
-- 5) Índices e UNIQUEs
-- Ajuste conforme regras do seu negócio. Verifique duplicatas antes.
-- ==================================================
-- Exemplo: membros.codigo_membro UNIQUE
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'membros_codigo_unq') THEN
    ALTER TABLE membros ADD CONSTRAINT membros_codigo_unq UNIQUE (codigo_membro);
  END IF;
END$$;

-- índices únicos para cpf / email (somente se desejar e após checar duplicatas)
CREATE UNIQUE INDEX IF NOT EXISTS membros_cpf_unq ON membros (cpf);
CREATE UNIQUE INDEX IF NOT EXISTS membros_email_unq ON membros (email);

-- setor.nome unique
CREATE UNIQUE INDEX IF NOT EXISTS setor_nome_unq ON setor (nome);

-- índices para transacoes
CREATE INDEX IF NOT EXISTS idx_transacoes_usuario_id ON transacoes (usuario_id);
CREATE INDEX IF NOT EXISTS idx_transacoes_created_at ON transacoes (created_at);

-- ==================================================
-- 6) Ajuste tipo para transacoes.valor
-- ==================================================
-- Use TYPE numeric(12,2) para valores monetários (ajuste conforme necessidade)
ALTER TABLE transacoes ALTER COLUMN valor TYPE numeric(12,2);

-- ==================================================
-- 7) Foreign Keys
-- Garantir FK transacoes.usuario_id -> usuario.id
-- ==================================================
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints tc
    WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'transacoes' AND tc.constraint_name = 'fk_transacoes_usuario'
  ) THEN
    ALTER TABLE transacoes ADD CONSTRAINT fk_transacoes_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE SET NULL;
  END IF;
END$$;

-- ==================================================
-- 8) Migrar usuario.setor (texto) para relação por id (opcional)
-- Se quiser relacionar usuario a tabela setor por id, siga estes passos:
-- 1) adicionar coluna usuario.setor_id
-- 2) popular via UPDATE (matching por nome)
-- 3) criar FK
-- 4) remover coluna textual (opcional)
-- ==================================================
-- 1) adicionar coluna
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS setor_id integer;

-- 2) popular (executar somente se você já possui correspondências entre usuário.setor (nome) e setor.nome)
UPDATE usuario u SET setor_id = s.id FROM setor s WHERE u.setor = s.nome;

-- 3) criar FK
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints tc
    WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'usuario' AND tc.constraint_name = 'fk_usuario_setor'
  ) THEN
    ALTER TABLE usuario ADD CONSTRAINT fk_usuario_setor FOREIGN KEY (setor_id) REFERENCES setor(id) ON DELETE SET NULL;
  END IF;
END$$;

-- 4) (opcional) remover coluna textual após checar dados
-- ALTER TABLE usuario DROP COLUMN setor;

-- ==================================================
-- 9) Renomear coluna com nome estranho: louvor.louvor_ -> louvor.conteudo
-- Só execute se a coluna existir e não quebrar o app
-- ==================================================
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='louvor' AND column_name='louvor_') THEN
    ALTER TABLE louvor RENAME COLUMN louvor_ TO conteudo;
  END IF;
END$$;

-- ==================================================
-- 10) Segurança: senhas (usuario.senha)
-- Recomenda-se NÃO armazenar senhas em texto. Em vez disso, usar Supabase Auth.
-- Se for migrar, crie coluna auth_id (uuid) e vincule ao usuário do Auth.
-- Não execute comandos que exijam manipular senhas em plain text aqui.
-- ==================================================
-- Exemplo: adicionar coluna auth_id para vincular ao Supabase Auth
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS auth_id uuid;
CREATE UNIQUE INDEX IF NOT EXISTS usuario_auth_id_idx ON usuario (auth_id);

-- ==================================================
-- 10.b) Adicionar colunas RAW para datas de membros
-- Estas colunas guardam a string original inserida pelo usuário (ex.: '45/45/45')
-- para auditoria e facilitar correções posteriores, mantendo a coluna date limpa.
-- ==================================================
ALTER TABLE membros ADD COLUMN IF NOT EXISTS data_nascimento_raw text;
ALTER TABLE membros ADD COLUMN IF NOT EXISTS data_conversao_raw text;
ALTER TABLE membros ADD COLUMN IF NOT EXISTS data_batismo_raw text;

-- ==================================================
-- 11) Row Level Security (RLS) - TEMPLATE
-- Habilitar e criar políticas é sensível à sua lógica de roles. Exemplo mínimo:
-- Execute somente se souber como sua aplicação usa roles e claims.
-- ==================================================
-- Exemplo: habilitar RLS para membros (apenas como template)
-- ALTER TABLE membros ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY select_membros_autenticados ON membros
--   FOR SELECT
--   USING (auth.role() = 'authenticated');

-- ==================================================
-- 12) Verificações pós-migração
-- Checar contagens e integridade após alterações
SELECT 'contagem_membros' AS info, count(*) FROM membros;
SELECT 'contagem_usuario' AS info, count(*) FROM usuario;
SELECT 'transacoes_sem_usuario' AS info, count(*) FROM transacoes WHERE usuario_id IS NULL;

-- FIM DO SCRIPT
-- Execute os blocos em ordem: CHECKS -> SEQUENCES/PKs -> DEFAULTS -> INDICES -> FKs -> renomeações.
-- Se ocorrerem erros, pare e me traga a mensagem para eu orientar a correção.
-- Remeça, revise e backup antes de qualquer alteração destrutiva.
