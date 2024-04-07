CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;


--1. What is the total ammount spent by each customer spent on Zomato? --

select s.userid,  sum(p.price) total_amount from sales s inner join product p
on s.product_id = p.product_id
group by s.userid

--2. How many days did each customer visited Zomato? --

select userid, count(created_date) as distinct_days from sales
group by userid

--3. What was the first product each customer purchased? --

with data as 
(select RANK() over (partition by userid order by created_date) as RW,userid, product_id from sales)
select userid, product_id from data where RW = 1

--4. What is the most purchased item on the menu and how many times was it purchased by all the customers? -- 

select userid, count(product_id) as purchase_freq from sales where product_id = (
select top 1 product_id  from sales 
group by product_id
order by count(product_id) desc)
group by userid

--5. Which is the favourite product on zomato? --

select * from 
(select *, RANK() over (partition by userid order by CNT desc) as RW
from (select userid, product_id,count(product_id) as CNT from sales group by userid, product_id)B) C
where RW = 1

--6. Which item was first purchased by customer when they became member? --

with data as(
select RANK() over (partition by a.userid order by a.created_date) as RW, a.userid, a.product_id , a.created_date, b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid = b.userid where b.gold_signup_date < a.created_date)
select * from data where 
RW = 1

--7. Which item was purchased just before the customer became member? --

with data as(
select RANK() over (partition by a.userid order by a.created_date desc) as RW,a.userid, a.product_id , a.created_date, b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid = b.userid where b.gold_signup_date > a.created_date)
select * from data where 
RW =1

--8. What are the total orders and ammount spend on each customer before they become member? --

select a.userid, count(a.product_id) No_of_orders, sum(p.price) as Total_ammount
from sales a inner join goldusers_signup b
on a.userid = b.userid
inner join product p
on a.product_id = p.product_id
where a.created_date < b.gold_signup_date
group by a.userid

--9. If buying each product generates points for eg 5rs = 2 Zomato points and each product has different purchasing points.
-- For eg for P1 5rs = 1 Zomato point, for P2 10rs =  5 Zomato points, for P3 5rs = 1 Zomato point. Calculate Total points earned by each customer 
-- and for which product most points have been given till now. --

select userid, sum(POINTS)*2.5 Total_points from (
select a.userid, a.product_id, sum(price) as AMOUNT, 
(case 
             when a.product_id = 1 then sum(price)/5
			 when a.product_id = 2 then sum(price)/2
			 when a.product_id = 3 then sum(price)/5
end
) as POINTS
from sales a inner join product b
on a.product_id = b.product_id
group by a.userid, a.product_id) f
group by userid




select top 1 product_id, sum(POINTS) Total_points from (
select a.userid, a.product_id, sum(price) as AMOUNT, 
(case 
             when a.product_id = 1 then sum(price)/5
			 when a.product_id = 2 then sum(price)/2
			 when a.product_id = 3 then sum(price)/5
end
) as POINTS
from sales a inner join product b
on a.product_id = b.product_id
group by a.userid, a.product_id) f
group by product_id
order by Total_points desc 


--10. In the first one year after a customer joins the gold program (including their joining date) irrespective of what the customer has
-- purchased they earns 5 Zomato points for every 10Rs spent. Who earned more? 1 or 3 and what was their points earning in their first year?  

select a.userid, a.created_date, a.product_id, b.gold_signup_date, p.price, (p.price)/2 points  from sales a inner join goldusers_signup b
on a.userid = b.userid
inner join product p
on a.product_id = p.product_id
where created_date < dateadd(year,1,gold_signup_date) 
and  gold_signup_date <= created_date

--11. Rank all transactions of the customers -- 

select *, rank() over (partition by userid order by created_date) as RNK from sales


--12. Rank all the transactions for each member whenever they are Zomato Gold member. For every non Gold member transaction mark as NA.

select a.userid, a.created_date, a.product_id, b.gold_signup_date, (CASE
when gold_signup_date is null then 'na' 
else Convert(varchar(20),rank() over (partition by a.userid order by a.created_date desc)) END)
as RNK from sales a left join goldusers_signup b
on a.userid = b.userid 




