CREATE VIEW dbo.DIM_ANALISTA 
AS
SELECT 
				distinct 
				NK_ANALISTA = da0.PK_SCD_USUAR,
				Nome_Analista =
				CASE 
					WHEN da.DS_LOGIN IS NOT NULL	THEN	da.DS_LOGIN
					ELSE 'Analista Não Informado'
				END

from

				CVM_SCD.SCD.SCD_ORD_SERV os
				-- analista responsavel 
				left join CVM_SCD.SCD.SCD_USUAR da0 on os.PK_ANALISTA_RESP=da0.PK_SCD_USUAR  
				left join CVM_SCD.CVM.USUARIO da on da0.PK_USUAR=da.PK_USUARIO 


