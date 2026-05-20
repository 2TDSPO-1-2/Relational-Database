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
   # 1 ─  Dois blocos anônimos de exibição com 'JOINs';
   # 2 ─  Bloco com 'LAG' / 'LEAD' (anterior, atual e próxima);
   # 3 ─  Quatro blocos com cursor explícito e decisão;
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
==================================================================================
   # 1 — TESTE DE BLOCOS ANÔNIMOS DE EXIBIÇÃO COM JOINS, GROUP BY E ORDER BY
  ──────────────────────────────────────────────────────────────────────────────
*/

   -- ## 1.1 — Consultas clínicas:
   --         atendimentos por clínica/veterinário e perfil de espécies
   --         com contagem de consultas.
  
DECLARE
    v_sep VARCHAR2(80) := RPAD('=', 80, '=');
    v_lin VARCHAR2(80) := RPAD('-', 80, '-');
BEGIN

    -- ### CONSULTA A: Total de atendimentos e peso médio por clínica
    --                (JOIN: CONSULTA ⟶ CLINICA)

    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  RELATÓRIO 1.1-A: Atendimentos e Peso Médio por Clínica');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(RPAD('CLÍNICA', 36) || LPAD('CONSULTAS', 10) || LPAD('PESO MÉDIO', 12) || LPAD('PESO MÁXIMO', 13));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    FOR r IN (
    	SELECT
    		c.NM_CLINICA,
    		COUNT(co.ID_CONSULTA) AS QTD_CONSULTAS,
    		ROUND(AVG(co.KG_PESO), 2) AS PESO_MEDIO,
    		MAX(co.KG_PESO) AS PESO_MAXIMO
        	FROM TB_ARKIVE_CONSULTA co
        		JOIN TB_ARKIVE_CLINICA c ON co.ID_CLINICA = c.ID_CLINICA
        	GROUP BY c.NM_CLINICA
        	ORDER BY QTD_CONSULTAS DESC, c.NM_CLINICA
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(r.NM_CLINICA, 36) || LPAD(r.QTD_CONSULTAS, 10) || LPAD(NVL(TO_CHAR(r.PESO_MEDIO, '999.99'), '  N/D'), 12) || LPAD(NVL(TO_CHAR(r.PESO_MAXIMO, '999.99'), '  N/D'), 13));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(' ');

    -- ### CONSULTA B: Total de animais e consultas por espécie e porte de raça
    --                (JOIN: ANIMAL ⟶ ESPECIE ⟶ RACA
    -- 			    LEFT JOIN CONSULTA)
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  RELATÓRIO 1.1-B: Animais e Consultas por Espécie e Porte de Raça');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(RPAD('ESPÉCIE', 14) || RPAD('PORTE', 10) || LPAD('ANIMAIS', 9) || LPAD('CONSULTAS', 11));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    FOR r IN (
        SELECT
        	e.NM_ESPECIE,
        	NVL(r.TP_PORTE, 'NÃO INFORMADO') AS TP_PORTE,
        	COUNT(DISTINCT a.ID_ANIMAL) AS QTD_ANIMAIS,
        	COUNT(co.ID_CONSULTA) AS QTD_CONSULTAS
        	FROM TB_ARKIVE_ANIMAL a
        		JOIN TB_ARKIVE_ESPECIE e ON a.ID_ESPECIE = e.ID_ESPECIE
        		LEFT JOIN TB_ARKIVE_RACA r ON a.ID_RACA = r.ID_RACA
        		LEFT JOIN TB_ARKIVE_CONSULTA co ON a.ID_ANIMAL = co.ID_ANIMAL
        	GROUP BY e.NM_ESPECIE, r.TP_PORTE
        	ORDER BY QTD_ANIMAIS DESC, e.NM_ESPECIE
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(r.NM_ESPECIE, 14) || RPAD(r.TP_PORTE, 10) || LPAD(r.QTD_ANIMAIS, 9) || LPAD(r.QTD_CONSULTAS, 11));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(' ');

    -- ### CONSULTA C: Responsáveis com seus animais e total de consultas
    --                (JOIN: RESPONSAVEL ⟶ RESPONSAVEL_ANIMAL ⟶ ANIMAL ⟶ ESPECIE
    --                 	    LEFT JOIN CONSULTA)
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  RELATÓRIO 1.1-C: Responsáveis, Animais e Total de Consultas');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(RPAD('RESPONSÁVEL', 22) || RPAD('ANIMAL', 10) || RPAD('ESPÉCIE', 10) || RPAD('TIPO VÍNCULO', 26) || LPAD('CONSULTAS', 9));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    FOR r IN (
        SELECT
        	re.NM_RESPONSAVEL,
        	a.NM_ANIMAL,
        	e.NM_ESPECIE,
        	ra.TP_VINCULO,
		COUNT(co.ID_CONSULTA) AS QTD_CONSULTAS
        	FROM TB_ARKIVE_RESPONSAVEL re
        		JOIN TB_ARKIVE_RESPONSAVEL_ANIMAL ra ON re.ID_RESPONSAVEL = ra.ID_RESPONSAVEL
        		JOIN TB_ARKIVE_ANIMAL a ON ra.ID_ANIMAL = a.ID_ANIMAL
        		JOIN TB_ARKIVE_ESPECIE e ON a.ID_ESPECIE = e.ID_ESPECIE
        		LEFT JOIN TB_ARKIVE_CONSULTA co ON a.ID_ANIMAL = co.ID_ANIMAL
        	WHERE ra.ST_ATIVO = 'S'
        	GROUP BY re.NM_RESPONSAVEL, a.NM_ANIMAL, e.NM_ESPECIE, ra.TP_VINCULO
        	ORDER BY re.NM_RESPONSAVEL, QTD_CONSULTAS DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(r.NM_RESPONSAVEL, 22) || RPAD(r.NM_ANIMAL, 10) || RPAD(r.NM_ESPECIE, 10) || RPAD(r.TP_VINCULO, 26) || LPAD(r.QTD_CONSULTAS, 9));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(v_sep);
