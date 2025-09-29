-- Script de Criação da Tabela de Motos

CREATE TABLE IF NOT EXISTS motos (
    id_moto SERIAL PRIMARY KEY,
    placa VARCHAR(10) NOT NULL,
    chassi VARCHAR(50) NOT NULL,
    num_motor VARCHAR(50),
    id_modelo INT NOT NULL,
    id_patio INT NOT NULL
);

-- Comentário: A tabela "__EFMigrationsHistory" será criada automaticamente
-- pelo Entity Framework Core para controlar as versões das migrações aplicadas.