CREATE VIEW dbo.FT_ORDEM_SERVICO AS 
select 

			Ordem_Servico = os.PK_ORD_SERV,
			Ano_Demanda = de.NR_ANO_DEMAND, 
			Numero_Demanda = de.NR_DEMAND,
			Assunto = CONCAT( 'Assunto Descaracterizado da OS ', CONVERT(VARCHAR , os.PK_ORD_SERV)) , ---- ISNULL(os.TX_ASSNTO,''),
			Sistema = ISNULL(oss.SG_SIST,''),
			Tipo = ISNULL(ost.DS_TP_DEMAND,''),
			Custo_Investimento = 
								CASE 
									WHEN DS_TP_DEMAND IN ('Manutenção Evolutiva',
														  'Desenvolvimento de Novo Sistema',
														  'Elaboração de Produto',
														  'Relatórios e Painéis')
									THEN 'INVESTIMENTO'
									WHEN DS_TP_DEMAND IN ('Manutenção Adaptativa',
														  'Manutenção Corretiva',
														  'Extração de Dados',
														  'Inclusão, Alteração ou Supressão de Dados',
														  'Serviço Técnico'
														  )
									THEN 'CUSTO'
									ELSE 'Não Informado'
								END,

			Id_Homologada = CASE 
							WHEN
								(	SELECT PK_TP_FASE_ORD_SERV FROM CVM_SCD.SCD.SCD_FASE_ORD_SERV WHERE PK_FASE_ORD_SERV = (
										SELECT MAX(PK_FASE_ORD_SERV) FROM CVM_SCD.SCD.SCD_FASE_ORD_SERV 
										WHERE PK_ORD_SERV = os.PK_ORD_SERV)
								) IN ( 5,6 )   -- 5 -- IMPLANTAÇÃO =-- 6 FINALIZADA 
								THEN 'SIM'  
								ELSE 'NÃO'

							END,
			Qtd_Pontos_funcao_Entregues = COALESCE(REPLACE(CONVERT(VARCHAR,ISNULL(os.VL_REAL,0)),'.',','),''),
			-- avaliacao
			Avaliacao_Resposta_4 = CASE WHEN  osav.r4 IS NOT NULL THEN osav.r4 ELSE 'Não houve avaliação'end,
			Avaliacao_Resposta_5 = CASE WHEN  osav.r5 IS NOT NULL THEN osav.r4 ELSE 'Não houve avaliação'end,
			Avaliacao_Resposta_6 = CASE WHEN  osav.r6 IS NOT NULL THEN osav.r4 ELSE 'Não houve avaliação'end,
			Avaliacao_Resposta_7 = CASE WHEN  osav.r7 IS NOT NULL THEN osav.r4 ELSE 'Não houve avaliação'end,
			-- dias uteis trabalhados por fase
			Duracao_Fase_Analise = CASE WHEN osdu.ana IS NULL THEN 0 ELSE osdu.ana END,
			Duracao_Fase_requisitos = CASE WHEN osdu.req IS NULL THEN 0 ELSE osdu.req END,
			Duracao_Fase_Projeto = CASE WHEN osdu.prj IS NULL THEN 0 ELSE osdu.prj END,
			Duracao_Fase_Construcao = CASE WHEN osdu.cod IS NULL THEN 0 ELSE osdu.cod END,
			Duracao_Fase_Testes = CASE WHEN osdu.tst IS NULL THEN 0 ELSE osdu.tst END,
			Duracao_Fase_Implantacao = CASE WHEN osdu.imp IS NULL THEN 0 ELSE osdu.imp  END,
			Duracao_Fase_Suspensa = CASE WHEN osdu.sus IS NULL THEN 0 ELSE osdu.sus END,
			Duracao_Total = CASE WHEN osdu.tra IS NULL THEN 0 ELSE osdu.tra END,
			Duracao_em_Espera = CASE WHEN osdu.esp IS NULL THEN 0 ELSE osdu.esp END,
			-- dias uteis trabalhados por grupo Fabrica , TI , Usuario
			Duracao_Fabrica = isnull(osdusf.fab,0) ,--Fabrica de Software
			Duracao_STI = isnull(osdusf.sti,0), -- STI
			Duracao_Usuario = isnull(osdusf.usr,0), --Usuario
			-- Analista Responsavel 
			FK_ANALISTA = da0.PK_SCD_USUAR, 
			-- Prestador Alocado 
			FK_PRESTADOR = pr.PK_PREST_SERV,
			-- Calendario Homologacao
			FK_CALENDARIO = calen.SK_Data,
			FK_DEMANDA = de.PK_DEMAND