END;
/

   -- ## 1.2 — NPS por veterinário/especialidade e aderência a protocolos.
  
DECLARE
    v_sep VARCHAR2(80) := RPAD('=', 80, '=');
    v_lin VARCHAR2(80) := RPAD('-', 80, '-');
BEGIN

    -- ### CONSULTA A: Nota NPS média por veterinário e especialidade
    -- 		      (JOIN: FEEDBACK_NPS ⟶ VETERINARIO)
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  RELATÓRIO 1.2-A: Nota NPS por Veterinário e Especialidade');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE( RPAD('VETERINÁRIO', 22) || RPAD('ESPECIALIDADE', 18) || LPAD('FEEDBACKS', 10) || LPAD('NOTA MÉDIA', 12) || LPAD('NOTA MÍNIMA', 13) || LPAD('NOTA MÁXIMA', 13));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    FOR r IN (
        SELECT
        	v.NM_VETERINARIO,
        	NVL(v.DS_ESPECIALIDADE, 'Não informada') AS DS_ESPECIALIDADE,
        	COUNT(n.ID_FEEDBACK_NPS) AS QTD_FEEDBACKS,
        	ROUND(AVG(n.NR_NOTA), 2) AS NOTA_MEDIA,
        	MIN(n.NR_NOTA) AS NOTA_MIN,
        	MAX(n.NR_NOTA) AS NOTA_MAX
        	FROM TB_ARKIVE_VETERINARIO v
        		JOIN TB_ARKIVE_FEEDBACK_NPS n ON v.ID_VETERINARIO = n.ID_VETERINARIO
        	GROUP BY v.NM_VETERINARIO, v.DS_ESPECIALIDADE
        	ORDER BY NOTA_MEDIA DESC, v.NM_VETERINARIO
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(r.NM_VETERINARIO, 22) || RPAD(r.DS_ESPECIALIDADE, 18) || LPAD(r.QTD_FEEDBACKS, 10) || LPAD(TO_CHAR(r.NOTA_MEDIA,'999.99'), 12) || LPAD(r.NOTA_MIN, 13) || LPAD(r.NOTA_MAX, 13));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(' ');

    -- ### CONSULTA B: Aderência a protocolos preventivos por tipo
    -- 		      (JOIN: EVENTO_PREVENTIVO ⟶ PROTOCOLO_PREVENTIVO)
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  RELATÓRIO 1.2-B: Aderência a Protocolos Preventivos por Tipo');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(RPAD('TIPO PROTOCOLO', 18) || LPAD('TOTAL', 7) || LPAD('REALIZADOS', 12) || LPAD('PENDENTES', 11) || LPAD('ATRASADOS', 11) || LPAD('% REALIZADO', 13));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    FOR r IN (
        SELECT
        	pp.TP_PROTOCOLO,
        	COUNT(*) AS TOTAL,
        	SUM(CASE WHEN ep.ST_STATUS = 'REALIZADO' THEN 1 ELSE 0 END) AS REALIZADOS,
        	SUM(CASE WHEN ep.ST_STATUS = 'PENDENTE' THEN 1 ELSE 0 END) AS PENDENTES,
        	SUM(CASE WHEN ep.ST_STATUS = 'ATRASADO' THEN 1 ELSE 0 END) AS ATRASADOS,
        	ROUND(SUM(CASE WHEN ep.ST_STATUS = 'REALIZADO' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS PCT_REALIZADO
        	FROM TB_ARKIVE_EVENTO_PREVENTIVO ep
        		JOIN TB_ARKIVE_PROTOCOLO_PREVENTIVO pp ON ep.ID_PROTOCOLO = pp.ID_PROTOCOLO
        	GROUP BY pp.TP_PROTOCOLO
        	ORDER BY TOTAL DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(r.TP_PROTOCOLO, 18) || LPAD(r.TOTAL, 7) || LPAD(r.REALIZADOS, 12) || LPAD(r.PENDENTES, 11) || LPAD(r.ATRASADOS, 11) || LPAD(TO_CHAR(r.PCT_REALIZADO, '999.9') || '%', 13));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(v_sep);
END;
/

/*
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================
   # 2 — TESTE DE BLOCO COM LAG / LEAD
  ──────────────────────────────────────────────────────────────────────────────
*/

DECLARE
    v_sep VARCHAR2(90) := RPAD('=', 90, '=');
    v_lin VARCHAR2(90) := RPAD('-', 90, '-');
    v_peso_ant_str VARCHAR2(10);
    v_peso_prx_str VARCHAR2(10);

    CURSOR c_lag_lead IS
        SELECT
        	a.NM_ANIMAL,
        	TO_CHAR(ab.DT_AVALIACAO, 'DD/MM/YYYY HH24:MI:SS') AS DT_AVAL,
        	ab.DS_COMPORTAMENTO,
        	ab.KG_PESO AS PESO_ATUAL,
        	LAG (ab.KG_PESO) OVER (ORDER BY ab.DT_AVALIACAO) AS PESO_ANT,
        	LEAD(ab.KG_PESO) OVER (ORDER BY ab.DT_AVALIACAO) AS PESO_PRX
        	FROM TB_ARKIVE_AVALIACAO_BEM_ESTAR ab
        		JOIN TB_ARKIVE_ANIMAL a ON ab.ID_ANIMAL = a.ID_ANIMAL
		ORDER BY ab.DT_AVALIACAO;

BEGIN
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  RELATÓRIO 2: Evolução de Peso — Linha Anterior / Atual / Próxima');
    DBMS_OUTPUT.PUT_LINE('  Tabela: TB_ARKIVE_AVALIACAO_BEM_ESTAR  |  Coluna: KG_PESO');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(RPAD('ANIMAL', 10) || RPAD('DATA', 12) || RPAD('COMPORTAMENTO', 14) || LPAD('PESO ANTERIOR', 14) || LPAD('PESO ATUAL', 11) || LPAD('PRÓXIMO PESO', 13));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    FOR r IN c_lag_lead LOOP
        IF r.PESO_ANT IS NULL THEN
            v_peso_ant_str := 'Vazio';
        ELSE
            v_peso_ant_str := TO_CHAR(r.PESO_ANT, 'FM999.99') || ' kg';
        END IF;

        IF r.PESO_PRX IS NULL THEN
            v_peso_prx_str := 'Vazio';
        ELSE
            v_peso_prx_str := TO_CHAR(r.PESO_PRX, 'FM999.99') || ' kg';
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD(r.NM_ANIMAL, 10) || RPAD(r.DT_AVAL, 12) || RPAD(NVL(r.DS_COMPORTAMENTO,'—'), 14) || LPAD(v_peso_ant_str, 14) || LPAD(TO_CHAR(r.PESO_ATUAL,'FM999.99') || ' kg', 11) || LPAD(v_peso_prx_str, 13));
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  Observação: "Vazio" indica ausência de linha anterior ou seguinte.');
    DBMS_OUTPUT.PUT_LINE(v_sep);
