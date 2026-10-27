CREATE TABLE book_data(
Book_ID SERIAL PRIMARY KEY,
Title VARCHAR(200),
Author VARCHAR(200),
Genre VARCHAR(200),
Published_Year INT,
Price NUMERIC(10,2),
Stock INT
);

CREATE TABLE customer_data(
Customer_ID SERIAL PRIMARY KEY,
Name VARCHAR(200),
Email VARCHAR(200),
Phone INT,
City VARCHAR(200),
Country VARCHAR(200)
);

CREATE TABLE orders_data(
Order_ID SERIAL PRIMARY KEY,
Customer_ID INT REFERENCES customer_data(Customer_ID),
Book_ID INT REFERENCES book_data(Book_ID),
Order_Date DATE,
Quantity INT,
Total_Amount NUMERIC(10,2)
);

--INSERT BOOK DATA
COPY book_data(Book_ID,Title,Author,Genre,Published_Year,Price,Stock)
FROM 'C:\Users\User\Downloads\SQL-13.9\Book Sales Analysis\Books.csv'
CSV HEADER;

SELECT * FROM book_data;

--INSERT CUSTMER DATA
COPY customer_data(Customer_ID,Name,Email,Phone,City,Country)
FROM 'C:\Users\User\Downloads\SQL-13.9\Book Sales Analysis\Customers.csv'
CSV HEADER;

SELECT * FROM customer_data;

--INSERT ORDER DATA
COPY orders_data(Order_ID,Customer_ID,Book_ID,Order_Date,Quantity,Total_Amount)
FROM 'C:\Users\User\Downloads\SQL-13.9\Book Sales Analysis\Orders.csv'
CSV HEADER;

SELECT * FROM orders_data;

--Q1. Retrive all books in the 'Fiction' Genre:
SELECT * FROM book_data
WHERE Genre='Fiction';

--Q2. Find books published after the year 1950:
SELECT * FROM book_data
WHERE Published_Year > 1950 ORDER BY Published_Year ASC;

--Q3. List of all customer country 'CANADA':
SELECT * FROM customer_data
WHERE Country='Canada';

--Q4. Show orders placed in November 2023:
SELECT * FROM orders_data
WHERE 
Order_Date BETWEEN '2023-11-01' AND '2023-11-30'
ORDER BY Order_Date ASC;

--Q5. Retrive total 'Stock' of book available:
SELECT SUM(stock) AS Total_Stock
FROM book_data;

--Q6. Find the details of the most expensive book:
SELECT * FROM book_data
ORDER BY Price DESC LIMIT 1;

--Q7. Show all customers details who order more than 1 qunatiry of a book:
SELECT
	c.Customer_ID,c.Name, c.Email, c.Phone, c.Country,
	o.Book_ID,o.Order_Date,o.Quantity
FROM customer_data c
LEFT JOIN orders_data o
	ON c.Customer_ID=o.Customer_ID
	WHERE Quantity>1
ORDER BY Quantity DESC;

--Q8.Retrive all orders where the total amount exceeds $20;
SELECT * FROM orders_data
WHERE total_amount>20
ORDER BY total_amount ASC;

--Q9. List all genres available in the Books Table:
SELECT Genre AS ListOf_Genre
FROM book_data
GROUP BY Genre ORDER BY Genre ASC;
--OR 
SELECT DISTINCT(Genre) AS ListOf_Genre
FROM book_data ORDER BY Genre ASC;

--Q10. Find the book with the lowest stock:
SELECT * FROM book_data 
ORDER BY stock ASC LIMIT 1;

--Q11. Calculate the total revenue generated from all orders:
SELECT 
SUM(total_amount) AS Total_Revenue
FROM orders_data;

--ADVANCE SECTION--

--Q1. Retrive the total number of books sold for each genre:
SELECT 
	b.Genre, SUM(o.Quantity) AS TotalQty_Sold
FROM book_data b 
INNER JOIN orders_data o
 ON b.Book_ID=o.Book_ID 
GROUP BY Genre ORDER BY SUM(o.Quantity) DESC;

--Q2. Find the Average price of books in the 'Fantasy' Genre:
SELECT Title, Genre, price,
  ROUND(AVG(Price) OVER(PARTITION BY Genre),2) AS Avg_Price
FROM book_data WHERE Genre='Fantasy';

--Another Way
SELECT ROUND(AVG(Price),2) AS Avg_Price
FROM book_data WHERE Genre='Fantasy';

