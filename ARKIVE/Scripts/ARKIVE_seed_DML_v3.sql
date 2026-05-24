/*
==================================================================================
   PROJETO ARKIVE - MASTERING RELATIONAL AND NON-RELATIONAL DATABASE
  ──────────────────────────────────────────────────────────────────────────────
   Turma: 2TDSPO (Unidade Paulista)
   Equipe:
    - RM561408 — Gustavo Crevelari Monteiro Porto
    - RM561996 — Lucca de Araujo Gomes
    - RM561671 — Rafaela Ferreira Santos
    - RM566224 — Victor Sabelli Rocha Batista
  ──────────────────────────────────────────────────────────────────────────────
   ÍNDICE
  ──────────────────────────────────────────────────────────────────────────────
   # 0 ─  Preparação do ambiente - 'SETs' para interface;
   # 1 ─  Procedure de carga + registro de erros;
   # 2 ─  Procedures de carga para demais tabelas (22 tabelas = 22 subseções);
   # 3 ─  Chamadas de carga via procedures (22 procedures = 22 subseções);
  ──────────────────────────────────────────────────────────────────────────────
   PADRÃO DE EXCEÇÕES ADOTADO EM TODAS AS PROCEDURES:
  ──────────────────────────────────────────────────────────────────────────────
    1. WHEN DUP_VAL_ON_INDEX = violação de UNIQUE ou PRIMARY KEY — (ORA-00001)
    2. WHEN e_check_violado  = violação de constraint CHECK      — (ORA-02290)
    3. WHEN OTHERS           = captura genérica

   *Nota: Ao ocorrer qualquer exceção, 'usuário', 'nome da procedure', 'data da
   procedure', 'código da procedure' e 'mensagem da procedure' são gravados em
   "TB_ARKIVE_LOG_ERRO" (via AUTONOMOUS_TRANSACTION).
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================
*/
/*
==================================================================================
   # 0 — PREPARAÇÃO DO AMBIENTE
  ──────────────────────────────────────────────────────────────────────────────
*/
SET SERVEROUTPUT ON SIZE UNLIMITED;
SET VERIFY OFF;

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

/*
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================
   # 1 ─ REGISTRO COM PR_ARKIVE_REG_ERRO + CARGA EM TB_ARKIVE_LOG_ERRO;
  ──────────────────────────────────────────────────────────────────────────────
*/
CREATE OR REPLACE PROCEDURE
    PR_ARKIVE_REG_ERRO (p_nm_procedure IN VARCHAR2, p_cd_erro IN NUMBER, p_ds_mensagem IN VARCHAR2)
        IS PRAGMA AUTONOMOUS_TRANSACTION;

    e_dup_log EXCEPTION;
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_dup_log, -1);
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);