END;
/
/*
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================
   # 3 — TESTE DE BLOCOS ANÔNIMOS COM CURSOR EXPLÍCITO E TOMADA DE DECISÃO
  ──────────────────────────────────────────────────────────────────────────────
*/

   -- ## 3.1 — RELATÓRIO COMPLETO DE FEEDBACK NPS
   -- 	      Lista todos os registros, sumariza os dados numéricos e apresenta
   --	      agrupamento por categoria NPS (Promotor / Neutro / Detrator).
   
DECLARE
    v_sep VARCHAR2(90) := RPAD('=', 90, '=');
    v_lin VARCHAR2(90) := RPAD('-', 90, '-');

    -- >> Cursor explícito: todos os registros de NPS com JOINs para nomes
    CURSOR c_nps IS
	SELECT
		n.ID_FEEDBACK_NPS,
		NVL(v.NM_VETERINARIO, '—') AS NM_VET,
		NVL(re.NM_RESPONSAVEL, '—') AS NM_RESP,
		NVL(a.NM_ANIMAL, '—') AS NM_ANIMAL,
		NVL(cl.NM_CLINICA, '—') AS NM_CLINICA,
        	n.NR_NOTA,
        	TO_CHAR(n.DT_FEEDBACK, 'DD/MM/YYYY HH24:MI:SS') AS DT_FB
        	FROM TB_ARKIVE_FEEDBACK_NPS n
        		LEFT JOIN TB_ARKIVE_VETERINARIO v ON n.ID_VETERINARIO = v.ID_VETERINARIO
        		LEFT JOIN TB_ARKIVE_RESPONSAVEL re ON n.ID_RESPONSAVEL = re.ID_RESPONSAVEL
        		LEFT JOIN TB_ARKIVE_ANIMAL a ON n.ID_ANIMAL = a.ID_ANIMAL
        		LEFT JOIN TB_ARKIVE_CLINICA cl ON n.ID_CLINICA = cl.ID_CLINICA
        	ORDER BY n.DT_FEEDBACK;

    -- >> Cursor para sumarização agrupada por categoria
    CURSOR c_nps_grupo IS
        SELECT
        	CASE
        		WHEN NR_NOTA BETWEEN 9 AND 10 THEN 'Promotor (9-10)'
        		WHEN NR_NOTA BETWEEN 7 AND 8 THEN 'Neutro (7-8)'
			ELSE 'Detrator  (0-6) '
        	END
        	AS CATEGORIA,
            	COUNT(*) AS QTD,
            	ROUND(AVG(NR_NOTA), 2) AS MEDIA, MIN(NR_NOTA) AS MINIMA, MAX(NR_NOTA) AS MAXIMA
        	FROM TB_ARKIVE_FEEDBACK_NPS
        	GROUP BY
            		CASE
               			WHEN NR_NOTA BETWEEN 9 AND 10 THEN 'Promotor  (9-10)'
               			WHEN NR_NOTA BETWEEN 7 AND 8  THEN 'Neutro (7-8) '
                		ELSE 'Detrator (0-6) '
            		END
            	ORDER BY MEDIA DESC;

    -- >> Variáveis de acumulação para sumarização geral
    v_total   NUMBER := 0;
    v_soma    NUMBER := 0;
    v_maximo  NUMBER := 0;
    v_minimo  NUMBER := 10;
    v_cat     VARCHAR2(20);

    -- >> Variáveis %ROWTYPE para os cursores
    v_nps       c_nps%ROWTYPE;
    v_nps_grupo c_nps_grupo%ROWTYPE;

