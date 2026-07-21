select Churn, count(*), round(count(*) * 100.0/ (select count(*) from chrun_data_s2),2) as pct
from chrun_data_s2
group by churn;

with contract_churn as (
	select Contract, Churn, count(*) as customer_count
	from chrun_data_s2
	group by Contract, Churn
),
contract_totals as(
	select Contract, sum(customer_count) as total_customers
    from contract_churn
    group by Contract
)
select cc.Contract, cc.Churn, cc.customer_count, ct.total_customers,
round(cc.customer_count*100.0 / ct.total_customers,2) as pct_within_contract 
from contract_churn cc
join contract_totals ct 
	on cc.Contract = ct.Contract
order by cc.Contract, cc.Churn;

WITH tenure_buckets AS (
    SELECT Contract,Churn,
        CASE
            WHEN tenure <= 6 THEN '0-6 months'
            WHEN tenure <= 12 THEN '6-12 months'
            WHEN tenure <= 24 THEN '1-2 years'
            ELSE '2+ years'
        END AS tenure_range
    FROM chrun_data_s2
)
SELECT Contract, tenure_range, Churn,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY Contract, tenure_range), 2) AS pct_within_group
FROM tenure_buckets
GROUP BY Contract, tenure_range, Churn
ORDER BY 
    Contract,
    CASE tenure_range
        WHEN '0-6 months' THEN 1
        WHEN '6-12 months' THEN 2
        WHEN '1-2 years' THEN 3
        ELSE 4
    END,
    Churn;
    
    
    SELECT
    CASE 
        WHEN Contract = 'Month-to-month' AND tenure <= 6 THEN 'High Risk'
        WHEN Contract = 'Month-to-month' THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_segment,
    Churn,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY 
        CASE 
            WHEN Contract = 'Month-to-month' AND tenure <= 6 THEN 'High Risk'
            WHEN Contract = 'Month-to-month' THEN 'Medium Risk'
            ELSE 'Low Risk'
        END), 2) AS pct_within_segment
FROM chrun_data_s2
GROUP BY risk_segment, Churn
ORDER BY risk_segment, Churn;



WITH risk_segment AS (
    SELECT *,
        CASE 
            WHEN Contract = 'Month-to-month' AND tenure <= 6 THEN 'High Risk'
            WHEN Contract = 'Month-to-month' THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS risk_tier
    FROM chrun_data_s2
)
SELECT
    PaymentMethod,
    COUNT(*) AS customer_count,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges,
    ROUND(SUM(CASE WHEN OnlineSecurity = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_with_online_security,
    ROUND(SUM(CASE WHEN TechSupport = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_with_tech_support,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM risk_segment
WHERE risk_tier = 'High Risk'
GROUP BY PaymentMethod
ORDER BY churn_rate_pct DESC;


WITH scored AS (
    SELECT
        customerID,
        Churn,
        (CASE Contract WHEN 'Month-to-month' THEN 3 WHEN 'One year' THEN 1 ELSE 0 END) +
        (CASE 
            WHEN tenure <= 6 THEN 3
            WHEN tenure <= 12 THEN 2
            WHEN tenure <= 24 THEN 1
            ELSE 0
        END) +
        (CASE WHEN PaymentMethod = 'Electronic check' THEN 3 ELSE 0 END) AS risk_score
    FROM chrun_data_s2
)
SELECT
    CASE 
        WHEN risk_score >= 6 THEN 'High Risk'
        WHEN risk_score >= 3 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_tier,
    COUNT(*) AS customer_count,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM scored
GROUP BY risk_tier
ORDER BY churn_rate_pct DESC;