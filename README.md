# Movies Rental Analysis
## Tools
![Python](https://img.icons8.com/color/24/000000/python.png) Python  
![SQL](https://img.icons8.com/fluency/24/000000/sql.png) SQL  
![Jupyter](https://img.icons8.com/color/24/000000/jupyter.png) Jupyter Notebook

## Data Source
The data is a database file in tar format. The data is loaded into postgres using pgadmin 

## Data ERD
<img src="dvd_rental_database_diagram.png">

## Data Dimension
The diagram shows several key entities:

- Film - Contains movie information like title, description, release year, language, rental duration, rental rate, length, rating, and special features
- Category - Film categories/genres
- Inventory - Physical DVD copies available for rent
- Rental - Rental transactions linking customers to specific inventory items
- Customer - Customer information including personal details and address
- Payment - Payment records for rentals
- Staff - Employee information
- Store - Store locations
- Actor - Actor information
- Address - Address details for customers and staff
- City - City information
- Country - Country information
- Language - Language options for films

## Exploratory Analysis

- The database has 16044 rental transaction which start from 2005-05-24 22:53:30 to 2006-02-14 15:16:03 which total 599 customers
- The data span for 2 year from 2005 to 2006 but rentals are recorded for only a month in 2006 and 4 months in 2005
- From the rental and payment table, 1452 rentals payment where not recorded