BEGIN

    -- ### 3.1-A: Listagem completa
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  CONSULTA 3.1-A: RELATÓRIO COMPLETO DE FEEDBACK NPS');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(LPAD('ID', 4) || '  ' || RPAD('VETERINÁRIO', 22) || RPAD('RESPONSÁVEL', 22) || RPAD('ANIMAL', 8) || LPAD('NOTA', 5) || '  ' || RPAD('DATA', 12));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    OPEN c_nps;
    LOOP
        FETCH c_nps INTO v_nps;
        EXIT WHEN c_nps%NOTFOUND;

        -- >> Acumula para sumarização
        v_total := v_total + 1;
        v_soma := v_soma + v_nps.NR_NOTA;
        IF v_nps.NR_NOTA > v_maximo THEN v_maximo := v_nps.NR_NOTA; END IF;
        IF v_nps.NR_NOTA < v_minimo THEN v_minimo := v_nps.NR_NOTA; END IF;

        -- >> Tomada de decisão: classificação NPS
        IF v_nps.NR_NOTA >= 9 THEN v_cat := '★★ Promotor';
        ELSIF v_nps.NR_NOTA >= 7 THEN v_cat := '◆  Neutro';
        ELSE v_cat := '▼  Detrator';
        END IF;

        DBMS_OUTPUT.PUT_LINE(LPAD(v_nps.ID_FEEDBACK_NPS, 4) || '  ' || RPAD(SUBSTR(v_nps.NM_VET,  1, 20), 22) || RPAD(SUBSTR(v_nps.NM_RESP, 1, 20), 22) || RPAD(v_nps.NM_ANIMAL, 8) || LPAD(v_nps.NR_NOTA,   5) || '  ' || RPAD(v_nps.DT_FB, 12) || ' [' || v_cat || ']');
    END LOOP;
    CLOSE c_nps;

    --  ### 3.1-B: Sumarização dos dados numéricos
    DBMS_OUTPUT.PUT_LINE(v_lin);
    DBMS_OUTPUT.PUT_LINE('  CONSULTA 3.1-B: SUMARIZAÇÃO GERAL (NR_NOTA)');
    DBMS_OUTPUT.PUT_LINE(v_lin);
    DBMS_OUTPUT.PUT_LINE('  Total de feedbacks  : ' || v_total);
    DBMS_OUTPUT.PUT_LINE('  Soma das notas      : ' || v_soma);
    DBMS_OUTPUT.PUT_LINE('  Nota média          : ' || TO_CHAR(v_soma / NULLIF(v_total, 0), 'FM999.99'));
    DBMS_OUTPUT.PUT_LINE('  Nota máxima         : ' || v_maximo);
    DBMS_OUTPUT.PUT_LINE('  Nota mínima         : ' || v_minimo);

    -- >> NPS Score = (%Promotores - %Detratores)
    DECLARE
        v_promotores NUMBER;
        v_detratores NUMBER;
    BEGIN
        SELECT
		SUM(CASE WHEN NR_NOTA >= 9 THEN 1 ELSE 0 END),
		SUM(CASE WHEN NR_NOTA <= 6 THEN 1 ELSE 0 END)
		INTO v_promotores, v_detratores
		FROM TB_ARKIVE_FEEDBACK_NPS;

        DBMS_OUTPUT.PUT_LINE('  NPS Score           : ' || TO_CHAR(ROUND((v_promotores - v_detratores) * 100.0 / NULLIF(v_total, 0), 1)) || ' pts');
    END;

    -- ### 3.1-C: Sumarização agrupada por categoria NPS
    DBMS_OUTPUT.PUT_LINE(v_lin);
    DBMS_OUTPUT.PUT_LINE('  CONSULTA 3.1-C: SUMARIZAÇÃO POR CATEGORIA NPS');
    DBMS_OUTPUT.PUT_LINE(v_lin);
    DBMS_OUTPUT.PUT_LINE(RPAD('CATEGORIA', 18) || LPAD('QTD', 5) || LPAD('MÉDIA', 10) || LPAD('MÍN', 6) || LPAD('MÁX', 6));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    OPEN c_nps_grupo;
    LOOP
        FETCH c_nps_grupo INTO v_nps_grupo;
        EXIT WHEN c_nps_grupo%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(RPAD(v_nps_grupo.CATEGORIA, 18) || LPAD(v_nps_grupo.QTD, 5) || LPAD(TO_CHAR(v_nps_grupo.MEDIA, 'FM999.99'), 10) || LPAD(v_nps_grupo.MINIMA, 6) || LPAD(v_nps_grupo.MAXIMA, 6));
    END LOOP;
    CLOSE c_nps_grupo;

    DBMS_OUTPUT.PUT_LINE(v_sep);
