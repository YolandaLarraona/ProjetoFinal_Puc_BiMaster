CREATE VIEW dbo.DIM_PRESTADOR
as

SELECT  
				distinct
				NK_PRESTADOR = pr.PK_PREST_SERV,
				Nome_Prestador_Servico = 
				case when pr.NM_PREST_SERV is null 
						then '' 
					 when pr.NM_PREST_SERV like '%CVM%'
						then 'STI'
						else rtrim(left(pr.NM_PREST_SERV,
										case when charindex(' ',pr.NM_PREST_SERV)=0 
												then len(pr.NM_PREST_SERV) 
												else charindex(' ',pr.NM_PREST_SERV) 
										end))  
						end 

from

				CVM_SCD.SCD.SCD_ORD_SERV os
				left join CVM_SCD.SCD.SCD_CONTR co on os.PK_CONTR = co.PK_CONTR
				left join CVM_SCD.SCD.SCD_PREST_SERV pr on co.pk_prest_serv = pr.PK_PREST_SERV 
				left join CVM_SCD.SCD.SCD_ITEM_CONTR it on it.PK_ITEM_CONTR = os.PK_ITEM_CONTR

where it.DS_ITEM IS NOT NULL