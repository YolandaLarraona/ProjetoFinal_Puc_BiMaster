CREATE VIEW dbo.DIM_DEMANDA 
AS

SELECT

			NK_DEMANDA					=	de.PK_DEMAND,
			Ano_Demanda					=	de.NR_ANO_DEMAND, 
			Numero_Demanda				=	de.NR_DEMAND, 
			Descricao_Demanda			=	de.DS_DEMAND, 
			Componente_Organizacional	=	co.SG_INF_CO,
			Superintendencia			= 	CASE WHEN	CO.CD_TP_INF_CO_ATU >=4    
												 THEN  (SELECT SG_INF_CO FROM CVM_SCD.DBO.SRH_INF_CO WHERE NR_INF_CO = CVM_SCD.DBO.FN_INF_CO_SUP(CO.NR_INF_CO))       
												 ELSE  (SELECT SG_INF_CO FROM CVM_SCD.DBO.SRH_INF_CO WHERE NR_INF_CO = CO.NR_INF_CO)  
											END ,  

			Custo_Investimento			= 	CASE 
													WHEN tpde.DS_TP_DEMAND IN ( 'Manuten��o Evolutiva',
																				'Desenvolvimento de Novo Sistema',
																				'Elabora��o de Produto',
																				'Relat�rios e Pain�is'
																			  )
													THEN 'INVESTIMENTO'
													WHEN tpde.DS_TP_DEMAND IN ( 'Extra��o de Dados',
																				'Inclus�o, Altera��o ou Supress�o de Dados',    
																				'Manuten��o Corretiva' , 
																				'Manuten��o Adaptativa',
																				'Servi�o T�cnico'
																			  )
													THEN 'CUSTO'
													ELSE 'N�o Informado'
											END,

			Tipo			     		= ISNULL(tpde.ds_tp_demand,'N�o Informado') ,  
			Data_Abertura				= convert(date,fade_aberta.dt_mudan_fase),
			Id_Encerrada				= CASE WHEN dfd.DS_TP_FASE_DEMAND = 'Encerrada'
												THEN 'S'
												ELSE 'N'
										  END,
			Sistema						= ISNULL(ds.SG_SIST, 'N�o Informado')

from
			CVM_SCD.SCD.scd_demand de

			LEFT JOIN CVM_SCD.SCD.scd_tp_demand tpde
			on de.pk_tp_demand = tpde.pk_tp_demand

			left join CVM_SCD.dbo.SRH_INF_CO co 
			on de.PK_CO_INCL=co.NR_INF_CO
            
			-----fase aberta
			left join 
				( select  PK_DEMAND,DT_MUDAN_FASE = Min(DT_MUDAN_FASE) FROM CVM_SCD.SCD.SCD_FASE_DEMAND a  				 
				  GROUP BY a.PK_DEMAND
				) as fade_aberta 
				ON fade_aberta.PK_DEMAND = de.PK_DEMAND 

			--- ultima fase 
			LEFT join
				(
				select PK_DEMAND, max(PK_FASE_DEMAND) maxpk
				from CVM_SCD.SCD.SCD_FASE_DEMAND
				where convert(date,DT_MUDAN_FASE)<=convert(date,getdate())
				group by PK_DEMAND
				) dfx on dfx.PK_DEMAND=de.PK_DEMAND 

			LEFT join CVM_SCD.SCD.SCD_FASE_DEMAND df 
			on df.PK_FASE_DEMAND=dfx.maxpk 

			LEFT join CVM_SCD.SCD.SCD_TP_FASE_DEMAND dfd 
			on dfd.PK_TP_FASE_DEMAND=df.PK_TP_FASE_DEMAND 

			LEFT join CVM_SCD.SCD.SCD_SIST ds 
			on de.PK_SIST=ds.PK_SIST