END;
/

-- ## 3.2 — RELATÓRIO DE CONSULTAS POR STATUS
--	   Lista todas as consultas com tradução do código de status e sinaliza
--	   consultas com peso acima do limite para a espécie.

DECLARE
    v_sep VARCHAR2(90) := RPAD('=', 90, '=');
    v_lin VARCHAR2(90) := RPAD('-', 90, '-');
    v_ds_status VARCHAR2(30);
    v_alerta_peso VARCHAR2(10);

    CURSOR c_consultas IS
        SELECT
		co.ID_CONSULTA,
		TO_CHAR(co.DT_HORA, 'DD/MM/YYYY HH24:MI:SS') AS DT_CONS,
		a.NM_ANIMAL,
		e.NM_ESPECIE,
		v.NM_VETERINARIO,
		co.TP_MODALIDADE,
		co.ST_STATUS,
		co.KG_PESO
		FROM TB_ARKIVE_CONSULTA co
			JOIN TB_ARKIVE_ANIMAL a ON co.ID_ANIMAL = a.ID_ANIMAL
			JOIN TB_ARKIVE_ESPECIE e ON a.ID_ESPECIE = e.ID_ESPECIE
			JOIN TB_ARKIVE_VETERINARIO v ON co.ID_VETERINARIO  = v.ID_VETERINARIO
		ORDER BY co.DT_HORA;

    -- >> Variável %ROWTYPE para o cursor
    v_cons c_consultas%ROWTYPE;

