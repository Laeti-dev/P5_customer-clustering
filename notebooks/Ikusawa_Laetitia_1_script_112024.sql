/*
 En excluant les commandes annulées, quelles sont les commandes
récentes de moins de 3 mois que les clients ont reçues avec au moins 3
jours de retard ?
 */

WITH RecentOrders AS (
    SELECT o.order_id, o.order_purchase_timestamp, o.order_delivered_customer_date, o.order_estimated_delivery_date, o.order_status
    FROM orders o
    WHERE o.order_purchase_timestamp >= DATE(
        (SELECT MAX(o2.order_purchase_timestamp) FROM orders o2), 
        '-3 months'
    )
)
SELECT ro.order_id
FROM RecentOrders ro
WHERE ro.order_delivered_customer_date > DATE(ro.order_estimated_delivery_date, '+3 days')
AND ro.order_status != 'canceled';



/*
Qui sont les vendeurs ayant généré un chiffre d'affaires de plus de 100
000 Real sur des commandes livrées via Olist ?
*/

SELECT s.seller_id, SUM(op.payment_value) AS total_revenues
FROM sellers s
LEFT JOIN order_items oi ON s.seller_id = oi.seller_id
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_pymts op ON o.order_id = op.order_id
GROUP BY s.seller_id
HAVING total_revenues > 100000
ORDER BY total_revenues DESC
;


/*
Qui sont les nouveaux vendeurs (moins de 3 mois d'ancienneté) qui
sont déjà très engagés avec la plateforme (ayant déjà vendu plus de 30
produits) ?
*/

WITH MinOrderDate AS (
    SELECT MIN(o2.order_purchase_timestamp) AS min_date
    FROM orders o2
    WHERE o2.order_purchase_timestamp > DATE(
        (SELECT MAX(o3.order_purchase_timestamp) FROM orders o3), '-3 months'
    )
),
FilteredOrders AS (
    SELECT o.order_id
    FROM orders o
    WHERE o.order_purchase_timestamp > (SELECT min_date FROM MinOrderDate)
)
SELECT oi.product_id, COUNT(oi.product_id) AS sold_quantity
FROM order_items oi
JOIN FilteredOrders fo ON oi.order_id = fo.order_id
GROUP BY oi.product_id
ORDER BY sold_quantity DESC
;


/*Question : Quels sont les 5 codes postaux, enregistrant plus de 30
reviews, avec le pire review score moyen sur les 12 derniers mois ?
 */

WITH RecentOrders AS (
    SELECT o.customer_id, o.order_id
    FROM orders o
    WHERE o.order_delivered_customer_date > DATE(
        (SELECT MAX(o2.order_delivered_customer_date) FROM orders o2), '-12 months')
),
OrderReviews AS (
    SELECT orev.order_id, orev.review_score
    FROM order_reviews orev
)
SELECT c.customer_zip_code_prefix, AVG(orev.review_score) AS mean_review_score
FROM customers c
JOIN RecentOrders ro ON c.customer_id = ro.customer_id
JOIN OrderReviews orev ON ro.order_id = orev.order_id
GROUP BY c.customer_zip_code_prefix
HAVING COUNT(orev.review_score) > 30
ORDER BY mean_review_score ASC
LIMIT 5;

