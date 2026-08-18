-- ============================================================
-- Consumer Credit Risk Scorecard
-- Weighted score = loan grade + home ownership + loan intent
--                  + prior default on file (0-25 pts each, 100 max)
-- Point values were derived empirically in Excel: each category
-- is ranked by its own observed default rate in the raw data,
-- not assigned arbitrarily. See scorecard_points table / the
-- Excel staging workbook for how each value was derived.
-- ============================================================

CREATE VIEW v_applicant_scores AS
WITH factor_points AS (
    SELECT
        a.applicant_id,
        (SELECT points FROM scorecard_points WHERE Factor = 'Loan_grade' AND Category = a.loan_grade) AS grade_points,
        (SELECT points FROM scorecard_points WHERE Factor = 'person_home_ownership' AND Category = a.person_home_ownership) AS home_points,
        (SELECT points FROM scorecard_points WHERE Factor = 'loan_intent' AND Category = a.loan_intent) AS intent_points,
        (SELECT points FROM scorecard_points WHERE Factor = 'cb_person_default_on_file' AND Category = a.cb_person_default_on_file) AS default_points,
        a.loan_status,
        a.loan_amnt
    FROM applicants a
),
scored AS (
    SELECT
        applicant_id,
        (grade_points + home_points + intent_points + default_points) AS total_score,
        loan_status,
        loan_amnt
    FROM factor_points
)
SELECT
    applicant_id,
    total_score,
    CASE
        WHEN total_score >= 75 THEN 'Low Risk'
        WHEN total_score >= 50 THEN 'Medium Risk'
        ELSE 'High Risk'
    END AS risk_tier,
    PERCENT_RANK() OVER (ORDER BY total_score) AS score_percentile,
    NTILE(10) OVER (ORDER BY total_score) AS score_decile,
    loan_status,
    loan_amnt
FROM scored;

-- ============================================================
-- Validation: tier-level default rate should climb steadily as
-- avg_score drops -- this is the check that confirms the model
-- actually separates good and bad loans.
-- ============================================================

SELECT
    risk_tier,
    COUNT(*) AS applicants,
    ROUND(AVG(total_score), 1) AS avg_score,
    ROUND(AVG(loan_status) * 100, 1) AS default_rate_pct
FROM v_applicant_scores
GROUP BY risk_tier
ORDER BY avg_score DESC;