BEGIN
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  CONSULTA 3.2: RELATÓRIO DE CONSULTAS POR STATUS E MODALIDADE');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(LPAD('ID', 4) || '  ' || RPAD('DATA', 12) || RPAD('ANIMAL', 9) || RPAD('ESPÉCIE', 9) || RPAD('VETERINÁRIO', 24) || RPAD('MODALIDADE', 12) || RPAD('STATUS', 22) || LPAD('PESO', 7));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    OPEN c_consultas;
    LOOP
        FETCH c_consultas INTO v_cons;
        EXIT WHEN c_consultas%NOTFOUND;

        -- >> Tomada de decisão: traduz código ST_STATUS
        CASE v_cons.ST_STATUS
        	WHEN 'AG' THEN v_ds_status := 'Agendada';
        	WHEN 'EP' THEN v_ds_status := 'Em Progresso';
        	WHEN 'AP' THEN v_ds_status := 'Aguardando Pagamento';
        	WHEN 'FI' THEN v_ds_status := 'Finalizada';
        	WHEN 'CA' THEN v_ds_status := 'Cancelada';
        	ELSE v_ds_status := '[?] Desconhecido';
        END CASE;

        -- >> Tomada de decisão: sinaliza peso elevado (> 20 kg)
        IF v_cons.KG_PESO IS NULL THEN
            v_alerta_peso := '  N/D';
        ELSIF v_cons.KG_PESO > 20 THEN
            v_alerta_peso := TO_CHAR(v_cons.KG_PESO, 'FM999.99') || '⚠';
        ELSE
            v_alerta_peso := TO_CHAR(v_cons.KG_PESO, 'FM999.99');
        END IF;

        DBMS_OUTPUT.PUT_LINE(LPAD(v_cons.ID_CONSULTA, 4) || '  ' ||
            RPAD(v_cons.DT_CONS, 12) || RPAD(v_cons.NM_ANIMAL, 9) || RPAD(v_cons.NM_ESPECIE, 9) || RPAD(SUBSTR(v_cons.NM_VETERINARIO, 1, 22), 24) || RPAD(v_cons.TP_MODALIDADE,12) || RPAD(v_ds_status, 22) || LPAD(v_alerta_peso, 7));
    END LOOP;
    CLOSE c_consultas;

    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  Legenda status: | AG = Agendada | EP = Em Progresso | AP = Ag.Pagamento | FI = Finalizada | CA = Cancelada |');
    DBMS_OUTPUT.PUT_LINE('  [!] Peso acima de 20 kg — atenção na dosagem de medicamentos!');
    DBMS_OUTPUT.PUT_LINE(v_sep);
END;
/

-- ## 3.3 — RELATÓRIO DE PRESCRIÇÕES POR VIA DE ADMINISTRAÇÃO
-- 	   Lista todas as prescrições ativas, classifica a via de administração e
-- 	   indica se o tratamento ainda está em andamento.

DECLARE
    v_sep VARCHAR2(90) := RPAD('=', 90, '=');
    v_lin VARCHAR2(90) := RPAD('-', 90, '-');
    v_via_desc VARCHAR2(30);
    v_situacao VARCHAR2(20);

    CURSOR c_prescricoes IS
        SELECT
		p.ID_PRESCRICAO,
		p.NM_MEDICAMENTO,
		p.DS_DOSAGEM,
		p.DS_FREQUENCIA,
		NVL(p.TP_VIA_ADMINISTRACAO, 'NÃO INFORMADO') AS TP_VIA,
		TO_CHAR(p.DT_INICIO, 'DD/MM/YYYY HH24:MI:SS') AS DT_INI,
		TO_CHAR(p.DT_FIM, 'DD/MM/YYYY HH24:MI:SS') AS DT_FIM_F,
		p.DT_FIM,
		a.NM_ANIMAL
		FROM TB_ARKIVE_PRESCRICAO p
			JOIN TB_ARKIVE_CONSULTA co ON p.ID_CONSULTA = co.ID_CONSULTA
			JOIN TB_ARKIVE_ANIMAL a ON co.ID_ANIMAL  = a.ID_ANIMAL
		ORDER BY p.DT_INICIO;

    -- >> Variável %ROWTYPE para o cursor
    v_presc c_prescricoes%ROWTYPE;

