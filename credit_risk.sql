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
)
SELECT * FROM factor_points LIMIT 20;

SELECT DISTINCT person_home_ownership
FROM applicants a
WHERE (SELECT points FROM scorecard_points WHERE Factor = 'person_home_ownership' AND Category = a.person_home_ownership) IS NULL;

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
    loan_status
FROM scored
LIMIT 20;

SELECT DISTINCT loan_grade
FROM applicants a
WHERE (SELECT points FROM scorecard_points WHERE Factor = 'Loan_grade' AND Category = a.loan_grade) IS NULL;

SELECT DISTINCT loan_intent
FROM applicants a
WHERE (SELECT points FROM scorecard_points WHERE Factor = 'loan_intent' AND Category = a.loan_intent) IS NULL;

SELECT DISTINCT cb_person_default_on_file
FROM applicants a
WHERE (SELECT points FROM scorecard_points WHERE Factor = 'cb_person_default_on_file' AND Category = a.cb_person_default_on_file) IS NULL;

WITH factor_points AS (
    SELECT
        a.applicant_id,
        (SELECT points FROM scorecard_points WHERE Factor = 'Loan_grade' AND Category = a.loan_grade) AS grade_points,
        (SELECT points FROM scorecard_points WHERE Factor = 'person_home_ownership' AND Category = a.person_home_ownership) AS home_points,
        (SELECT points FROM scorecard_points WHERE Factor = 'loan_intent' AND Category = a.loan_intent) AS intent_points,
        (SELECT points FROM scorecard_points WHERE Factor = 'cb_person_default_on_file' AND Category = a.cb_person_default_on_file) AS default_points
    FROM applicants a
)
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN grade_points + home_points + intent_points + default_points IS NULL THEN 1 ELSE 0 END) AS null_scores
FROM factor_points;

SELECT COUNT(*) AS bad_rows
FROM applicants
WHERE loan_grade IS NULL OR loan_grade = ''
   OR person_home_ownership IS NULL OR person_home_ownership = ''
   OR loan_intent IS NULL OR loan_intent = ''
   OR cb_person_default_on_file IS NULL OR cb_person_default_on_file = '';
   
   SELECT
  SUM(CASE WHEN (SELECT points FROM scorecard_points WHERE Factor='Loan_grade' AND Category=a.loan_grade) IS NULL THEN 1 ELSE 0 END) AS grade_nulls,
  SUM(CASE WHEN (SELECT points FROM scorecard_points WHERE Factor='person_home_ownership' AND Category=a.person_home_ownership) IS NULL THEN 1 ELSE 0 END) AS home_nulls,
  SUM(CASE WHEN (SELECT points FROM scorecard_points WHERE Factor='loan_intent' AND Category=a.loan_intent) IS NULL THEN 1 ELSE 0 END) AS intent_nulls,
  SUM(CASE WHEN (SELECT points FROM scorecard_points WHERE Factor='cb_person_default_on_file' AND Category=a.cb_person_default_on_file) IS NULL THEN 1 ELSE 0 END) AS default_nulls
FROM applicants a;

SELECT DISTINCT person_home_ownership
FROM applicants a
WHERE (SELECT points FROM scorecard_points WHERE Factor='person_home_ownership' AND Category=a.person_home_ownership) IS NULL;

SELECT Category, LENGTH(Category) AS char_length, Points
FROM scorecard_points
WHERE Factor = 'person_home_ownership';

SELECT COUNT(*) FROM scorecard_points WHERE Factor = 'person_home_ownership';

SELECT Category, LENGTH(Category) AS char_length, Points
FROM scorecard_points
WHERE Factor = 'person_home_ownership'
ORDER BY Category;

UPDATE scorecard_points
SET Factor = TRIM(Factor);

SELECT COUNT(*) FROM scorecard_points WHERE Factor = 'person_home_ownership';

WITH factor_points AS (
    SELECT
        a.applicant_id,
        (SELECT points FROM scorecard_points WHERE Factor = 'Loan_grade' AND Category = a.loan_grade) AS grade_points,
        (SELECT points FROM scorecard_points WHERE Factor = 'person_home_ownership' AND Category = a.person_home_ownership) AS home_points,
        (SELECT points FROM scorecard_points WHERE Factor = 'loan_intent' AND Category = a.loan_intent) AS intent_points,
        (SELECT points FROM scorecard_points WHERE Factor = 'cb_person_default_on_file' AND Category = a.cb_person_default_on_file) AS default_points
    FROM applicants a
)
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN grade_points + home_points + intent_points + default_points IS NULL THEN 1 ELSE 0 END) AS null_scores
FROM factor_points;

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

SELECT
    risk_tier,
    COUNT(*) AS applicants,
    ROUND(AVG(total_score), 1) AS avg_score,
    ROUND(AVG(loan_status) * 100, 1) AS default_rate_pct
FROM v_applicant_scores
GROUP BY risk_tier
ORDER BY avg_score DESC;