BEGIN
    INSERT INTO TB_ARKIVE_LOG_ERRO (NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES (SUBSTR(p_nm_procedure, 1, 100), USER, SYSDATE, p_cd_erro, SUBSTR(p_ds_mensagem, 1, 4000));
    COMMIT;

EXCEPTION
    WHEN e_dup_log THEN NULL;
    WHEN e_check_violado THEN NULL;
    WHEN OTHERS THEN NULL;
END PR_ARKIVE_REG_ERRO;
/
/*
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================
   # 2 — PROCEDURES DE CARGA DE DADOS (uma por tabela — 22 tabelas)
  ──────────────────────────────────────────────────────────────────────────────
*/
  -- ## 2.01 — TB_ARKIVE_ESPECIE
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_ESPECIE (
    p_nm_especie IN TB_ARKIVE_ESPECIE.NM_ESPECIE%TYPE,
    p_st_ativo IN TB_ARKIVE_ESPECIE.ST_ATIVO%TYPE DEFAULT 'S'
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_ESPECIE';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_ESPECIE (NM_ESPECIE, ST_ATIVO)
    VALUES (p_nm_especie, NVL(p_st_ativo, 'S'));
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Espécie duplicada [' || p_nm_especie || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [ST_ATIVO]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_ESPECIE;
/
  -- ## 2.02 — TB_ARKIVE_RACA
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_RACA (
    p_nm_raca IN TB_ARKIVE_RACA.NM_RACA%TYPE,
    p_id_especie IN TB_ARKIVE_RACA.ID_ESPECIE%TYPE,
    p_tp_porte IN TB_ARKIVE_RACA.TP_PORTE%TYPE DEFAULT NULL,
    p_st_ativo IN TB_ARKIVE_RACA.ST_ATIVO%TYPE DEFAULT 'S'
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_RACA';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_RACA (NM_RACA, ID_ESPECIE, TP_PORTE, ST_ATIVO)
    VALUES (p_nm_raca, p_id_especie, p_tp_porte, NVL(p_st_ativo, 'S'));
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Raça duplicada [' || p_nm_raca || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [TP_PORTE ou ST_ATIVO]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_RACA;
/
  -- ## 2.03 — TB_ARKIVE_RESPONSAVEL
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_RESPONSAVEL (
    p_nm_responsavel IN TB_ARKIVE_RESPONSAVEL.NM_RESPONSAVEL%TYPE,
    p_dc_cpf_rg IN TB_ARKIVE_RESPONSAVEL.DC_CPF_RG%TYPE,
    p_ds_email IN TB_ARKIVE_RESPONSAVEL.DS_EMAIL%TYPE DEFAULT NULL,
    p_nr_contato IN TB_ARKIVE_RESPONSAVEL.NR_CONTATO%TYPE DEFAULT NULL,
    p_tp_responsavel IN TB_ARKIVE_RESPONSAVEL.TP_RESPONSAVEL%TYPE,
    p_dt_cadastro IN TB_ARKIVE_RESPONSAVEL.DT_CADASTRO%TYPE DEFAULT SYSDATE,
    p_st_notificacao IN TB_ARKIVE_RESPONSAVEL.ST_NOTIFICACAO%TYPE DEFAULT 'S',
    p_st_ativo IN TB_ARKIVE_RESPONSAVEL.ST_ATIVO%TYPE DEFAULT 'S'
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_RESPONSAVEL';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_RESPONSAVEL (
        NM_RESPONSAVEL, DC_CPF_RG, DS_EMAIL, NR_CONTATO,
        TP_RESPONSAVEL, DT_CADASTRO, ST_NOTIFICACAO, ST_ATIVO
    ) VALUES (
        p_nm_responsavel, p_dc_cpf_rg, p_ds_email, p_nr_contato,
        p_tp_responsavel, NVL(p_dt_cadastro, SYSDATE),
        NVL(p_st_notificacao, 'S'), NVL(p_st_ativo, 'S')
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Documento duplicado [' || p_dc_cpf_rg || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [TP_RESPONSAVEL / ST_*]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_RESPONSAVEL;
/
  -- ## 2.04 — TB_ARKIVE_CLINICA
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_CLINICA (
    p_nm_clinica IN TB_ARKIVE_CLINICA.NM_CLINICA%TYPE,
    p_dc_cnpj IN TB_ARKIVE_CLINICA.DC_CNPJ%TYPE,
    p_ds_endereco IN TB_ARKIVE_CLINICA.DS_ENDERECO%TYPE DEFAULT NULL,
    p_nr_contato IN TB_ARKIVE_CLINICA.NR_CONTATO%TYPE DEFAULT NULL,
    p_ds_email IN TB_ARKIVE_CLINICA.DS_EMAIL%TYPE DEFAULT NULL,
    p_st_ativo IN TB_ARKIVE_CLINICA.ST_ATIVO%TYPE DEFAULT 'S'
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_CLINICA';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_CLINICA (
        NM_CLINICA, DC_CNPJ, DS_ENDERECO, NR_CONTATO, DS_EMAIL, ST_ATIVO
    ) VALUES (
        p_nm_clinica, p_dc_cnpj, p_ds_endereco,
        p_nr_contato, p_ds_email, NVL(p_st_ativo, 'S')
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'CNPJ duplicado [' || p_dc_cnpj || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [ST_ATIVO]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_CLINICA;
/
  -- ## 2.05 — TB_ARKIVE_RESPONSAVEL_CLINICA
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_RESP_CLINICA (
    p_id_responsavel IN TB_ARKIVE_RESPONSAVEL_CLINICA.ID_RESPONSAVEL%TYPE,
    p_id_clinica IN TB_ARKIVE_RESPONSAVEL_CLINICA.ID_CLINICA%TYPE,
    p_dt_vinculo IN TB_ARKIVE_RESPONSAVEL_CLINICA.DT_VINCULO%TYPE DEFAULT SYSDATE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_RESP_CLINICA';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_RESPONSAVEL_CLINICA (ID_RESPONSAVEL, ID_CLINICA, DT_VINCULO)
    VALUES (p_id_responsavel, p_id_clinica, NVL(p_dt_vinculo, SYSDATE));
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Vínculo duplicado [RESP ' || p_id_responsavel ||
            ' / CLINICA ' || p_id_clinica || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_RESP_CLINICA;
/
  -- ## 2.06 — TB_ARKIVE_VETERINARIO
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_VETERINARIO (
    p_nm_veterinario IN TB_ARKIVE_VETERINARIO.NM_VETERINARIO%TYPE,
    p_dc_crmv IN TB_ARKIVE_VETERINARIO.DC_CRMV%TYPE,
    p_ds_especialidade IN TB_ARKIVE_VETERINARIO.DS_ESPECIALIDADE%TYPE DEFAULT NULL,
    p_ds_email IN TB_ARKIVE_VETERINARIO.DS_EMAIL%TYPE DEFAULT NULL,
    p_id_clinica IN TB_ARKIVE_VETERINARIO.ID_CLINICA%TYPE DEFAULT NULL,
    p_st_ativo IN TB_ARKIVE_VETERINARIO.ST_ATIVO%TYPE DEFAULT 'S'
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_VETERINARIO';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_VETERINARIO (
        NM_VETERINARIO, DC_CRMV, DS_ESPECIALIDADE, DS_EMAIL, ID_CLINICA, ST_ATIVO
    ) VALUES (
        REGEXP_REPLACE(TRIM(p_nm_veterinario),'^[[:space:]]*Dr(a)?[.]?[[:space:]]+', '', 1, 0,'i'),
    	p_dc_crmv,
    	p_ds_especialidade,
    	p_ds_email,
    	p_id_clinica,
    	NVL(p_st_ativo, 'S')
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'CRMV duplicado [' || p_dc_crmv || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [ST_ATIVO]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_VETERINARIO;
/
  -- ## 2.07 — TB_ARKIVE_USUARIO
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_USUARIO (
    p_tp_usuario IN TB_ARKIVE_USUARIO.TP_USUARIO%TYPE,
    p_id_responsavel IN TB_ARKIVE_USUARIO.ID_RESPONSAVEL%TYPE DEFAULT NULL,
    p_id_veterinario IN TB_ARKIVE_USUARIO.ID_VETERINARIO%TYPE DEFAULT NULL,
    p_ds_login IN TB_ARKIVE_USUARIO.DS_LOGIN%TYPE,
    p_ds_senha_hash IN TB_ARKIVE_USUARIO.DS_SENHA_HASH%TYPE,
    p_dt_cadastro IN TB_ARKIVE_USUARIO.DT_CADASTRO%TYPE DEFAULT SYSDATE,
    p_st_ativo IN TB_ARKIVE_USUARIO.ST_ATIVO%TYPE DEFAULT 'S'
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_USUARIO';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_USUARIO (
        TP_USUARIO, ID_RESPONSAVEL, ID_VETERINARIO,
        DS_LOGIN, DS_SENHA_HASH, DT_CADASTRO, ST_ATIVO
    ) VALUES (
        p_tp_usuario, p_id_responsavel, p_id_veterinario,
        p_ds_login, p_ds_senha_hash,
        NVL(p_dt_cadastro, SYSDATE), NVL(p_st_ativo, 'S')
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Login duplicado [' || p_ds_login || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [TP_USUARIO / referências FK]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_USUARIO;
/
  -- ## 2.08 — TB_ARKIVE_ANIMAL
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_ANIMAL (
    p_nm_animal IN TB_ARKIVE_ANIMAL.NM_ANIMAL%TYPE,
    p_id_especie IN TB_ARKIVE_ANIMAL.ID_ESPECIE%TYPE,
    p_id_raca IN TB_ARKIVE_ANIMAL.ID_RACA%TYPE DEFAULT NULL,
    p_ds_sexo IN TB_ARKIVE_ANIMAL.DS_SEXO%TYPE DEFAULT NULL,
    p_ds_castrado IN TB_ARKIVE_ANIMAL.DS_CASTRADO%TYPE DEFAULT 'N',
    p_id_clinica IN TB_ARKIVE_ANIMAL.ID_CLINICA%TYPE DEFAULT NULL,
    p_st_ativo IN TB_ARKIVE_ANIMAL.ST_ATIVO%TYPE DEFAULT 'S'
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_ANIMAL';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_ANIMAL (
        NM_ANIMAL, ID_ESPECIE, ID_RACA, DS_SEXO,
        DS_CASTRADO, ID_CLINICA, ST_ATIVO
    ) VALUES (
        p_nm_animal, p_id_especie, p_id_raca, p_ds_sexo,
        NVL(p_ds_castrado, 'N'), p_id_clinica, NVL(p_st_ativo, 'S')
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Animal duplicado [' || p_nm_animal || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [DS_SEXO / DS_CASTRADO / ST_ATIVO]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_ANIMAL;
/
  -- ## 2.09 — TB_ARKIVE_RESPONSAVEL_ANIMAL
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_RESP_ANIMAL (
    p_id_animal IN TB_ARKIVE_RESPONSAVEL_ANIMAL.ID_ANIMAL%TYPE,
    p_id_responsavel IN TB_ARKIVE_RESPONSAVEL_ANIMAL.ID_RESPONSAVEL%TYPE,
    p_tp_vinculo IN TB_ARKIVE_RESPONSAVEL_ANIMAL.TP_VINCULO%TYPE,
    p_dt_inicio IN TB_ARKIVE_RESPONSAVEL_ANIMAL.DT_INICIO%TYPE DEFAULT SYSDATE,
    p_dt_fim IN TB_ARKIVE_RESPONSAVEL_ANIMAL.DT_FIM%TYPE DEFAULT NULL,
    p_st_principal IN TB_ARKIVE_RESPONSAVEL_ANIMAL.ST_PRINCIPAL%TYPE DEFAULT 'N',
    p_st_ativo IN TB_ARKIVE_RESPONSAVEL_ANIMAL.ST_ATIVO%TYPE DEFAULT 'S'
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_RESP_ANIMAL';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_RESPONSAVEL_ANIMAL (
        ID_ANIMAL, ID_RESPONSAVEL, TP_VINCULO,
        DT_INICIO, DT_FIM, ST_PRINCIPAL, ST_ATIVO
    ) VALUES (
        p_id_animal, p_id_responsavel, p_tp_vinculo,
        NVL(p_dt_inicio, SYSDATE), p_dt_fim,
        NVL(p_st_principal, 'N'), NVL(p_st_ativo, 'S')
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Vínculo duplicado [ANIMAL ' || p_id_animal ||
            ' / RESP ' || p_id_responsavel || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [TP_VINCULO / DT_FIM / ST_*]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_RESP_ANIMAL;
/
  -- ## 2.10 — TB_ARKIVE_CATEGORIA_DOENCA
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_CAT_DOENCA (
    p_nm_categoria IN TB_ARKIVE_CATEGORIA_DOENCA.NM_CATEGORIA%TYPE,
    p_st_ativo IN TB_ARKIVE_CATEGORIA_DOENCA.ST_ATIVO%TYPE DEFAULT 'S'
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_CAT_DOENCA';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_CATEGORIA_DOENCA (NM_CATEGORIA, ST_ATIVO)
    VALUES (p_nm_categoria, NVL(p_st_ativo, 'S'));
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Categoria duplicada [' || p_nm_categoria || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [ST_ATIVO]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_CAT_DOENCA;
/
  -- ## 2.11 — TB_ARKIVE_DOENCA
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_DOENCA (
    p_nm_doenca IN TB_ARKIVE_DOENCA.NM_DOENCA%TYPE,
    p_id_categoria IN TB_ARKIVE_DOENCA.ID_CATEGORIA%TYPE DEFAULT NULL,
    p_ds_doenca IN VARCHAR2 DEFAULT NULL,
    p_cd_cid_vet IN TB_ARKIVE_DOENCA.CD_CID_VET%TYPE DEFAULT NULL,
    p_ds_sintomas IN VARCHAR2 DEFAULT NULL,
    p_st_ativo IN TB_ARKIVE_DOENCA.ST_ATIVO%TYPE DEFAULT 'S'
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_DOENCA';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_DOENCA (
        NM_DOENCA, ID_CATEGORIA, DS_DOENCA,
        CD_CID_VET, DS_SINTOMAS, ST_ATIVO
    ) VALUES (
        p_nm_doenca, p_id_categoria, p_ds_doenca,
        p_cd_cid_vet, p_ds_sintomas, NVL(p_st_ativo, 'S')
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Doença duplicada [' || p_nm_doenca || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [ST_ATIVO]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_DOENCA;
/
  -- ## 2.12 — TB_ARKIVE_PREDISPOSICAO
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_PREDISPOSICAO (
    p_id_especie IN TB_ARKIVE_PREDISPOSICAO.ID_ESPECIE%TYPE,
    p_id_raca IN TB_ARKIVE_PREDISPOSICAO.ID_RACA%TYPE DEFAULT NULL,
    p_id_doenca IN TB_ARKIVE_PREDISPOSICAO.ID_DOENCA%TYPE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_PREDISPOSICAO';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_PREDISPOSICAO (ID_ESPECIE, ID_RACA, ID_DOENCA)
    VALUES (p_id_especie, p_id_raca, p_id_doenca);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Predisposição duplicada [ESP ' || p_id_especie ||
            ' / RACA ' || NVL(TO_CHAR(p_id_raca), 'NULL') ||
            ' / DOENCA ' || p_id_doenca || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_PREDISPOSICAO;
/
  -- ## 2.13 — TB_ARKIVE_CONSULTA
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_CONSULTA (
    p_dt_hora IN TB_ARKIVE_CONSULTA.DT_HORA%TYPE,
    p_tp_modalidade IN TB_ARKIVE_CONSULTA.TP_MODALIDADE%TYPE,
    p_ds_motivo IN VARCHAR2,
    p_ds_sintomas IN VARCHAR2 DEFAULT NULL,
    p_ds_observacao IN VARCHAR2 DEFAULT NULL,
    p_kg_peso IN TB_ARKIVE_CONSULTA.KG_PESO%TYPE DEFAULT NULL,
    p_ds_transcricao IN VARCHAR2 DEFAULT NULL,
    p_st_status IN TB_ARKIVE_CONSULTA.ST_STATUS%TYPE DEFAULT 'AG',
    p_id_animal IN TB_ARKIVE_CONSULTA.ID_ANIMAL%TYPE,
    p_id_veterinario IN TB_ARKIVE_CONSULTA.ID_VETERINARIO%TYPE,
    p_id_clinica IN TB_ARKIVE_CONSULTA.ID_CLINICA%TYPE DEFAULT NULL
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_CONSULTA';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_CONSULTA (
        DT_HORA, TP_MODALIDADE, DS_MOTIVO, DS_SINTOMAS,
        DS_OBSERVACAO, KG_PESO, DS_TRANSCRICAO, ST_STATUS,
        ID_ANIMAL, ID_VETERINARIO, ID_CLINICA
    ) VALUES (
        p_dt_hora, p_tp_modalidade, p_ds_motivo, p_ds_sintomas,
        p_ds_observacao, p_kg_peso, p_ds_transcricao,
        NVL(p_st_status, 'AG'), p_id_animal, p_id_veterinario, p_id_clinica
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Consulta duplicada: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [TP_MODALIDADE / ST_STATUS / KG_PESO]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_CONSULTA;
/
  -- ## 2.14 — TB_ARKIVE_DIAGNOSTICO
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_DIAGNOSTICO (
    p_ds_diagnostico IN VARCHAR2,
    p_tp_severidade IN TB_ARKIVE_DIAGNOSTICO.TP_SEVERIDADE%TYPE DEFAULT NULL,
    p_st_confirmado IN TB_ARKIVE_DIAGNOSTICO.ST_CONFIRMADO%TYPE DEFAULT 'S',
    p_ds_insight_ia IN VARCHAR2 DEFAULT NULL,
    p_pc_confianca IN TB_ARKIVE_DIAGNOSTICO.PC_CONFIANCA%TYPE DEFAULT NULL,
    p_st_validacao_vet IN TB_ARKIVE_DIAGNOSTICO.ST_VALIDACAO_VET%TYPE DEFAULT NULL,
    p_id_consulta IN TB_ARKIVE_DIAGNOSTICO.ID_CONSULTA%TYPE,
    p_id_doenca IN TB_ARKIVE_DIAGNOSTICO.ID_DOENCA%TYPE DEFAULT NULL
) IS
    c_nm_proc  CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_DIAGNOSTICO';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_DIAGNOSTICO (
        DS_DIAGNOSTICO, TP_SEVERIDADE, ST_CONFIRMADO,
        DS_INSIGHT_IA, PC_CONFIANCA, ST_VALIDACAO_VET,
        ID_CONSULTA, ID_DOENCA
    ) VALUES (
        p_ds_diagnostico, p_tp_severidade, NVL(p_st_confirmado, 'S'),
        p_ds_insight_ia, p_pc_confianca, p_st_validacao_vet,
        p_id_consulta, p_id_doenca
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Diagnóstico duplicado: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [TP_SEVERIDADE / ST_* / PC_CONFIANCA]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_DIAGNOSTICO;
/
  -- ## 2.15 — TB_ARKIVE_PRESCRICAO
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_PRESCRICAO (
    p_nm_medicamento IN TB_ARKIVE_PRESCRICAO.NM_MEDICAMENTO%TYPE,
    p_ds_dosagem IN TB_ARKIVE_PRESCRICAO.DS_DOSAGEM%TYPE,
    p_ds_frequencia IN TB_ARKIVE_PRESCRICAO.DS_FREQUENCIA%TYPE DEFAULT NULL,
    p_tp_via_administracao IN TB_ARKIVE_PRESCRICAO.TP_VIA_ADMINISTRACAO%TYPE DEFAULT NULL,
    p_dt_inicio IN TB_ARKIVE_PRESCRICAO.DT_INICIO%TYPE,
    p_dt_fim IN TB_ARKIVE_PRESCRICAO.DT_FIM%TYPE DEFAULT NULL,
    p_ds_instrucoes IN VARCHAR2 DEFAULT NULL,
    p_id_consulta IN TB_ARKIVE_PRESCRICAO.ID_CONSULTA%TYPE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_PRESCRICAO';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_PRESCRICAO (
        NM_MEDICAMENTO, DS_DOSAGEM, DS_FREQUENCIA,
        TP_VIA_ADMINISTRACAO, DT_INICIO, DT_FIM,
        DS_INSTRUCOES, ID_CONSULTA
    ) VALUES (
        p_nm_medicamento, p_ds_dosagem, p_ds_frequencia,
        p_tp_via_administracao, p_dt_inicio, p_dt_fim,
        p_ds_instrucoes, p_id_consulta
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Prescrição duplicada: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [TP_VIA / DT_FIM]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_PRESCRICAO;
/
  -- ## 2.16 — TB_ARKIVE_AVALIACAO_BEM_ESTAR
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_AVAL_BEM_ESTAR (
    p_id_animal IN TB_ARKIVE_AVALIACAO_BEM_ESTAR.ID_ANIMAL%TYPE,
    p_id_responsavel IN TB_ARKIVE_AVALIACAO_BEM_ESTAR.ID_RESPONSAVEL%TYPE DEFAULT NULL,
    p_id_veterinario IN TB_ARKIVE_AVALIACAO_BEM_ESTAR.ID_VETERINARIO%TYPE DEFAULT NULL,
    p_id_consulta IN TB_ARKIVE_AVALIACAO_BEM_ESTAR.ID_CONSULTA%TYPE DEFAULT NULL,
    p_dt_avaliacao IN TB_ARKIVE_AVALIACAO_BEM_ESTAR.DT_AVALIACAO%TYPE DEFAULT SYSDATE,
    p_nr_idade IN TB_ARKIVE_AVALIACAO_BEM_ESTAR.NR_IDADE%TYPE DEFAULT NULL,
    p_kg_peso IN TB_ARKIVE_AVALIACAO_BEM_ESTAR.KG_PESO%TYPE DEFAULT NULL,
    p_ds_apetite IN TB_ARKIVE_AVALIACAO_BEM_ESTAR.DS_APETITE%TYPE DEFAULT NULL,
    p_ds_atividade IN TB_ARKIVE_AVALIACAO_BEM_ESTAR.DS_ATIVIDADE%TYPE DEFAULT NULL,
    p_ds_comportamento IN TB_ARKIVE_AVALIACAO_BEM_ESTAR.DS_COMPORTAMENTO%TYPE DEFAULT NULL,
    p_ds_observacao IN VARCHAR2 DEFAULT NULL
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_AVAL_BEM_ESTAR';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_AVALIACAO_BEM_ESTAR (
        ID_ANIMAL, ID_RESPONSAVEL, ID_VETERINARIO, ID_CONSULTA,
        DT_AVALIACAO, NR_IDADE, KG_PESO,
        DS_APETITE, DS_ATIVIDADE, DS_COMPORTAMENTO, DS_OBSERVACAO
    ) VALUES (
        p_id_animal, p_id_responsavel, p_id_veterinario, p_id_consulta,
        NVL(p_dt_avaliacao, SYSDATE), p_nr_idade, p_kg_peso,
        p_ds_apetite, p_ds_atividade, p_ds_comportamento, p_ds_observacao
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Avaliação duplicada: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [DS_APETITE / DS_ATIVIDADE / DS_COMPORTAMENTO / autor]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_AVAL_BEM_ESTAR;
/
  -- ## 2.17 — TB_ARKIVE_PROTOCOLO_PREVENTIVO
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_PROTOCOLO_PREV (
    p_nm_protocolo IN TB_ARKIVE_PROTOCOLO_PREVENTIVO.NM_PROTOCOLO%TYPE,
    p_tp_protocolo IN TB_ARKIVE_PROTOCOLO_PREVENTIVO.TP_PROTOCOLO%TYPE,
    p_ds_protocolo IN VARCHAR2 DEFAULT NULL,
    p_nr_intervalo IN TB_ARKIVE_PROTOCOLO_PREVENTIVO.NR_INTERVALO%TYPE,
    p_nr_idade_min IN TB_ARKIVE_PROTOCOLO_PREVENTIVO.NR_IDADE_MIN%TYPE DEFAULT 0,
    p_id_especie IN TB_ARKIVE_PROTOCOLO_PREVENTIVO.ID_ESPECIE%TYPE DEFAULT NULL,
    p_id_raca IN TB_ARKIVE_PROTOCOLO_PREVENTIVO.ID_RACA%TYPE DEFAULT NULL,
    p_st_ativo IN TB_ARKIVE_PROTOCOLO_PREVENTIVO.ST_ATIVO%TYPE DEFAULT 'S'
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_PROTOCOLO_PREV';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_PROTOCOLO_PREVENTIVO (
        NM_PROTOCOLO, TP_PROTOCOLO, DS_PROTOCOLO,
        NR_INTERVALO, NR_IDADE_MIN, ID_ESPECIE, ID_RACA, ST_ATIVO
    ) VALUES (
        p_nm_protocolo, p_tp_protocolo, p_ds_protocolo,
        p_nr_intervalo, NVL(p_nr_idade_min, 0),
        p_id_especie, p_id_raca, NVL(p_st_ativo, 'S')
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Protocolo duplicado [' || p_nm_protocolo || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [TP_PROTOCOLO / NR_INTERVALO / NR_IDADE_MIN]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_PROTOCOLO_PREV;
/
  -- ## 2.18 — TB_ARKIVE_EVENTO_PREVENTIVO
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_EVENTO_PREV (
    p_dt_aplicacao IN TB_ARKIVE_EVENTO_PREVENTIVO.DT_APLICACAO%TYPE DEFAULT NULL,
    p_dt_proximo IN TB_ARKIVE_EVENTO_PREVENTIVO.DT_PROXIMO%TYPE,
    p_st_status IN TB_ARKIVE_EVENTO_PREVENTIVO.ST_STATUS%TYPE DEFAULT 'PENDENTE',
    p_st_alerta IN TB_ARKIVE_EVENTO_PREVENTIVO.ST_ALERTA%TYPE DEFAULT 'N',
    p_ds_observacao IN VARCHAR2 DEFAULT NULL,
    p_id_animal IN TB_ARKIVE_EVENTO_PREVENTIVO.ID_ANIMAL%TYPE,
    p_id_protocolo IN TB_ARKIVE_EVENTO_PREVENTIVO.ID_PROTOCOLO%TYPE,
    p_id_consulta IN TB_ARKIVE_EVENTO_PREVENTIVO.ID_CONSULTA%TYPE DEFAULT NULL
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_EVENTO_PREV';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_EVENTO_PREVENTIVO (
        DT_APLICACAO, DT_PROXIMO, ST_STATUS, ST_ALERTA,
        DS_OBSERVACAO, ID_ANIMAL, ID_PROTOCOLO, ID_CONSULTA
    ) VALUES (
        p_dt_aplicacao, p_dt_proximo,
        NVL(p_st_status, 'PENDENTE'), NVL(p_st_alerta, 'N'),
        p_ds_observacao, p_id_animal, p_id_protocolo, p_id_consulta
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Evento preventivo duplicado: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [ST_STATUS / DT_APLICACAO / DT_PROXIMO]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_EVENTO_PREV;
/
  -- ## 2.19 — TB_ARKIVE_ALERTA
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_ALERTA (
    p_tp_alerta IN TB_ARKIVE_ALERTA.TP_ALERTA%TYPE,
    p_ds_mensagem IN VARCHAR2,
    p_dt_envio IN TB_ARKIVE_ALERTA.DT_ENVIO%TYPE DEFAULT SYSDATE,
    p_dt_leitura IN TB_ARKIVE_ALERTA.DT_LEITURA%TYPE DEFAULT NULL,
    p_st_status IN TB_ARKIVE_ALERTA.ST_STATUS%TYPE DEFAULT 'ENVIADO',
    p_tp_canal IN TB_ARKIVE_ALERTA.TP_CANAL%TYPE,
    p_id_animal IN TB_ARKIVE_ALERTA.ID_ANIMAL%TYPE,
    p_id_responsavel IN TB_ARKIVE_ALERTA.ID_RESPONSAVEL%TYPE DEFAULT NULL,
    p_id_clinica IN TB_ARKIVE_ALERTA.ID_CLINICA%TYPE DEFAULT NULL,
    p_id_evento_prev IN TB_ARKIVE_ALERTA.ID_EVENTO_PREV%TYPE DEFAULT NULL
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_ALERTA';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_ALERTA (
        TP_ALERTA, DS_MENSAGEM, DT_ENVIO, DT_LEITURA,
        ST_STATUS, TP_CANAL, ID_ANIMAL,
        ID_RESPONSAVEL, ID_CLINICA, ID_EVENTO_PREV
    ) VALUES (
        p_tp_alerta, p_ds_mensagem,
        NVL(p_dt_envio, SYSDATE), p_dt_leitura,
        NVL(p_st_status, 'ENVIADO'), p_tp_canal, p_id_animal,
        p_id_responsavel, p_id_clinica, p_id_evento_prev
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Alerta duplicado: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [TP_ALERTA / ST_STATUS / TP_CANAL / destino]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_ALERTA;
/
  -- ## 2.20 — TB_ARKIVE_EVENTO_JORNADA
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_EVENTO_JORNADA (
    p_tp_evento IN TB_ARKIVE_EVENTO_JORNADA.TP_EVENTO%TYPE,
    p_dt_evento IN TB_ARKIVE_EVENTO_JORNADA.DT_EVENTO%TYPE DEFAULT SYSDATE,
    p_tp_origem IN TB_ARKIVE_EVENTO_JORNADA.TP_ORIGEM%TYPE,
    p_tp_ator IN TB_ARKIVE_EVENTO_JORNADA.TP_ATOR%TYPE DEFAULT NULL,
    p_id_responsavel IN TB_ARKIVE_EVENTO_JORNADA.ID_RESPONSAVEL%TYPE DEFAULT NULL,
    p_id_veterinario IN TB_ARKIVE_EVENTO_JORNADA.ID_VETERINARIO%TYPE DEFAULT NULL,
    p_id_animal IN TB_ARKIVE_EVENTO_JORNADA.ID_ANIMAL%TYPE DEFAULT NULL,
    p_id_clinica IN TB_ARKIVE_EVENTO_JORNADA.ID_CLINICA%TYPE DEFAULT NULL,
    p_ds_canal IN TB_ARKIVE_EVENTO_JORNADA.DS_CANAL%TYPE DEFAULT NULL,
    p_ds_contexto IN VARCHAR2 DEFAULT NULL,
    p_payload_json IN VARCHAR2 DEFAULT NULL
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_EVENTO_JORNADA';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_EVENTO_JORNADA (
        TP_EVENTO, DT_EVENTO, TP_ORIGEM, TP_ATOR,
        ID_RESPONSAVEL, ID_VETERINARIO, ID_ANIMAL, ID_CLINICA,
        DS_CANAL, DS_CONTEXTO, PAYLOAD_JSON
    ) VALUES (
        p_tp_evento, NVL(p_dt_evento, SYSDATE), p_tp_origem, p_tp_ator,
        p_id_responsavel, p_id_veterinario, p_id_animal, p_id_clinica,
        p_ds_canal, p_ds_contexto, p_payload_json
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Evento de jornada duplicado: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [TP_ORIGEM / TP_ATOR / PAYLOAD_JSON]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_EVENTO_JORNADA;
/
  -- ## 2.21 — TB_ARKIVE_ADESAO_PRESCRICAO
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_ADESAO_PRESCRICAO (
    p_id_prescricao IN TB_ARKIVE_ADESAO_PRESCRICAO.ID_PRESCRICAO%TYPE,
    p_id_responsavel IN TB_ARKIVE_ADESAO_PRESCRICAO.ID_RESPONSAVEL%TYPE DEFAULT NULL,
    p_id_animal IN TB_ARKIVE_ADESAO_PRESCRICAO.ID_ANIMAL%TYPE,
    p_dt_registro IN TB_ARKIVE_ADESAO_PRESCRICAO.DT_REGISTRO%TYPE DEFAULT SYSDATE,
    p_st_tomou IN TB_ARKIVE_ADESAO_PRESCRICAO.ST_TOMOU%TYPE,
    p_ds_observacao IN VARCHAR2 DEFAULT NULL
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_ADESAO_PRESCRICAO';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_ADESAO_PRESCRICAO (
        ID_PRESCRICAO, ID_RESPONSAVEL, ID_ANIMAL,
        DT_REGISTRO, ST_TOMOU, DS_OBSERVACAO
    ) VALUES (
        p_id_prescricao, p_id_responsavel, p_id_animal,
        NVL(p_dt_registro, SYSDATE), p_st_tomou, p_ds_observacao
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Adesão duplicada: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [ST_TOMOU]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_ADESAO_PRESCRICAO;
/
  -- ## 2.22 — TB_ARKIVE_FEEDBACK_NPS
CREATE OR REPLACE PROCEDURE PR_ARKIVE_INS_FEEDBACK_NPS (
    p_id_veterinario IN TB_ARKIVE_FEEDBACK_NPS.ID_VETERINARIO%TYPE DEFAULT NULL,
    p_id_responsavel IN TB_ARKIVE_FEEDBACK_NPS.ID_RESPONSAVEL%TYPE DEFAULT NULL,
    p_id_animal IN TB_ARKIVE_FEEDBACK_NPS.ID_ANIMAL%TYPE DEFAULT NULL,
    p_id_clinica IN TB_ARKIVE_FEEDBACK_NPS.ID_CLINICA%TYPE DEFAULT NULL,
    p_id_consulta IN TB_ARKIVE_FEEDBACK_NPS.ID_CONSULTA%TYPE DEFAULT NULL,
    p_nr_nota IN TB_ARKIVE_FEEDBACK_NPS.NR_NOTA%TYPE,
    p_ds_comentario IN VARCHAR2 DEFAULT NULL,
    p_dt_feedback IN TB_ARKIVE_FEEDBACK_NPS.DT_FEEDBACK%TYPE DEFAULT SYSDATE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_ARKIVE_INS_FEEDBACK_NPS';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_ARKIVE_FEEDBACK_NPS (
        ID_VETERINARIO, ID_RESPONSAVEL, ID_ANIMAL, ID_CLINICA,
        ID_CONSULTA, NR_NOTA, DS_COMENTARIO, DT_FEEDBACK
    ) VALUES (
        p_id_veterinario, p_id_responsavel, p_id_animal, p_id_clinica,
        p_id_consulta, p_nr_nota, p_ds_comentario,
        NVL(p_dt_feedback, SYSDATE)
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Feedback NPS duplicado: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK [NR_NOTA 0-5 / contexto obrigatório]: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_ARKIVE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_ARKIVE_INS_FEEDBACK_NPS;
/
/*
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================
   # 3 — CARGA DE DADOS VIA PROCEDURES
  ──────────────────────────────────────────────────────────────────────────────
*/
  -- ## 3.01 — TB_ARKIVE_ESPECIE
BEGIN
    PR_ARKIVE_INS_ESPECIE('Cachorro', 'S');
    PR_ARKIVE_INS_ESPECIE('Gato', 'S');
    PR_ARKIVE_INS_ESPECIE('Ave', 'S');
    PR_ARKIVE_INS_ESPECIE('Coelho', 'S');
    PR_ARKIVE_INS_ESPECIE('Cavalo', 'S');
    PR_ARKIVE_INS_ESPECIE('Peixe', 'S');
    PR_ARKIVE_INS_ESPECIE('Réptil', 'S');
    PR_ARKIVE_INS_ESPECIE('Hamster', 'S');
    PR_ARKIVE_INS_ESPECIE('Porquinho da Índia', 'S');
    PR_ARKIVE_INS_ESPECIE('Furão', 'S');
    COMMIT;
END;
/
  -- ## 3.02 — TB_ARKIVE_RACA
BEGIN
    PR_ARKIVE_INS_RACA('Labrador', 1, 'GRANDE', 'S');
    PR_ARKIVE_INS_RACA('Poodle', 1, 'MEDIO', 'S');
    PR_ARKIVE_INS_RACA('Buldogue', 1, 'MEDIO', 'S');
    PR_ARKIVE_INS_RACA('Golden Retriever', 1, 'GRANDE', 'S');
    PR_ARKIVE_INS_RACA('Pastor Alemão', 1, 'GRANDE', 'S');
    PR_ARKIVE_INS_RACA('Siamês', 2, 'MEDIO', 'S');
    PR_ARKIVE_INS_RACA('Persa', 2, 'MEDIO', 'S');
    PR_ARKIVE_INS_RACA('Maine Coon', 2, 'GRANDE', 'S');
    PR_ARKIVE_INS_RACA('Sphynx', 2, 'PEQUENO', 'S');
    PR_ARKIVE_INS_RACA('Ragdoll', 2, 'GRANDE', 'S');
    COMMIT;
END;
/
  -- ## 3.03 — TB_ARKIVE_RESPONSAVEL
BEGIN
    PR_ARKIVE_INS_RESPONSAVEL('Ana Paula Souza', '12345678901', 'ana.souza@email.com', '11987654321', 'TUTOR', SYSDATE, 'S', 'S');
    PR_ARKIVE_INS_RESPONSAVEL('Carlos Alberto Mendes', '23456789012', 'carlos.mendes@email.com', '21976543210', 'TUTOR', SYSDATE, 'S', 'S');
    PR_ARKIVE_INS_RESPONSAVEL('Fernanda Lima', '34567890123', 'fernanda.lima@email.com', '31987654321', 'FUNCIONARIO_CLINICA', SYSDATE, 'S', 'S');
    PR_ARKIVE_INS_RESPONSAVEL('Ricardo Oliveira', '45678901234', 'ricardo.oliveira@email.com', '41976543210', 'ONG', SYSDATE, 'S', 'S');
    PR_ARKIVE_INS_RESPONSAVEL('Patrícia Costa', '56789012345', 'patricia.costa@email.com', '51987654321', 'TUTOR', SYSDATE, 'S', 'S');
    PR_ARKIVE_INS_RESPONSAVEL('Juliana Rocha', '67890123456', 'juliana.rocha@email.com', '61976543210', 'INSTITUICAO', SYSDATE, 'S', 'S');
    PR_ARKIVE_INS_RESPONSAVEL('Marcos Vinicius', '78901234567', 'marcos.vinicius@email.com', '71987654321', 'FUNCIONARIO_ZOO',SYSDATE, 'S', 'S');
    PR_ARKIVE_INS_RESPONSAVEL('Camila Alves', '89012345678', 'camila.alves@email.com', '81976543210', 'TUTOR', SYSDATE, 'S', 'S');
    PR_ARKIVE_INS_RESPONSAVEL('Rodrigo Santos', '90123456789', 'rodrigo.santos@email.com', '91987654321', 'OUTRO', SYSDATE, 'S', 'S');
    PR_ARKIVE_INS_RESPONSAVEL('Luciana Ferreira', '01234567890', 'luciana.ferreira@email.com', '11987654322', 'TUTOR', SYSDATE, 'S', 'S');
    COMMIT;
END;
/
  -- ## 3.04 — TB_ARKIVE_CLINICA
BEGIN
    PR_ARKIVE_INS_CLINICA('VetCare Paulista', '12345678000101', 'Av. Paulista, 1000, São Paulo/SP', '1133331111', 'contato@vetcare.com', 'S');
    PR_ARKIVE_INS_CLINICA('Animal Saúde', '23456789000102', 'Rua das Flores, 200, Rio de Janeiro/RJ', '2134442222', 'atendimento@animalsaude.com', 'S');
    PR_ARKIVE_INS_CLINICA('Pet Bem Estar', '34567890000103', 'Av. Afonso Pena, 500, Belo Horizonte/MG', '3135553333', 'bemestar@pet.com', 'S');
    PR_ARKIVE_INS_CLINICA('Clínica Veterinária São Francisco','45678901000104', 'Rua XV de Novembro, 1500, Curitiba/PR', '4136664444', 'sfrancisco@vet.com', 'S');
    PR_ARKIVE_INS_CLINICA('ZooVet Porto Alegre', '56789012000105', 'Av. Ipiranga, 300, Porto Alegre/RS', '5137775555', 'zoovet@zoovet.com', 'S');
    PR_ARKIVE_INS_CLINICA('Clínica Dog & Cat', '67890123000106', 'Rua da Praia, 75, Salvador/BA', '7138886666', 'dogcat@dogcat.com', 'S');
    PR_ARKIVE_INS_CLINICA('Vet Hospital Brasília', '78901234000107', 'Setor Médico Norte, 10, Brasília/DF', '6139997777', 'hospital@vetbrasilia.com', 'S');
    PR_ARKIVE_INS_CLINICA('Clínica Pet Vida', '89012345000108', 'Rua do Comércio, 320, Recife/PE', '8140008888', 'petvida@petvida.com', 'S');
    PR_ARKIVE_INS_CLINICA('Animal Center Manaus', '90123456000109', 'Av. Amazonas, 450, Manaus/AM', '9241119999', 'animalcenter@manaus.com', 'S');
    PR_ARKIVE_INS_CLINICA('Clínica Veterinária Fortaleza', '01234567000110', 'Rua Barão do Rio Branco, 800, Fortaleza/CE', '8542220000', 'fortaleza@vetclinic.com', 'S');
    COMMIT;
END;
/
  -- ## 3.05 — TB_ARKIVE_RESPONSAVEL_CLINICA
BEGIN
    PR_ARKIVE_INS_RESP_CLINICA(1, 1, SYSDATE);
    PR_ARKIVE_INS_RESP_CLINICA(2, 2, SYSDATE);
    PR_ARKIVE_INS_RESP_CLINICA(3, 3, SYSDATE);
    PR_ARKIVE_INS_RESP_CLINICA(4, 4, SYSDATE);
    PR_ARKIVE_INS_RESP_CLINICA(5, 5, SYSDATE);
    PR_ARKIVE_INS_RESP_CLINICA(6, 6, SYSDATE);
    PR_ARKIVE_INS_RESP_CLINICA(7, 7, SYSDATE);
    PR_ARKIVE_INS_RESP_CLINICA(8, 8, SYSDATE);
    PR_ARKIVE_INS_RESP_CLINICA(9, 9, SYSDATE);
    PR_ARKIVE_INS_RESP_CLINICA(10, 10, SYSDATE);
    COMMIT;
END;
/
  -- ## 3.06 — TB_ARKIVE_VETERINARIO
BEGIN
    PR_ARKIVE_INS_VETERINARIO('Mariana Andrade', '12345-SP','Clínica Geral', 'mariana.andrade@vet.com', 1, 'S');
    PR_ARKIVE_INS_VETERINARIO('Rafael Brito', '23456-RJ','Dermatologia', 'rafael.brito@vet.com', 2, 'S');
    PR_ARKIVE_INS_VETERINARIO('Carolina Mendes', '34567-MG','Ortopedia', 'carolina.mendes@vet.com', 3, 'S');
    PR_ARKIVE_INS_VETERINARIO('Thiago Lima', '45678-PR','Cardiologia', 'thiago.lima@vet.com', 4, 'S');
    PR_ARKIVE_INS_VETERINARIO('Fernanda Castro', '56789-RS','Oftalmologia', 'fernanda.castro@vet.com', 5, 'S');
    PR_ARKIVE_INS_VETERINARIO('Gustavo Nunes', '67890-BA','Neurologia', 'gustavo.nunes@vet.com', 6, 'S');
    PR_ARKIVE_INS_VETERINARIO('Patrícia Faria', '78901-DF','Oncologia', 'patricia.faria@vet.com', 7, 'S');
    PR_ARKIVE_INS_VETERINARIO('André Ribeiro', '89012-PE','Cirurgia', 'andre.ribeiro@vet.com', 8, 'S');
    PR_ARKIVE_INS_VETERINARIO('Lívia Batista', '90123-AM','Endocrinologia', 'livia.batista@vet.com', 9, 'S');
    PR_ARKIVE_INS_VETERINARIO('Bruno Almeida', '01234-CE','Clínica Geral', 'bruno.almeida@vet.com', NULL, 'S');
    COMMIT;
END;
/
  -- ## 3.07 — TB_ARKIVE_USUARIO
BEGIN
    PR_ARKIVE_INS_USUARIO('RESPONSAVEL', 1, NULL, 'ana.souza', 'hash_senha_001', SYSDATE, 'S');
    PR_ARKIVE_INS_USUARIO('RESPONSAVEL', 2, NULL, 'carlos.mendes', 'hash_senha_002', SYSDATE, 'S');
    PR_ARKIVE_INS_USUARIO('RESPONSAVEL', 5, NULL, 'patricia.costa', 'hash_senha_003', SYSDATE, 'S');
    PR_ARKIVE_INS_USUARIO('RESPONSAVEL', 8, NULL, 'camila.alves', 'hash_senha_004', SYSDATE, 'S');
    PR_ARKIVE_INS_USUARIO('RESPONSAVEL', 10, NULL, 'luciana.ferreira', 'hash_senha_005', SYSDATE, 'S');
    PR_ARKIVE_INS_USUARIO('VETERINARIO', NULL, 1, 'mariana.andrade', 'hash_senha_006', SYSDATE, 'S');
    PR_ARKIVE_INS_USUARIO('VETERINARIO', NULL, 2, 'rafael.brito', 'hash_senha_007', SYSDATE, 'S');
    PR_ARKIVE_INS_USUARIO('VETERINARIO', NULL, 3, 'carolina.mendes', 'hash_senha_008', SYSDATE, 'S');
    PR_ARKIVE_INS_USUARIO('VETERINARIO', NULL, 4, 'thiago.lima', 'hash_senha_009', SYSDATE, 'S');
    PR_ARKIVE_INS_USUARIO('VETERINARIO', NULL, 5, 'fernanda.castro', 'hash_senha_010', SYSDATE, 'S');
    COMMIT;
END;
/
  -- ## 3.08 — TB_ARKIVE_ANIMAL
BEGIN
    PR_ARKIVE_INS_ANIMAL('Rex', 1, 1, 'M', 'S', 1, 'S');
    PR_ARKIVE_INS_ANIMAL('Luna', 1, 2, 'F', 'S', 2, 'S');
    PR_ARKIVE_INS_ANIMAL('Thor', 1, 3, 'M', 'N', NULL, 'S');
    PR_ARKIVE_INS_ANIMAL('Mel', 2, 6, 'F', 'S', 3, 'S');
    PR_ARKIVE_INS_ANIMAL('Simba', 2, 7, 'M', 'N', 4, 'S');
    PR_ARKIVE_INS_ANIMAL('Bilu', 1, 4, 'M', 'S', 5, 'S');
    PR_ARKIVE_INS_ANIMAL('Nina', 2, 8, 'F', 'S', NULL, 'S');
    PR_ARKIVE_INS_ANIMAL('Bob', 1, 5, 'M', 'N', 6, 'S');
    PR_ARKIVE_INS_ANIMAL('Frajola', 2, 9, 'M', 'S', 7, 'S');
    PR_ARKIVE_INS_ANIMAL('Pandora', 2, 10, 'F', 'N', NULL, 'S');
    COMMIT;
END;
/
  -- ## 3.09 — TB_ARKIVE_RESPONSAVEL_ANIMAL
BEGIN
    PR_ARKIVE_INS_RESP_ANIMAL(1, 1, 'TUTOR_LEGAL', SYSDATE, NULL, 'S', 'S');
    PR_ARKIVE_INS_RESP_ANIMAL(2, 2, 'TUTOR_LEGAL', SYSDATE, NULL, 'S', 'S');
    PR_ARKIVE_INS_RESP_ANIMAL(3, 3, 'CUIDADOR', SYSDATE, NULL, 'N', 'S');
    PR_ARKIVE_INS_RESP_ANIMAL(4, 4, 'RESPONSAVEL_CLINICO', SYSDATE, NULL, 'S', 'S');
    PR_ARKIVE_INS_RESP_ANIMAL(5, 5, 'TUTOR_LEGAL', SYSDATE, NULL, 'S', 'S');
    PR_ARKIVE_INS_RESP_ANIMAL(6, 6, 'CONTATO_EMERGENCIA', SYSDATE, NULL, 'N', 'S');
    PR_ARKIVE_INS_RESP_ANIMAL(7, 7, 'RESPONSAVEL_OPERACIONAL', SYSDATE, NULL, 'S', 'S');
    PR_ARKIVE_INS_RESP_ANIMAL(8, 8, 'TUTOR_LEGAL', SYSDATE, NULL, 'S', 'S');
    PR_ARKIVE_INS_RESP_ANIMAL(9, 9, 'CUIDADOR', SYSDATE, NULL, 'N', 'S');
    PR_ARKIVE_INS_RESP_ANIMAL(10, 10, 'TUTOR_LEGAL', SYSDATE, NULL, 'S', 'S');
    COMMIT;
END;
/
  -- ## 3.10 — TB_ARKIVE_CATEGORIA_DOENCA
BEGIN
    PR_ARKIVE_INS_CAT_DOENCA('Infecciosa', 'S');
    PR_ARKIVE_INS_CAT_DOENCA('Parasitária', 'S');
    PR_ARKIVE_INS_CAT_DOENCA('Nutricional', 'S');
    PR_ARKIVE_INS_CAT_DOENCA('Comportamental', 'S');
    PR_ARKIVE_INS_CAT_DOENCA('Cardiovascular', 'S');
    PR_ARKIVE_INS_CAT_DOENCA('Respiratória', 'S');
    PR_ARKIVE_INS_CAT_DOENCA('Dermatológica', 'S');
    PR_ARKIVE_INS_CAT_DOENCA('Oftalmológica', 'S');
    PR_ARKIVE_INS_CAT_DOENCA('Ortopédica', 'S');
    PR_ARKIVE_INS_CAT_DOENCA('Oncológica', 'S');
    COMMIT;
END;
/
  -- ## 3.11 — TB_ARKIVE_DOENCA
BEGIN
    PR_ARKIVE_INS_DOENCA('Parvovirose', 1, 'Doença viral grave que afeta cães', 'A08.0', 'vômito, diarreia sanguinolenta, letargia', 'S');
    PR_ARKIVE_INS_DOENCA('Giardíase', 2, 'Infecção por protozoário', 'A07.1', 'diarreia, perda de peso, fezes claras', 'S');
    PR_ARKIVE_INS_DOENCA('Obesidade', 3, 'Acúmulo excessivo de gordura', 'E66.9', 'ganho de peso, dificuldade de locomoção', 'S');
    PR_ARKIVE_INS_DOENCA('Ansiedade de separação', 4, 'Comportamento destrutivo quando sozinho', 'F41.8', 'latidos excessivos, destrói objetos', 'S');
    PR_ARKIVE_INS_DOENCA('Insuficiência cardíaca', 5, 'Coração não bombeia sangue adequadamente', 'I50.9', 'tosse, cansaço, dificuldade respiratória', 'S');
    PR_ARKIVE_INS_DOENCA('Traqueobronquite', 6, 'Tosse dos canis', 'J20.9', 'tosse seca, secreção nasal', 'S');
    PR_ARKIVE_INS_DOENCA('Dermatite atópica', 7, 'Inflamação alérgica da pele', 'L20.8', 'coceira, vermelhidão, lesões', 'S');
    PR_ARKIVE_INS_DOENCA('Catarata', 8, 'Opacificação do cristalino', 'H25.9', 'visão turva, olho esbranquiçado', 'S');
    PR_ARKIVE_INS_DOENCA('Displasia coxofemoral', 9, 'Malformação da articulação do quadril', 'M16.9', 'claudicação, dor ao andar', 'S');
    PR_ARKIVE_INS_DOENCA('Linfoma', 10, 'Câncer no sistema linfático', 'C85.9', 'linfonodos aumentados, perda de peso', 'S');
    COMMIT;
END;
/
  -- ## 3.12 — TB_ARKIVE_PREDISPOSICAO
BEGIN
    PR_ARKIVE_INS_PREDISPOSICAO(1, 1, 9);
    PR_ARKIVE_INS_PREDISPOSICAO(1, 2, 7);
    PR_ARKIVE_INS_PREDISPOSICAO(1, 3, 6);
    PR_ARKIVE_INS_PREDISPOSICAO(1, 4, 5);
    PR_ARKIVE_INS_PREDISPOSICAO(1, 5, 9);
    PR_ARKIVE_INS_PREDISPOSICAO(2, 6, 7);
    PR_ARKIVE_INS_PREDISPOSICAO(2, 7, 8);
    PR_ARKIVE_INS_PREDISPOSICAO(2, 8, 5);
    PR_ARKIVE_INS_PREDISPOSICAO(2, 9, 7);
    PR_ARKIVE_INS_PREDISPOSICAO(2, 10, 8);
    COMMIT;
END;
/
  -- ## 3.13 — TB_ARKIVE_CONSULTA
BEGIN
    PR_ARKIVE_INS_CONSULTA(TO_DATE('2025-01-15 09:30', 'YYYY-MM-DD HH24:MI'), 'PRESENCIAL', 'Vômito e diarreia', 'Vômito frequente, fezes moles', 'Animal alerta mas desidratado', 12.5, 'Animal com quadro gastrointestinal', 'FI', 1, 1, 1);
    PR_ARKIVE_INS_CONSULTA(TO_DATE('2025-02-20 14:15', 'YYYY-MM-DD HH24:MI'), 'REMOTA', 'Tosse seca há 5 dias', 'Tosse produtiva noturna', 'Proprietário relata piora à noite', 8.2, 'Sugestão de traqueobronquite', 'AP', 2, 2, 2);
    PR_ARKIVE_INS_CONSULTA(TO_DATE('2025-03-10 11:00', 'YYYY-MM-DD HH24:MI'), 'PRESENCIAL','Coceira intensa', 'Lesões na pele, vermelhidão', 'Suspeita de dermatite alérgica', 25.3, 'Encaminhado para dermatologista', 'FI', 3, 3, 3);
    PR_ARKIVE_INS_CONSULTA(TO_DATE('2025-04-05 16:45', 'YYYY-MM-DD HH24:MI'), 'PRESENCIAL','Check-up anual', 'Sem sintomas aparentes', 'Animal saudável', 4.8, 'Vacinação em dia', 'FI', 4, 4, 4);
    PR_ARKIVE_INS_CONSULTA(TO_DATE('2025-05-22 09:00', 'YYYY-MM-DD HH24:MI'), 'REMOTA', 'Dificuldade para urinar', 'Esforço ao urinar, pouca quantidade', 'Histórico de cálculo urinário', 5.2, 'Orientado a aumentar água', 'AG', 5, 5, 5);
    PR_ARKIVE_INS_CONSULTA(TO_DATE('2025-06-18 13:20', 'YYYY-MM-DD HH24:MI'), 'PRESENCIAL', 'Manqueira na pata traseira', 'Claudicação intermitente', 'Suspeita de displasia', 28.1, 'Solicitado raio-x', 'EP', 6, 6, 6);
    PR_ARKIVE_INS_CONSULTA(TO_DATE('2025-07-30 10:30', 'YYYY-MM-DD HH24:MI'), 'REMOTA', 'Olho vermelho e lacrimejante', 'Secreção ocular purulenta', 'Possível conjuntivite', 3.7, 'Prescrito colírio', 'FI', 7, 7, 7);
    PR_ARKIVE_INS_CONSULTA(TO_DATE('2025-08-12 15:00', 'YYYY-MM-DD HH24:MI'), 'PRESENCIAL', 'Perda de apetite e emagrecimento', 'Hiporexia há 1 semana', 'Exames laboratoriais solicitados', 18.4, 'Aguardando resultados', 'AG', 8, 8, 8);
    PR_ARKIVE_INS_CONSULTA(TO_DATE('2025-09-25 11:45', 'YYYY-MM-DD HH24:MI'), 'REMOTA', 'Comportamento agressivo', 'Rosna e morde sem aviso', 'Necessário avaliação comportamental', 6.3, 'Encaminhado ao adestrador', 'AP', 9, 9, 9);
    PR_ARKIVE_INS_CONSULTA(TO_DATE('2025-10-03 08:30', 'YYYY-MM-DD HH24:MI'), 'PRESENCIAL', 'Vermelhidão nas orelhas', 'Sacudindo a cabeça, odor fétido', 'Otite externa confirmada', 4.2, 'Limpeza e medicação tópica', 'FI', 10,10, NULL);
    COMMIT;
END;
/
  -- ## 3.14 — TB_ARKIVE_DIAGNOSTICO
BEGIN
    PR_ARKIVE_INS_DIAGNOSTICO('Gastroenterite aguda', 'MODERADA', 'S', 'Possível parvovirose', 85.5, 'S', 1, 1);
    PR_ARKIVE_INS_DIAGNOSTICO('Traqueobronquite infecciosa', 'LEVE', 'S', 'Tosse dos canis', 92.0, 'S', 2, 6);
    PR_ARKIVE_INS_DIAGNOSTICO('Dermatite atópica', 'MODERADA', 'S', 'Alergia alimentar', 78.3, 'N', 3, 7);
    PR_ARKIVE_INS_DIAGNOSTICO('Animal saudável', 'LEVE',   'S', 'Sem anormalidades', 99.0, 'S', 4, NULL);
    PR_ARKIVE_INS_DIAGNOSTICO('Cistite idiopática', 'MODERADA', 'N', 'Possível cálculo uretral', 65.0, NULL, 5, NULL);
    PR_ARKIVE_INS_DIAGNOSTICO('Displasia coxofemoral', 'GRAVE', 'S', 'Sinais radiológicos compatíveis', 94.2, 'S', 6, 9);
    PR_ARKIVE_INS_DIAGNOSTICO('Conjuntivite bacteriana', 'LEVE', 'S', 'Infecção ocular comum', 88.7, 'S', 7, NULL);
    PR_ARKIVE_INS_DIAGNOSTICO('Insuficiência renal', 'GRAVE', 'N', 'Suspeita com base nos sintomas', 72.4, NULL, 8, NULL);
    PR_ARKIVE_INS_DIAGNOSTICO('Transtorno comportamental', 'MODERADA', 'S', 'Ansiedade por separação', 81.0, 'S', 9, 4);
    PR_ARKIVE_INS_DIAGNOSTICO('Otite externa', 'LEVE', 'S', 'Infecção por Malassezia', 96.5, 'S', 10,NULL);
    COMMIT;
END;
/
  -- ## 3.15 — TB_ARKIVE_PRESCRICAO
BEGIN
    PR_ARKIVE_INS_PRESCRICAO('Metronidazol', '50 mg/kg', '12/12 horas', 'ORAL', TO_DATE('2025-01-15 10:30', 'YYYY-MM-DD HH24:MI'), TO_DATE('2025-01-20 22:30', 'YYYY-MM-DD HH24:MI'), 'Administrar após alimentação', 1);
    PR_ARKIVE_INS_PRESCRICAO('Doxiciclina', '10 mg/kg', '24/24 horas', 'ORAL', TO_DATE('2025-02-20 08:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2025-03-05 08:00', 'YYYY-MM-DD HH24:MI'), 'Repouso e evitar contato', 2);
    PR_ARKIVE_INS_PRESCRICAO('Prednisolona', '0.5 mg/kg', '24/24 horas', 'ORAL', TO_DATE('2025-03-10 18:30', 'YYYY-MM-DD HH24:MI'), TO_DATE('2025-03-24 18:30', 'YYYY-MM-DD HH24:MI'), 'Reduzir gradualmente', 3);
    PR_ARKIVE_INS_PRESCRICAO('Antipulgas', '1 comprimido', '30/30 dias','ORAL', TO_DATE('2025-04-05 12:00', 'YYYY-MM-DD HH24:MI'), NULL, 'Aplicar mensalmente', 4);
    PR_ARKIVE_INS_PRESCRICAO('Fenbendazol', '50 mg/kg', '24/24 horas', 'ORAL', TO_DATE('2025-05-22 06:30', 'YYYY-MM-DD HH24:MI'), TO_DATE('2025-05-25 06:30', 'YYYY-MM-DD HH24:MI'), 'Por 3 dias consecutivos', 5);
    PR_ARKIVE_INS_PRESCRICAO('Meloxicam', '0.2 mg/kg', '24/24 horas', 'ORAL', TO_DATE('2025-06-18 14:20', 'YYYY-MM-DD HH24:MI'),TO_DATE('2025-06-25 14:20', 'YYYY-MM-DD HH24:MI'),'Administrar com comida', 6);
    PR_ARKIVE_INS_PRESCRICAO('Colírio antibiótico', '1 gota', '8/8 horas', 'OCULAR', TO_DATE('2025-07-30 08:15', 'YYYY-MM-DD HH24:MI'),TO_DATE('2025-08-06 16:15', 'YYYY-MM-DD HH24:MI'),'Limpar olho antes da aplicação', 7);
    PR_ARKIVE_INS_PRESCRICAO('Fluidoterapia subcutânea', '200 ml', '2x/semana', 'INJETAVEL', TO_DATE('2025-08-13 09:00', 'YYYY-MM-DD HH24:MI'), NULL, 'Realizar na clínica', 8);
    PR_ARKIVE_INS_PRESCRICAO('Trazodona', '5 mg/kg', '12/12 horas', 'ORAL', TO_DATE('2025-09-25 07:20', 'YYYY-MM-DD HH24:MI'), TO_DATE('2025-10-25 19:20', 'YYYY-MM-DD HH24:MI'), 'Usar conforme necessidade', 9);
    PR_ARKIVE_INS_PRESCRICAO('Cerasol', '3 gotas', '12/12 horas', 'OTOLOGICO', TO_DATE('2025-10-03 08:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2025-10-10 20:00', 'YYYY-MM-DD HH24:MI'), 'Massagear a base da orelha', 10);
    COMMIT;
END;
/
  -- ## 3.16 — TB_ARKIVE_AVALIACAO_BEM_ESTAR
BEGIN
    PR_ARKIVE_INS_AVAL_BEM_ESTAR(1, 1, NULL, NULL, TO_DATE('2025-01-10 08:00', 'YYYY-MM-DD HH24:MI'), 3.5, 12.5, 'NORMAL', 'NORMAL', 'NORMAL', 'Animal ativo e saudável');
    PR_ARKIVE_INS_AVAL_BEM_ESTAR(2, 2, NULL, NULL, TO_DATE('2025-02-18 08:00', 'YYYY-MM-DD HH24:MI'), 1.0, 8.0, 'REDUZIDO', 'BAIXA', 'ALTERADO', 'Pouco apetite e letárgico');
    PR_ARKIVE_INS_AVAL_BEM_ESTAR(3, NULL, 3, 3, TO_DATE('2025-03-10 08:00', 'YYYY-MM-DD HH24:MI'), 5.0, 25.0, 'NORMAL', 'NORMAL', 'ANSIOSO', 'Coceira controlada com medicação');
    PR_ARKIVE_INS_AVAL_BEM_ESTAR(4, 4, NULL, NULL, TO_DATE('2025-04-01 08:00', 'YYYY-MM-DD HH24:MI'), 2.0, 4.8, 'NORMAL', 'ALTA', 'NORMAL', 'Bom peso e comportamento');
    PR_ARKIVE_INS_AVAL_BEM_ESTAR(5, NULL, NULL, 5, TO_DATE('2025-05-22 08:00', 'YYYY-MM-DD HH24:MI'), 7.0, 5.2, 'REDUZIDO', 'BAIXA', 'APATICO', 'Esforço urinário observado');
    PR_ARKIVE_INS_AVAL_BEM_ESTAR(6, 6, NULL, NULL, TO_DATE('2025-06-15 08:00', 'YYYY-MM-DD HH24:MI'), 4.0, 28.0, 'NORMAL', 'BAIXA', 'NORMAL', 'Manqueira intermitente');
    PR_ARKIVE_INS_AVAL_BEM_ESTAR(7, 7, NULL, NULL, TO_DATE('2025-07-28 08:00', 'YYYY-MM-DD HH24:MI'), 0.8, 3.5, 'NORMAL', 'NORMAL', 'NORMAL', 'Olho esquerdo lacrimejante');
    PR_ARKIVE_INS_AVAL_BEM_ESTAR(8, NULL, 8, 8, TO_DATE('2025-08-12 08:00', 'YYYY-MM-DD HH24:MI'), 9.0, 18.0, 'SEM APETITE', 'BAIXA', 'ALTERADO', 'Aguardando resultados laboratoriais');
    PR_ARKIVE_INS_AVAL_BEM_ESTAR(9, 9, NULL, NULL, TO_DATE('2025-09-20 08:00', 'YYYY-MM-DD HH24:MI'), 3.0, 6.0, 'AUMENTADO', 'NORMAL', 'AGRESSIVO', 'Comportamento piorou nas últimas semanas');
    PR_ARKIVE_INS_AVAL_BEM_ESTAR(10, NULL, NULL, 10, TO_DATE('2025-10-03 08:00', 'YYYY-MM-DD HH24:MI'), 1.5, 4.2, 'NORMAL', 'NORMAL', 'NORMAL', 'Orelha direita limpa após tratamento');
    COMMIT;
END;
/
  -- ## 3.17 — TB_ARKIVE_PROTOCOLO_PREVENTIVO
BEGIN
    PR_ARKIVE_INS_PROTOCOLO_PREV('Vacina V10', 'VACINA', 'Vacina polivalente para cães', 365, 2, 1, NULL, 'S');
    PR_ARKIVE_INS_PROTOCOLO_PREV('Vacina antirrábica', 'VACINA', 'Vacina contra raiva', 365, 3, 1, NULL, 'S');
    PR_ARKIVE_INS_PROTOCOLO_PREV('Vermífugo trimestral', 'VERMIFUGO', 'Dosagem contra vermes intestinais', 90, 1,  NULL, NULL, 'S');
    PR_ARKIVE_INS_PROTOCOLO_PREV('Check-up geriátrico', 'CHECK-UP', 'Exames para animais idosos', 180, 96, 1, NULL, 'S');
    PR_ARKIVE_INS_PROTOCOLO_PREV('Antipulgas mensal', 'ANTIPARASITARIO', 'Controle de pulgas e carrapatos', 30, 0, 2, NULL, 'S');
    PR_ARKIVE_INS_PROTOCOLO_PREV('Vacina Felina V5', 'VACINA', 'Quádrupla para gatos', 365, 2, 2, NULL, 'S');
    PR_ARKIVE_INS_PROTOCOLO_PREV('Profilaxia odontológica', 'CHECK-UP', 'Limpeza dos dentes', 365, 12, 1, NULL, 'S');
    PR_ARKIVE_INS_PROTOCOLO_PREV('Prevenção dirofilariose', 'ANTIPARASITARIO', 'Medicação contra verme do coração', 30, 3, 1, 1, 'S');
    PR_ARKIVE_INS_PROTOCOLO_PREV('Vacina contra gripe canina', 'VACINA', 'Proteção contra influenza', 365, 2, 1, NULL, 'S');
    PR_ARKIVE_INS_PROTOCOLO_PREV('Controle de giárdia', 'VERMIFUGO', 'Protocolo específico para giardíase', 180, 2,  2, NULL, 'S');
    COMMIT;
END;
/
  -- ## 3.18 — TB_ARKIVE_EVENTO_PREVENTIVO
BEGIN
    PR_ARKIVE_INS_EVENTO_PREV(TO_DATE('2025-01-10 08:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2026-01-10 08:00', 'YYYY-MM-DD HH24:MI'), 'REALIZADO', 'N', 'Vacina aplicada sem intercorrências', 1, 1, NULL);
    PR_ARKIVE_INS_EVENTO_PREV(TO_DATE('2025-02-20 08:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2026-02-20 08:00', 'YYYY-MM-DD HH24:MI'), 'REALIZADO', 'N', 'Antirrábica ok', 2, 2, 2);
    PR_ARKIVE_INS_EVENTO_PREV(NULL, TO_DATE('2025-04-15 08:00', 'YYYY-MM-DD HH24:MI'), 'PENDENTE', 'S', 'Aguardando agendamento', 3, 3, NULL);
    PR_ARKIVE_INS_EVENTO_PREV(TO_DATE('2025-04-05 08:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2025-10-02 08:00', 'YYYY-MM-DD HH24:MI'), 'REALIZADO', 'N', 'Check-up geriátrico normal', 4, 4, 4);
    PR_ARKIVE_INS_EVENTO_PREV(TO_DATE('2025-05-01 08:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2025-05-31 08:00', 'YYYY-MM-DD HH24:MI'), 'REALIZADO', 'N', 'Antipulgas aplicado', 5, 5, NULL);
    PR_ARKIVE_INS_EVENTO_PREV(NULL, TO_DATE('2025-03-20 08:00', 'YYYY-MM-DD HH24:MI'), 'ATRASADO', 'S', 'Vacina atrasada', 6, 6, NULL);
    PR_ARKIVE_INS_EVENTO_PREV(TO_DATE('2025-07-30 08:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2026-07-30 08:00', 'YYYY-MM-DD HH24:MI'), 'REALIZADO', 'N', 'Limpeza dental realizada', 7, 7, 7);
    PR_ARKIVE_INS_EVENTO_PREV(TO_DATE('2025-08-01 08:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2025-08-31 08:00', 'YYYY-MM-DD HH24:MI'), 'REALIZADO', 'N', 'Medicação contra dirofilariose', 8, 8, 8);
    PR_ARKIVE_INS_EVENTO_PREV(NULL, TO_DATE('2025-09-01 08:00', 'YYYY-MM-DD HH24:MI'), 'PENDENTE', 'N', 'Vacina contra gripe não aplicada', 9, 9, NULL);
    PR_ARKIVE_INS_EVENTO_PREV(TO_DATE('2025-10-01 08:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2026-03-30 08:00', 'YYYY-MM-DD HH24:MI'), 'REALIZADO', 'N', 'Tratamento preventivo para giárdia', 10, 10, NULL);
    COMMIT;
END;
/
  -- ## 3.19 — TB_ARKIVE_ALERTA
BEGIN
    PR_ARKIVE_INS_ALERTA('VACINA', 'Vacina V10 do seu pet Rex está próxima do vencimento.', TO_DATE('2025-12-10 08:00', 'YYYY-MM-DD HH24:MI'), NULL, 'ENVIADO', 'APP', 1, 1, NULL, 1);
    PR_ARKIVE_INS_ALERTA('RETORNO', 'Retorno da consulta do animal Luna está pendente.', TO_DATE('2025-03-01 09:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2025-03-02 14:00', 'YYYY-MM-DD HH24:MI'), 'LIDO', 'WHATSAPP', 2, 2, NULL, NULL);
    PR_ARKIVE_INS_ALERTA('MEDICAMENTO', 'Medicação do Thor deve ser administrada hoje.', TO_DATE('2025-03-12 07:30', 'YYYY-MM-DD HH24:MI'), NULL, 'ENVIADO', 'EMAIL', 3, 3, 3, 3);
    PR_ARKIVE_INS_ALERTA('CHECK-UP', 'Check-up anual do Mel está agendado.', TO_DATE('2025-04-01 10:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2025-04-01 10:05', 'YYYY-MM-DD HH24:MI'),'LIDO', 'APP', 4, 4, NULL, 4);
    PR_ARKIVE_INS_ALERTA('VACINA', 'Vacina antirrábica do Simba está atrasada.', TO_DATE('2025-03-25 11:00', 'YYYY-MM-DD HH24:MI'), NULL, 'IGNORADO', 'WHATSAPP', 5, 5, NULL, NULL);
    PR_ARKIVE_INS_ALERTA('RETORNO', 'Reavaliação do caso do Bilu é necessária.', TO_DATE('2025-06-20 08:00', 'YYYY-MM-DD HH24:MI'), NULL, 'ENVIADO', 'EMAIL', 6, 6, 6, 6);
    PR_ARKIVE_INS_ALERTA('MEDICAMENTO','Colírio do Nina deve ser aplicado.', TO_DATE('2025-07-31 08:30', 'YYYY-MM-DD HH24:MI'), NULL, 'ENVIADO', 'APP', 7, 7, 7, 7);
    PR_ARKIVE_INS_ALERTA('CHECK-UP',  'Check-up geriátrico do Bob está pendente.', TO_DATE('2025-09-01 09:00', 'YYYY-MM-DD HH24:MI'), NULL,                                        'ENVIADO', 'WHATSAPP', 8, 8, 8, 8);
    PR_ARKIVE_INS_ALERTA('VACINA', 'Vacina contra gripe para o Frajola foi esquecida.', TO_DATE('2025-10-01 07:00', 'YYYY-MM-DD HH24:MI'), NULL,                                        'ENVIADO', 'EMAIL', 9, 9, 9, 9);
    PR_ARKIVE_INS_ALERTA('RETORNO', 'Consulta de retorno da Pandora deve ser agendada.', TO_DATE('2025-10-05 10:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2025-10-06 18:00', 'YYYY-MM-DD HH24:MI'), 'LIDO', 'APP', 10, 10, 10, 10);
    COMMIT;
END;
/
  -- ## 3.20 — TB_ARKIVE_EVENTO_JORNADA
BEGIN
    PR_ARKIVE_INS_EVENTO_JORNADA('ANIMAL_CADASTRADO', SYSDATE, 'APP', 'RESPONSAVEL', 1, NULL, 1, NULL, 'MOBILE', 'Cadastro do animal Rex', '{"peso": 12.5, "castrado": true}');
    PR_ARKIVE_INS_EVENTO_JORNADA('CONSULTA_CRIADA', TO_DATE('2025-01-10 10:00', 'YYYY-MM-DD HH24:MI'), 'WEB', 'VETERINARIO', NULL,1, 1, 1, 'WEB', 'Consulta presencial criada', '{"motivo": "Vômito"}');
    PR_ARKIVE_INS_EVENTO_JORNADA('ALERTA_LIDO', TO_DATE('2025-03-02 14:00', 'YYYY-MM-DD HH24:MI'), 'WHATSAPP', 'RESPONSAVEL', 2, NULL, 2, NULL, 'WHATSAPP', 'Leitura de alerta de retorno', '{"alerta_id": 2}');
    PR_ARKIVE_INS_EVENTO_JORNADA('DIAGNOSTICO_CONFIRMADO', TO_DATE('2025-03-11 16:00', 'YYYY-MM-DD HH24:MI'), 'API', 'IA', NULL, NULL, 3, 3, 'API', 'Confirmação de insight de IA', '{"confianca": 78.3}');
    PR_ARKIVE_INS_EVENTO_JORNADA('PRESCRICAO_EMITIDA', TO_DATE('2025-03-10 15:30', 'YYYY-MM-DD HH24:MI'), 'SISTEMA', 'VETERINARIO', NULL, 3, 3, 3, 'SISTEMA', 'Prescrição gerada', '{"medicamento": "Prednisolona"}');
    PR_ARKIVE_INS_EVENTO_JORNADA('AVALIACAO_BEM_ESTAR', SYSDATE, 'APP', 'RESPONSAVEL', 4, NULL, 4, NULL, 'MOBILE', 'Nova avaliação de bem-estar', '{"peso": 4.8, "apetite": "NORMAL"}');
    PR_ARKIVE_INS_EVENTO_JORNADA('EVENTO_PREV_ATRASADO', TO_DATE('2025-03-21 00:00', 'YYYY-MM-DD HH24:MI'), 'SISTEMA', 'SISTEMA', NULL, NULL, 6, NULL, 'JOB', 'Disparo automático de atraso', '{"protocolo": "Vacina Felina V5"}');
    PR_ARKIVE_INS_EVENTO_JORNADA('FEEDBACK_ENVIADO', TO_DATE('2025-03-02 18:00', 'YYYY-MM-DD HH24:MI'), 'APP', 'RESPONSAVEL', 2, NULL, 2, 2, 'MOBILE', 'Feedback NPS enviado', '{"nota": 9}');
    PR_ARKIVE_INS_EVENTO_JORNADA('VINCULO_RESP_ANIMAL', SYSDATE, 'WEB', 'CLINICA', NULL, NULL, 8, 8, 'WEB', 'Responsável associado ao animal', '{"tipo_vinculo": "TUTOR_LEGAL"}');
    PR_ARKIVE_INS_EVENTO_JORNADA('ADESAO_PRESCRICAO', TO_DATE('2025-10-04 12:00', 'YYYY-MM-DD HH24:MI'), 'APP', 'RESPONSAVEL', 10, NULL, 10, NULL, 'MOBILE', 'Registro de adesão a prescrição', '{"tomou": "S"}');
    COMMIT;
END;
/
  -- ## 3.21 — TB_ARKIVE_ADESAO_PRESCRICAO
BEGIN
    PR_ARKIVE_INS_ADESAO_PRESCRICAO(1, 1, 1,  TO_DATE('2025-01-16 10:00', 'YYYY-MM-DD HH24:MI'), 'S', 'Medicação administrada corretamente');
    PR_ARKIVE_INS_ADESAO_PRESCRICAO(2, 2, 2,  TO_DATE('2025-02-21 19:00', 'YYYY-MM-DD HH24:MI'), 'S', 'Dose noturna esquecida, compensada no dia seguinte');
    PR_ARKIVE_INS_ADESAO_PRESCRICAO(3, 3, 3,  TO_DATE('2025-03-11 08:30', 'YYYY-MM-DD HH24:MI'), 'N', 'Animal vomitou após administração');
    PR_ARKIVE_INS_ADESAO_PRESCRICAO(4, 4, 4,  TO_DATE('2025-04-06 09:00', 'YYYY-MM-DD HH24:MI'), 'S', 'Aplicação mensal realizada');
    PR_ARKIVE_INS_ADESAO_PRESCRICAO(5, 5, 5,  TO_DATE('2025-05-23 20:00', 'YYYY-MM-DD HH24:MI'), 'S', 'Todas as doses administradas');
    PR_ARKIVE_INS_ADESAO_PRESCRICAO(6, 6, 6,  TO_DATE('2025-06-19 12:30', 'YYYY-MM-DD HH24:MI'), 'S', 'Animal melhorou da claudicação');
    PR_ARKIVE_INS_ADESAO_PRESCRICAO(7, 7, 7,  TO_DATE('2025-07-31 21:00', 'YYYY-MM-DD HH24:MI'), 'N', 'Responsável relatou dificuldade para aplicar colírio');
    PR_ARKIVE_INS_ADESAO_PRESCRICAO(8, 8, 8,  TO_DATE('2025-08-14 14:00', 'YYYY-MM-DD HH24:MI'), 'S', 'Fluidoterapia realizada conforme orientação');
    PR_ARKIVE_INS_ADESAO_PRESCRICAO(9, 9, 9,  TO_DATE('2025-09-26 18:30', 'YYYY-MM-DD HH24:MI'), 'S', 'Medicação controlou agressividade');
    PR_ARKIVE_INS_ADESAO_PRESCRICAO(10, 10, 10, TO_DATE('2025-10-04 09:00', 'YYYY-MM-DD HH24:MI'), 'S', 'Tratamento concluído com sucesso');
    COMMIT;
END;
/
  -- ## 3.22 — TB_ARKIVE_FEEDBACK_NPS
BEGIN
    PR_ARKIVE_INS_FEEDBACK_NPS(1, 1, 1, 1, 1, 5, 'Atendimento excelente, muito profissional!', TO_DATE('2025-01-16 13:13', 'YYYY-MM-DD HH24:MI'));
    PR_ARKIVE_INS_FEEDBACK_NPS(2, 2, 2, 2, 2, 5, 'Boa orientação, mas demorou um pouco', TO_DATE('2025-02-22 13:13', 'YYYY-MM-DD HH24:MI'));
    PR_ARKIVE_INS_FEEDBACK_NPS(NULL, 3, 3, 3, 3, 4, 'Medicação causou efeito colateral, não esperava', TO_DATE('2025-03-12 13:13', 'YYYY-MM-DD HH24:MI'));
    PR_ARKIVE_INS_FEEDBACK_NPS(4, 4, 4, 4, 4, 5, 'Check-up rápido e eficiente', TO_DATE('2025-04-06 13:13', 'YYYY-MM-DD HH24:MI'));
    PR_ARKIVE_INS_FEEDBACK_NPS(NULL, 5, 5, 5, 5, 3, 'A consulta remota não resolveu meu problema', TO_DATE('2025-05-23 13:13', 'YYYY-MM-DD HH24:MI'));
    PR_ARKIVE_INS_FEEDBACK_NPS(6, 6, 6, 6, 6, 4, 'Bom atendimento, mas precisei voltar', TO_DATE('2025-06-20 13:13', 'YYYY-MM-DD HH24:MI'));
    PR_ARKIVE_INS_FEEDBACK_NPS(NULL, 7, 7, 7, 7, 5, 'Colírio resolveu rapidamente', TO_DATE('2025-07-31 13:13', 'YYYY-MM-DD HH24:MI'));
    PR_ARKIVE_INS_FEEDBACK_NPS(8, 8, 8, 8, 8, 3, 'Aguardei muito pelos resultados', TO_DATE('2025-08-15 13:13', 'YYYY-MM-DD HH24:MI'));
    PR_ARKIVE_INS_FEEDBACK_NPS(9, 9, 9, 9, 9, 5, 'O adestrador resolveu o problema comportamental', TO_DATE('2025-09-27 13:13', 'YYYY-MM-DD HH24:MI'));
    PR_ARKIVE_INS_FEEDBACK_NPS(10, 10, 10, NULL, 10, 4, 'Tratamento da otite foi eficaz', TO_DATE('2025-10-05 13:13', 'YYYY-MM-DD HH24:MI'));
    COMMIT;
END;
/
/*
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================

FIM DO SCRIPT

  Total de objetos criados:
  ──────────────────────────────────────────────────────────────────────────────
    1 Procedure auxiliar             (PR_ARKIVE_REG_ERRO)
   22 Procedures de carga            (PR_ARKIVE_INS_*)
   22 Blocos de chamada de carga     (Seção # 3)
*/