BEGIN
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  CONSULTA 3.3: RELATÓRIO DE PRESCRIÇÕES POR VIA DE ADMINISTRAÇÃO');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(LPAD('ID', 4) || '  ' || RPAD('MEDICAMENTO', 20) || RPAD('ANIMAL', 9) || RPAD('DOSAGEM', 12) || RPAD('VIA', 14) || RPAD('INÍCIO', 12) || RPAD('FIM', 12) || RPAD('SITUAÇÃO', 18));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    OPEN c_prescricoes;
    LOOP
        FETCH c_prescricoes INTO v_presc;
        EXIT WHEN c_prescricoes%NOTFOUND;

        -- >> Tomada de decisão: descrição da via de administração
        CASE v_presc.TP_VIA
		WHEN 'ORAL' THEN v_via_desc := 'Oral';
		WHEN 'INJETAVEL' THEN v_via_desc := 'Injetável';
		WHEN 'TOPICO' THEN v_via_desc := 'Tópico';
		WHEN 'OCULAR' THEN v_via_desc := 'Ocular';
		WHEN 'OTOLOGICO' THEN v_via_desc := 'Otológico';
		WHEN 'OUTRO' THEN v_via_desc := 'Outro';
		ELSE v_via_desc := '[?] ' || v_presc.TP_VIA;
        END CASE;

        -- >> Tomada de decisão: situação (em andamento / concluído / contínuo)
        IF v_presc.DT_FIM IS NULL THEN
            v_situacao := 'Contínuo';
        ELSIF v_presc.DT_FIM >= SYSDATE THEN
            v_situacao := 'Em andamento';
        ELSE
            v_situacao := 'Concluído';
        END IF;

        DBMS_OUTPUT.PUT_LINE( LPAD(v_presc.ID_PRESCRICAO, 4) || '  ' || RPAD(SUBSTR(v_presc.NM_MEDICAMENTO,1,18), 20) || RPAD(v_presc.NM_ANIMAL, 9) || RPAD(v_presc.DS_DOSAGEM, 12) || RPAD(v_via_desc, 14) || RPAD(v_presc.DT_INI, 12) || RPAD(NVL(v_presc.DT_FIM_F, 'Indetermin.'),12) || RPAD(v_situacao, 18));
    END LOOP;
    CLOSE c_prescricoes;

    DBMS_OUTPUT.PUT_LINE(v_sep);
END;
/

-- ## 3.4 — RELATÓRIO DE ALERTAS POR STATUS E CANAL
-- 	   Lista todos os alertas, classifica por status/canal e exibe estatísticas
-- 	   de tempo de resposta quando o alerta foi lido.

DECLARE
    v_sep VARCHAR2(90) := RPAD('=', 90, '=');
    v_lin VARCHAR2(90) := RPAD('-', 90, '-');
    v_status_desc VARCHAR2(25);
    v_canal_desc VARCHAR2(20);
    v_tempo_resp VARCHAR2(20);
    v_total NUMBER := 0;
    v_lidos NUMBER := 0;
    v_ignorados NUMBER := 0;
    v_enviados NUMBER := 0;

    CURSOR c_alertas IS
        SELECT
        	al.ID_ALERTA,
        	al.TP_ALERTA,
        	al.ST_STATUS,
        	al.TP_CANAL,
        	TO_CHAR(al.DT_ENVIO,   'DD/MM/YYYY HH24:MI:SS HH24:MI') AS DT_ENV,
        	TO_CHAR(al.DT_LEITURA, 'DD/MM/YYYY HH24:MI:SS HH24:MI') AS DT_LEI,
        	al.DT_ENVIO,
        	al.DT_LEITURA,
        	a.NM_ANIMAL,
        	NVL(re.NM_RESPONSAVEL, '(clínica)') AS NM_DEST
        	FROM TB_ARKIVE_ALERTA al
        		JOIN TB_ARKIVE_ANIMAL a ON al.ID_ANIMAL = a.ID_ANIMAL
        		LEFT JOIN TB_ARKIVE_RESPONSAVEL re ON al.ID_RESPONSAVEL = re.ID_RESPONSAVEL
        	ORDER BY al.DT_ENVIO;

    -- >> Variável %ROWTYPE para o cursor
    v_alerta c_alertas%ROWTYPE;