--Q3. List of customers who have placed at least 2 orders:
SELECT c.Customer_id, c.Name,
  COUNT(o.Order_ID) AS NumberOf_Orders
  FROM customer_data c
INNER JOIN orders_data o
  ON c.Customer_id=o.Customer_id
  GROUP BY c.Customer_id
HAVING COUNT(o.Order_ID)>=2
ORDER BY COUNT(o.Customer_id) DESC;
  
--Another way  BY Window Function
SELECT Customer_id, Name, NumberOf_Orders FROM(
SELECT c.Customer_id, c.Name,
  COUNT(o.Order_ID)
  OVER(PARTITION BY o.customer_id) AS NumberOf_Orders,
  ROW_NUMBER()
  OVER(PARTITION BY o.customer_id ORDER BY o.customer_id ASC) AS EachCustomer_Row
  FROM customer_data c
INNER JOIN orders_data o
  ON c.Customer_id=o.Customer_id
) AS RPT_ANALYSIS
WHERE NumberOf_Orders>=2 AND EachCustomer_Row=1 ORDER BY NumberOf_Orders DESC;

--Q4. Find the most frequently orderd book:
SELECT b.Book_ID, b.Title,
	COUNT(o.Order_ID) AS Order_Count
		FROM book_data b
		INNER JOIN orders_data o
		ON b.Book_ID=o.Book_ID
	GROUP BY b.Book_ID
ORDER BY COUNT(o.Order_ID) DESC LIMIT 1;

--Q5. Show the top 3 most expensive books of 'Fantasy' Genre:
SELECT 
 Book_ID, Title, Genre, Price
 FROM book_data
 WHERE Genre='Fantasy' 
ORDER BY Price DESC LIMIT 3;

--Q6. Retrive the total quantity of books sold by each author:
SELECT  b.Author, SUM(o.Quantity) AS Total_Books_Sold
 FROM book_data b
 	INNER JOIN orders_data o
 ON b.Book_ID=o.Book_ID
GROUP BY b.Author ORDER BY b.Author ASC;

--Q7. List the cities where customers who spent over $30 are located:
SELECT c.Customer_ID, c.City, 
	SUM(o.Total_Amount) AS Total_Spend
		FROM customer_data c
		INNER JOIN orders_data o
		ON c.Customer_id=o.Customer_id
	GROUP BY c.Customer_ID, c.City
HAVING SUM(o.Total_Amount) >30 ORDER BY Customer_ID ASC;

--Q8. Find the customer who spent the most on orders:
SELECT c.Customer_ID, c.Name,
	SUM(o.Total_Amount) AS Total_Spent
	FROM customer_data c
	INNER JOIN orders_data o
	ON c.Customer_id=o.Customer_id
	GROUP BY c.Customer_ID
ORDER BY SUM(o.Total_Amount) DESC LIMIT 1;

--Q9.Calculate the stock remaining after fulfilling all order:
SELECT  b.Book_ID, SUM(b.stock) AS Total_Stock,
		SUM(o.Quantity) AS Sales_Qty,
		SUM(b.stock)-COALESCE(SUM(o.Quantity),0) AS Remaining_Stock
		FROM book_data b
		LEFT JOIN orders_data o
		ON b.Book_ID=o.Book_ID
GROUP BY b.Book_ID ORDER BY b.Book_ID ASC;

--Q10. Analyze monthly sales revenue and the total number of books sold for each month.
SELECT
	EXTRACT(YEAR FROM order_date) AS Sales_Year,
	EXTRACT(MONTH FROM order_date)  AS Sales_Month,
	SUM(quantity) AS Sales_Qty,
	SUM(total_amount) AS Total_Revenue
FROM orders_data
GROUP BY
	EXTRACT(YEAR FROM order_date),
	EXTRACT(MONTH FROM order_date) 
ORDER BY 
	EXTRACT(YEAR FROM order_date),
	EXTRACT(MONTH FROM order_date) ASC;

--Q11. Rank customers based on their total spending on orders.
SELECT 
	Customer_ID, Name, Total_Spend,
	DENSE_RANK() OVER(ORDER BY Total_Spend DESC) AS Customer_Rank
FROM(
	SELECT 
		c.customer_id, c.name,
	  	SUM(o.total_amount) AS Total_Spend
	  
	FROM customer_data c
		INNER JOIN orders_data o
		ON c.customer_id=o.customer_id
	GROUP BY c.customer_id
	) AS Summary
ORDER BY Customer_Rank ASC;


---END---