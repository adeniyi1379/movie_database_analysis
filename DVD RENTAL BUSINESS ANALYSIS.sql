-- DVD RENTAL BUSINESS ANALYSIS - 10 KEY STAKEHOLDER QUESTIONS
-- These queries provide insights into revenue, customer behavior, and operational efficiency

-- =================================================================
-- QUESTION 1: What is our monthly revenue trend and growth rate?
-- =================================================================
-- Critical for understanding business performance and seasonal patterns

SELECT 
    DATE_TRUNC('month', payment_date) as month,
    COUNT(*) as total_transactions,
    SUM(amount) as monthly_revenue,
    ROUND(AVG(amount), 2) as avg_transaction_value,
    LAG(SUM(amount)) OVER (ORDER BY DATE_TRUNC('month', payment_date)) as prev_month_revenue,
    ROUND(
        ((SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY DATE_TRUNC('month', payment_date))) 
         / LAG(SUM(amount)) OVER (ORDER BY DATE_TRUNC('month', payment_date)) * 100), 2
    ) as month_over_month_growth_pct
FROM payment 
GROUP BY DATE_TRUNC('month', payment_date)
ORDER BY month;

-- =================================================================
-- QUESTION 2: Which films generate the most revenue and should we stock more?
-- =================================================================
-- Helps optimize inventory investment and purchasing decisions

SELECT 
    f.title,
    f.rating,
    c.name as category,
    COUNT(r.rental_id) as total_rentals,
    SUM(p.amount) as total_revenue,
    ROUND(AVG(p.amount), 2) as avg_rental_price,
    COUNT(DISTINCT i.inventory_id) as copies_in_stock,
    ROUND(SUM(p.amount) / COUNT(DISTINCT i.inventory_id), 2) as revenue_per_copy,
    ROUND(COUNT(r.rental_id)::DECIMAL / COUNT(DISTINCT i.inventory_id), 2) as rentals_per_copy
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY f.film_id, f.title, f.rating, c.name
ORDER BY total_revenue DESC
LIMIT 20;

-- =================================================================
-- QUESTION 3: What is our customer lifetime value and retention rate?
-- =================================================================
-- Essential for understanding customer profitability and marketing ROI

WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name as customer_name,
        COUNT(r.rental_id) as total_rentals,
        SUM(p.amount) as lifetime_value,
        MIN(r.rental_date) as first_rental_date,
        MAX(r.rental_date) as last_rental_date,
        EXTRACT(DAYS FROM (MAX(r.rental_date) - MIN(r.rental_date))) as customer_lifespan_days
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT 
    ROUND(AVG(lifetime_value), 2) as avg_customer_lifetime_value,
    ROUND(AVG(total_rentals), 2) as avg_rentals_per_customer,
    ROUND(AVG(customer_lifespan_days), 0) as avg_customer_lifespan_days,
    COUNT(CASE WHEN last_rental_date >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as active_customers_last_30_days,
    COUNT(*) as total_customers,
    ROUND(
        COUNT(CASE WHEN last_rental_date >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END)::DECIMAL 
        / COUNT(*) * 100, 2
    ) as customer_retention_rate_pct
FROM customer_metrics;

-- =================================================================
-- QUESTION 4: Which store locations are most profitable?
-- =================================================================
-- Critical for expansion decisions and resource allocation

SELECT 
    s.store_id,
    CONCAT(a.address, ', ', c.city, ', ', co.country) as store_location,
    COUNT(DISTINCT cust.customer_id) as total_customers,
    COUNT(r.rental_id) as total_rentals,
    SUM(p.amount) as total_revenue,
    ROUND(AVG(p.amount), 2) as avg_transaction_value,
    ROUND(SUM(p.amount) / COUNT(DISTINCT cust.customer_id), 2) as revenue_per_customer,
    COUNT(DISTINCT staff.staff_id) as staff_count,
    ROUND(SUM(p.amount) / COUNT(DISTINCT staff.staff_id), 2) as revenue_per_staff_member
FROM store s
JOIN address a ON s.address_id = a.address_id
JOIN city c ON a.city_id = c.city_id
JOIN country co ON c.country_id = co.country_id
JOIN customer cust ON s.store_id = cust.store_id
JOIN rental r ON cust.customer_id = r.customer_id
JOIN payment p ON r.rental_id = p.rental_id
JOIN staff ON s.store_id = staff.store_id
GROUP BY s.store_id, a.address, c.city, co.country
ORDER BY total_revenue DESC;

-- =================================================================
-- QUESTION 5: What are our peak business hours and days?
-- =================================================================
-- Important for staffing optimization and operational planning

SELECT 
    EXTRACT(DOW FROM r.rental_date) as day_of_week,
    CASE EXTRACT(DOW FROM r.rental_date)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END as day_name,
    EXTRACT(HOUR FROM r.rental_date) as hour_of_day,
    COUNT(*) as rental_count,
    SUM(p.amount) as hourly_revenue,
    ROUND(AVG(p.amount), 2) as avg_transaction_value
FROM rental r
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY EXTRACT(DOW FROM r.rental_date), EXTRACT(HOUR FROM r.rental_date)
ORDER BY rental_count DESC
LIMIT 20;

-- =================================================================
-- QUESTION 6: How effective is our inventory turnover?
-- =================================================================
-- Helps identify slow-moving inventory and optimize stock levels

SELECT 
    f.title,
    c.name as category,
    COUNT(DISTINCT i.inventory_id) as total_copies,
    COUNT(r.rental_id) as total_rentals,
    ROUND(COUNT(r.rental_id)::DECIMAL / COUNT(DISTINCT i.inventory_id), 2) as turnover_ratio,
    CASE 
        WHEN COUNT(r.rental_id)::DECIMAL / COUNT(DISTINCT i.inventory_id) >= 10 THEN 'High Turnover'
        WHEN COUNT(r.rental_id)::DECIMAL / COUNT(DISTINCT i.inventory_id) >= 5 THEN 'Medium Turnover'
        ELSE 'Low Turnover'
    END as turnover_category,
    MAX(r.rental_date) as last_rental_date,
    EXTRACT(DAYS FROM (CURRENT_DATE - MAX(r.rental_date))) as days_since_last_rental
FROM film f
JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY f.film_id, f.title, c.name
HAVING COUNT(DISTINCT i.inventory_id) > 0
ORDER BY turnover_ratio DESC;

-- =================================================================
-- QUESTION 7: What is our late return rate and lost revenue from overdue fees?
-- =================================================================
-- Important for understanding collection efficiency and policy effectiveness

WITH rental_analysis AS (
    SELECT 
        r.rental_id,
        r.rental_date,
        r.return_date,
        f.rental_duration,
        CASE 
            WHEN r.return_date IS NULL THEN 'Never Returned'
            WHEN r.return_date > (r.rental_date + INTERVAL '1 day' * f.rental_duration) THEN 'Late Return'
            ELSE 'On Time'
        END as return_status,
        CASE 
            WHEN r.return_date IS NOT NULL AND r.return_date > (r.rental_date + INTERVAL '1 day' * f.rental_duration) 
            THEN EXTRACT(DAYS FROM (r.return_date - (r.rental_date + INTERVAL '1 day' * f.rental_duration)))
            WHEN r.return_date IS NULL 
            THEN EXTRACT(DAYS FROM (CURRENT_DATE - (r.rental_date + INTERVAL '1 day' * f.rental_duration)))
            ELSE 0
        END as days_overdue,
        f.rental_rate
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
)
SELECT 
    COUNT(*) as total_rentals,
    COUNT(CASE WHEN return_status = 'On Time' THEN 1 END) as on_time_returns,
    COUNT(CASE WHEN return_status = 'Late Return' THEN 1 END) as late_returns,
    COUNT(CASE WHEN return_status = 'Never Returned' THEN 1 END) as never_returned,
    ROUND(COUNT(CASE WHEN return_status = 'Late Return' THEN 1 END)::DECIMAL / COUNT(*) * 100, 2) as late_return_rate_pct,
    ROUND(AVG(CASE WHEN return_status != 'On Time' THEN days_overdue END), 2) as avg_days_overdue,
    ROUND(SUM(CASE WHEN return_status != 'On Time' THEN days_overdue * rental_rate * 0.5 END), 2) as potential_late_fee_revenue
FROM rental_analysis;

-- =================================================================
-- QUESTION 8: Which movie categories are most popular and profitable?
-- =================================================================
-- Guides content acquisition strategy and marketing focus

SELECT 
    c.name as category,
    COUNT(r.rental_id) as total_rentals,
    COUNT(DISTINCT f.film_id) as unique_films,
    SUM(p.amount) as total_revenue,
    ROUND(AVG(p.amount), 2) as avg_rental_price,
    ROUND(SUM(p.amount) / COUNT(r.rental_id), 2) as revenue_per_rental,
    ROUND(COUNT(r.rental_id)::DECIMAL / COUNT(DISTINCT f.film_id), 2) as avg_rentals_per_film,
    RANK() OVER (ORDER BY SUM(p.amount) DESC) as revenue_rank,
    RANK() OVER (ORDER BY COUNT(r.rental_id) DESC) as popularity_rank
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY c.category_id, c.name
ORDER BY total_revenue DESC;

-- =================================================================
-- QUESTION 9: What is our customer acquisition cost vs. customer value?
-- =================================================================
-- Essential for marketing budget allocation and ROI analysis

WITH monthly_customer_acquisition AS (
    SELECT 
        DATE_TRUNC('month', create_date) as acquisition_month,
        COUNT(*) as new_customers_acquired
    FROM customer 
    GROUP BY DATE_TRUNC('month', create_date)
),
monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', payment_date) as revenue_month,
        SUM(amount) as monthly_revenue
    FROM payment 
    GROUP BY DATE_TRUNC('month', payment_date)
)
SELECT 
    mca.acquisition_month,
    mca.new_customers_acquired,
    COALESCE(mr.monthly_revenue, 0) as monthly_revenue,
    ROUND(COALESCE(mr.monthly_revenue, 0) / NULLIF(mca.new_customers_acquired, 0), 2) as revenue_per_new_customer,
    -- Assuming 10% of monthly r