from

			CVM_SCD.SCD.SCD_ORD_SERV os
			INNER JOIN CVM_SCD.SCD.SCD_DEMAND de
			on os.pk_demand = de.pk_demand 
			---OS tipo 
			left join CVM_SCD.SCD.SCD_TP_DEMAND ost 
			on os.PK_TP_DEMAND=ost.PK_TP_DEMAND
			-- analista responsavel 
			left join CVM_SCD.SCD.SCD_USUAR da0 on os.PK_ANALISTA_RESP=da0.PK_SCD_USUAR  
			left join CVM_SCD.CVM.USUARIO da on da0.PK_USUAR=da.PK_USUARIO 
			-- contrato e prestador alocado 
			left join CVM_SCD.SCD.SCD_CONTR co on os.PK_CONTR = co.PK_CONTR
			left join CVM_SCD.SCD.SCD_PREST_SERV pr on co.pk_prest_serv = pr.PK_PREST_SERV 
	--		left join CVM_SCD.SCD.SCD_ITEM_CONTR it on it.PK_ITEM_CONTR = os.PK_ITEM_CONTR
			-- sistema 
			left join CVM_SCD.SCD.SCD_SIST oss on os.PK_SIST=oss.PK_SIST
			-- OS data homologacao
			left join
				(
				select PK_ORD_SERV, max(DT_MUDAN_FASE) maxdt
				from CVM_SCD.SCD.SCD_FASE_ORD_SERV a
				where convert(date,DT_MUDAN_FASE)<=getdate() ---and pk_ord_serv = 789 
				AND a.PK_TP_FASE_ORD_SERV = 5 --- select * from cvm_scd.scd.scd_tp_fase_ord_serv
				group by PK_ORD_SERV
				) osdthom on osdthom.PK_ORD_SERV=os.PK_ORD_SERV
			left join CVM_SCD.dbo.SCD_Calendario calen
			on calen.data = CONVERT(DATE,osdthom.maxdt)
			-- OS avaliacao
			left join
				(
				select 
 
				PK_ORD_SERV = os, 
				case when [4] is not null then [4] else '' end R4,--respostas para a primeira pergunta
				case when [5] is not null then [5] else '' end R5,--respostas para a primeira pergunta
				case when [6] is not null then [6] else '' end R6,--respostas para a primeira pergunta
				case when [7] is not null then [7] else '' end R7,--respostas para a primeira pergunta
				case when [8] is not null then [8] else '' end SUGESTAO--respostas para a primeira pergunta

				from 

						(
						select
							q.FK_ORD_SERV os,
							p.FK_PERG p,
							replace(isnull(r.DS_RESP,p.DS_RESP),char(13)+char(10),' ') r
						from CVM_SCD.SCD.SCD_RESP_QUESTIONARIO q
						join CVM_SCD.SCD.SCD_RESP_QUESTOES p on p.FK_RESP_QUESTIONARIO=q.PK_RESP_QUESTIONARIO
						left join CVM_SCD.SCD.SCD_RESP_PERG r on r.PK_RESP_PERG=p.FK_RESP_PERG
						where
							p.FK_PERG in (4,5,6,7,8) and
							(r.DS_RESP is not null or p.DS_RESP is not null) 
						) a pivot (max(r) for p in ([4],[5],[6],[7],[8])) b
				  ) osav on osav.PK_ORD_SERV = os.PK_ORD_SERV
			-- OS duracao em cada fase
			left join
				(
				select 
						os,
						case when [9]<0 then 0 else isnull([9],0) end ana,--Análise
						case when [1]<0 then 0 else isnull([1],0) end req,--Requisitos
						case when [2]<0 then 0 else isnull([2],0) end prj,--Projeto
						case when [3]<0 then 0 else isnull([3],0) end cod,--Construção
						case when [4]<0 then 0 else isnull([4],0) end tst,--Testes
						case when [5]<0 then 0 else isnull([5],0) end imp,--Implantação
						case when [7]<0 then 0 else isnull([7],0) end sus,--Suspensa

						case when [9]<0 then 0 else isnull([9],0) end+
						case when [1]<0 then 0 else isnull([1],0) end+
						case when [2]<0 then 0 else isnull([2],0) end+
						case when [3]<0 then 0 else isnull([3],0) end+
						case when [4]<0 then 0 else isnull([4],0) end --+
					--	case when [5]<0 then 0 else isnull([5],0) end   -- retirei o tempo de implantacao devido as distorcoes pela nao finalização da OS
						tra,--dias uteis Trabalhados
						case when [7]<0 then 0 else isnull([7],0) end esp--dias uteis em Espera (OS Suspensa)
					from 
						(
						select
							a.os,
							a.tf,
							--dias corridos
							datediff(dd,a.dat,isnull(b.dat,getdate()))
							--menos sabados e domingos
							-datediff(wk,a.dat,isnull(b.dat,getdate()))*2-case when datepart(dw,a.dat)=1 or datepart(dw,isnull(b.dat,getdate()))=7 then 1 else 0 end
							--menos feriados nacionais
							-(select count(0) from CVM_SCD.dbo.INF_FERIAD where TP_NIVEL_FERIAD='NAC' and DT_REFER between a.dat and isnull(b.dat,getdate()) and datepart(dw,DT_REFER) between 2 and 6)
							--menos feriados no RJ
							-(select count(0) from CVM_SCD.dbo.INF_FERIAD_REGION where SG_UF='RJ' and DT_REFER between a.dat and isnull(b.dat,getdate()) and datepart(dw,DT_REFER) between 2 and 6) du
						from
							(
							select
								rank () over (order by a.PK_ORD_SERV,a.DT_MUDAN_FASE,a.PK_FASE_ORD_SERV) id,
								a.PK_ORD_SERV os,
								a.PK_TP_FASE_ORD_SERV tf,
								convert(date,DT_MUDAN_FASE) dat
							from CVM_SCD.SCD.SCD_FASE_ORD_SERV a
							inner join CVM_SCD.SCD.SCD_ORD_SERV b on b.PK_ORD_SERV=a.PK_ORD_SERV
							where convert(date,DT_MUDAN_FASE)<=getdate()           
							) a 
						left join
							(
							select
								rank () over (order by PK_ORD_SERV,DT_MUDAN_FASE,PK_FASE_ORD_SERV) id,
								PK_ORD_SERV os,
								PK_TP_FASE_ORD_SERV tf,
								convert(date,DT_MUDAN_FASE) dat
							from  CVM_SCD.SCD.SCD_FASE_ORD_SERV
							where convert(date,DT_MUDAN_FASE)<=getdate() 
							) b on b.os=a.os and b.id=a.id+1
						) a pivot (sum(du) for tf in ([9],[1],[2],[3],[4],[5],[7])) b
					) osdu on osdu.os=os.PK_ORD_SERV

			--OS dias uteis por subfase
			left join
				(
				select * from
					(
					select
						os,
						tp,
						case when du<0 then 0 else du end du
					from 
						(
						select
							a.os,
							a.tp,
							--dias corridos
							datediff(dd,a.dat,isnull(b.dat,getdate()))
							--menos sabados e domingos
							-datediff(wk,a.dat,isnull(b.dat,getdate()))*2-case when datepart(dw,a.dat)=1 or datepart(dw,isnull(b.dat,getdate()))=7 then 1 else 0 end
							--menos feriados nacionais
							-(select count(0) from CVM_SCD.dbo.INF_FERIAD where TP_NIVEL_FERIAD='NAC' and DT_REFER between a.dat and isnull(b.dat,getdate()) and datepart(dw,DT_REFER) between 2 and 6)
							--menos feriados no RJ
							-(select count(0) from CVM_SCD.dbo.INF_FERIAD_REGION where SG_UF='RJ' and DT_REFER between a.dat and isnull(b.dat,getdate()) and datepart(dw,DT_REFER) between 2 and 6) du
						from 
							(
							select
								rank () over (order by a.PK_ORD_SERV,a.DT_MUDAN_FASE,b.PK_FASE_ORD_SERV,b.DT_MUDAN_SUBFASE,b.PK_SUBFASE_ORD_SERV) id,
								a.PK_ORD_SERV os,
								isnull(convert(date,b.DT_MUDAN_SUBFASE),convert(date,a.DT_MUDAN_FASE)) dat,
								case
								when a.PK_TP_FASE_ORD_SERV in (6,7,8) then '' --fases descartadas: Finalizadas, Suspensas e Canceladas
								when c.PK_CONTR is null then 'usr'
								when c.PK_CONTR =30 then 'sti'
								else 'fab'

								end tp
							from  CVM_SCD.SCD.SCD_FASE_ORD_SERV a
							left join CVM_SCD.SCD.SCD_SUBFASE_ORD_SERV b on b.PK_FASE_ORD_SERV=a.PK_FASE_ORD_SERV
							left join CVM_SCD.SCD.SCD_CONTR_USUARIO c on c.PK_USUARIO=b.PK_USUARIO_RESP
							where isnull(convert(date,b.DT_MUDAN_SUBFASE),convert(date,a.DT_MUDAN_FASE))<=getdate()
							) a
						left join 
							(
							select
								rank () over (order by a.PK_ORD_SERV,a.DT_MUDAN_FASE,b.PK_FASE_ORD_SERV,b.DT_MUDAN_SUBFASE,b.PK_SUBFASE_ORD_SERV) id,
								a.PK_ORD_SERV os,
								isnull(convert(date,b.DT_MUDAN_SUBFASE),convert(date,a.DT_MUDAN_FASE)) dat
							from  CVM_SCD.SCD.SCD_FASE_ORD_SERV a
							left join CVM_SCD.SCD.SCD_SUBFASE_ORD_SERV b on b.PK_FASE_ORD_SERV=a.PK_FASE_ORD_SERV
							where isnull(convert(date,b.DT_MUDAN_SUBFASE),convert(date,a.DT_MUDAN_FASE))<=getdate()
							) b on b.os=a.os and b.id=a.id+1
						) a
					) b pivot (sum(du) for tp in ([fab],[sti],[usr])) z
				) osdusf on osdusf.os=os.PK_ORD_SERV
	











