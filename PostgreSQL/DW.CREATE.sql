create schema dw;
--shipping
drop table if exists dw.shipping_dim ;
CREATE TABLE dw.shipping_dim
(
 ship_id       serial NOT NULL,
 shipping_mode varchar(14) NOT NULL,
 CONSTRAINT PK_shipping_dim PRIMARY KEY ( ship_id )
);

truncate table dw.shipping_dim;

insert into dw.shipping_dim 
select 100+row_number() over(), ship_mode 
from (select distinct ship_mode from stg.orders ) a;

--customers

drop table if exists dw.customer_dim ;
CREATE TABLE dw.customer_dim
(
cust_id serial NOT NULL,
customer_id   varchar(8) NOT NULL, 
 customer_name varchar(22) NOT NULL,
 CONSTRAINT PK_customer_dim PRIMARY KEY ( cust_id )
);

truncate table dw.customer_dim;

insert into dw.customer_dim 
select 100+row_number() over(), customer_id, customer_name 
from (select distinct customer_id, customer_name from stg.orders ) a;

--geo
drop table if exists dw.geo_dim ;
CREATE TABLE dw.geo_dim
(
 geo_id      serial NOT NULL,
 country     varchar(13) NOT NULL,
 city        varchar(17) NOT NULL,
 state       varchar(20) NOT NULL,
 postal_code varchar(20) NOT NULL,
 CONSTRAINT PK_geo_dim PRIMARY KEY ( geo_id )
);


truncate table dw.geo_dim;

insert into dw.geo_dim 
select 100+row_number() over(), country, city, state, postal_code 
from (select distinct country, city, state, postal_code from stg.orders ) a;

select distinct country, city, state, postal_code from dw.geo_dim
where country is null or city is null or postal_code is null;

--products

drop table if exists dw.product_dim ;
CREATE TABLE dw.product_dim
(
 prod_id   serial NOT NULL,
 product_id   varchar(50) NOT NULL,  
 product_name varchar(127) NOT NULL,
 category     varchar(15) NOT NULL,
 sub_category varchar(11) NOT NULL,
 segment      varchar(11) NOT NULL,
 CONSTRAINT PK_product_dim PRIMARY KEY ( prod_id )
);

truncate table dw.product_dim ;

insert into dw.product_dim 
select 100+row_number() over () as prod_id 
,product_id, product_name, category, subcategory, segment 
from (select distinct product_id, product_name, category, subcategory, segment from stg.orders ) a;

--CALENDAR 

drop table if exists dw.calendar_dim ;
CREATE TABLE dw.calendar_dim
(
dateid serial  NOT NULL,
year        int NOT NULL,
quarter     int NOT NULL,
month       int NOT NULL,
week        int NOT NULL,
date        date NOT NULL,
week_day    varchar(20) NOT NULL,
leap  varchar(20) NOT NULL,
CONSTRAINT PK_calendar_dim PRIMARY KEY ( dateid )
);

truncate table dw.calendar_dim;

insert into dw.calendar_dim 
select 
to_char(date,'yyyymmdd')::int as date_id,  
       extract('year' from date)::int as year,
       extract('quarter' from date)::int as quarter,
       extract('month' from date)::int as month,
       extract('week' from date)::int as week,
       date::date,
       to_char(date, 'dy') as week_day,
       extract('day' from
               (date + interval '2 month - 1 day')
              ) = 29
       as leap
  from generate_series(date '2000-01-01',
                       date '2030-01-01',
                       interval '1 day')
       as t(date);

--sales_fact
drop table if exists dw.sales_fact ;
CREATE TABLE dw.sales_fact
(
 sales_id      serial NOT NULL,
 cust_id integer NOT NULL,
 order_date_id integer NOT NULL,
 ship_date_id integer NOT NULL,
 prod_id  integer NOT NULL,
 ship_id     integer NOT NULL,
 geo_id      integer NOT NULL,
 order_id    varchar(25) NOT NULL,
 sales       numeric(9,4) NOT NULL,
 profit      numeric(21,16) NOT NULL,
 quantity    int4 NOT NULL,
 discount    numeric(4,2) NOT NULL,
 CONSTRAINT PK_sales_fact PRIMARY KEY ( sales_id ));

ALTER TABLE dw.sales_fact ADD FOREIGN KEY (ship_id) REFERENCES dw.shipping_dim(ship_id);
ALTER TABLE dw.sales_fact ADD FOREIGN KEY (prod_id) REFERENCES dw.product_dim(prod_id);
ALTER TABLE dw.sales_fact ADD FOREIGN KEY (geo_id) REFERENCES dw.geo_dim(geo_id);
ALTER TABLE dw.sales_fact ADD FOREIGN KEY (cust_id) REFERENCES dw.customer_dim(cust_id);

insert into dw.sales_fact 
select
	 100+row_number() over() as sales_id
	 ,cust_id
	 ,to_char(order_date,'yyyymmdd')::int as  order_date_id
	 ,to_char(ship_date,'yyyymmdd')::int as  ship_date_id
	 ,p.prod_id
	 ,s.ship_id
	 ,geo_id
	 ,o.order_id
	 ,sales
	 ,profit
     ,quantity
	 ,discount
from stg.orders o 
inner join dw.shipping_dim s on o.ship_mode = s.shipping_mode
inner join dw.geo_dim g on o.postal_code = g.postal_code 
		and g.country=o.country and g.city = o.city and o.state = g.state
inner join dw.product_dim p on o.product_name = p.product_name 
		and o.segment=p.segment and o.subcategory=p.sub_category and o.category=p.category and o.product_id=p.product_id 
inner join dw.customer_dim cd on cd.customer_id=o.customer_id 
		and cd.customer_name=o.customer_name 