BEGIN
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  CONSULTA 3.4: RELATÓRIO DE ALERTAS: STATUS, CANAL E TEMPO DE RESPOSTA');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(LPAD('ID', 4)        || '  ' || RPAD('ANIMAL',   9)  || RPAD('DESTINATÁRIO',22) || RPAD('TIPO',    12)  || RPAD('CANAL',   12)  || RPAD('STATUS',  20)  || RPAD('RESPOSTA', 18));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    OPEN c_alertas;
    LOOP
        FETCH c_alertas INTO v_alerta;
        EXIT WHEN c_alertas%NOTFOUND;

        v_total := v_total + 1;

        -- >> Tomada de decisão: descrição do status
        CASE v_alerta.ST_STATUS
		WHEN 'ENVIADO' THEN v_status_desc := 'Enviado — aguardando';
			v_enviados := v_enviados + 1;
		WHEN 'LIDO' THEN v_status_desc := 'Lido pelo destinatário';
			v_lidos := v_lidos + 1;
		WHEN 'IGNORADO' THEN v_status_desc := 'Ignorado';
			v_ignorados := v_ignorados + 1;
		ELSE v_status_desc := '[?] ' || v_alerta.ST_STATUS;
        END CASE;

        -- >> Tomada de decisão: canal
        CASE v_alerta.TP_CANAL
		WHEN 'APP' THEN v_canal_desc := 'App';
		WHEN 'WHATSAPP' THEN v_canal_desc := 'WhatsApp';
		WHEN 'EMAIL' THEN v_canal_desc := 'E-mail';
		ELSE v_canal_desc := v_alerta.TP_CANAL;
        END CASE;

        -- >> Tomada de decisão: tempo de resposta (em horas)
        IF v_alerta.DT_LEITURA IS NOT NULL THEN
            DECLARE
                v_horas NUMBER;
            BEGIN
                v_horas := ROUND((v_alerta.DT_LEITURA - v_alerta.DT_ENVIO) * 24, 1);
                v_tempo_resp := TO_CHAR(v_horas) || 'h';
            END;
        ELSIF v_alerta.ST_STATUS = 'ENVIADO' THEN
            v_tempo_resp := 'Pendente';
        ELSE
            v_tempo_resp := 'N/A';
        END IF;

        DBMS_OUTPUT.PUT_LINE(
LPAD(v_alerta.ID_ALERTA, 4) || '  ' || RPAD(v_alerta.NM_ANIMAL, 9) || RPAD(SUBSTR(v_alerta.NM_DEST, 1, 20), 22) || RPAD(v_alerta.TP_ALERTA, 12) || RPAD(v_canal_desc, 12) || RPAD(v_status_desc, 20) || RPAD(v_tempo_resp, 18));
    END LOOP;
    
    CLOSE c_alertas;

    -- >> Resumo de status
    DBMS_OUTPUT.PUT_LINE(v_lin);
    DBMS_OUTPUT.PUT_LINE('  RESUMO DOS ALERTAS');
    DBMS_OUTPUT.PUT_LINE(v_lin);
    DBMS_OUTPUT.PUT_LINE('  Total de alertas  : ' || v_total);
    DBMS_OUTPUT.PUT_LINE('  Lidos             : ' || v_lidos    || ' (' || ROUND(v_lidos * 100.0 / NULLIF(v_total, 0), 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('  Enviados (pend.)  : ' || v_enviados || ' (' || ROUND(v_enviados * 100.0 / NULLIF(v_total, 0), 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('  Ignorados         : ' || v_ignorados|| ' (' || ROUND(v_ignorados * 100.0 / NULLIF(v_total, 0), 1) || '%)');
    DBMS_OUTPUT.PUT_LINE(v_sep);
END;
/
/*
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================

FIM DO SCRIPT

  Total de blocos executados:
  ──────────────────────────────────────────────────────────────────────────────
   2 Blocos anônimos de exibição com JOINs     (Teste 1)
   1 Bloco com LAG / LEAD                      (Teste 2)
   4 Blocos com cursor explícito e decisão     (Teste 3)
*/
