drop table Products cascade constraints; /* Dimension Table*/
drop table Channels cascade constraints;  /* Dimension Table*/
drop table Suppliers cascade constraints; /* Dimension Table*/
drop table Clients cascade constraints; /* Dimension Table*/
drop table Transactions cascade constraints; /* Dimension Table*/
drop table Sales cascade constraints; /* Fact Table*/

/*Create dimension tables*/
/*Products table*/
create table Products
(product_id varchar2(6) primary key,
product_name varchar2(30) Not NULL,
product_price number(5,2) default 0.00 Not null,
product_category varchar2(30) not null,
product_description varchar2(250));

/*Channels table*/
create table Channels
(channel_id varchar2(3) primary key,
channel_desc varchar2(20) Not null,
city varchar2(10),
suburb varchar2(10),
region varchar2(10)
);

/*Suppliers table*/
create table Suppliers
(supplier_id varchar2(5) primary key,
supplier_name varchar2(30) Not Null
);

/*Clients table*/
create table Clients
(client_id varchar2(4) primary key,
first_name varchar2(20),
last_name varchar2(20),
address varchar2(250),
email varchar2(50),
phone_number varchar2(12)
);

/*Transactions table*/
create table Transactions
(transaction_id varchar2(8) primary key,
trasaction_date date,
transaction_amount number(7,2),
transaction_type varchar2(20)
);

/*Fact table*/
create table Sales
(sale_id varchar2(8) primary key,
total_sales number(10,2), /*total_sale = quantity*sales_price*/
quantity number(6,0),
product_id varchar2(6),
supplier_id varchar2(5),
channel_id varchar2(3),
client_id varchar2(4),
transaction_id varchar2(8),
constraint sales_product_fk foreign key (product_id) REFERENCES products(product_id),
constraint sales_supplier_fk foreign key (supplier_id) REFERENCES suppliers(supplier_id),
constraint sales_client_fk foreign key (client_id) REFERENCES clients(client_id),
constraint sales_channel_fk foreign key (channel_id) REFERENCES channels(channel_id),
constraint sales_transaction_fk foreign key (transaction_id) REFERENCES transactions(transaction_id)
);