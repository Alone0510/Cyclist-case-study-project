WITH 
year_data AS 
(
select *
from manish..Divvy_Trips_2019_Q2$
union all
select *
from  manish..Divvy_Trips_2019_Q3$
union all
select *
from manish..Divvy_Trips_2019_Q4$
union all
select *
from manish..Divvy_Trips_2019_Q1$
),
null_cleaned AS
(
select *
from year_data
where [03 - Rental Start Station Name] IS NOT NULL AND [02 - Rental End Station Name]IS NOT NULL
),
aggre_data AS
(
select *,DATENAME(dw,[01 - Rental Details Local Start Time]) as Week_day,
DATEDIFF(minute,[01 - Rental Details Local Start Time],[01 - Rental Details Local End Time]) as total_minutes
from null_cleaned
),
clean_ride_id_data AS
(
select *
from aggre_data
where total_minutes >= 1
),
cstart_station_name_data AS
(
select [01 - Rental Details Rental ID],
TRIM(replace(replace([03 - Rental Start Station Name],'(*)',''),'(Temp)','')) AS start_staion_name
from clean_ride_id_data
where [03 - Rental Start Station Name] NOT LIKE '%(LBH-WH-TEST)%'
),
cend_station_name_data AS
(
select [01 - Rental Details Rental ID],
TRIM(replace(replace([02 - Rental End Station Name],'(*)',''),'(Temp)','')) AS end_staion_name
from clean_ride_id_data
where [02 - Rental End Station Name] NOT LIKE '%(LBH-WH-TEST)%'
),
station_name AS
(
select ss.[01 - Rental Details Rental ID],ss.start_staion_name, es.end_staion_name
from cstart_station_name_data ss
join cend_station_name_data es
on ss.[01 - Rental Details Rental ID]=es.[01 - Rental Details Rental ID]
),
final_table AS
(
select sn.[01 - Rental Details Rental ID], crid.[01 - Rental Details Bike ID], crid.[user type],crid.week_day,
CAST([01 - Rental Details Local Start Time] AS date) AS date_of_year, crid.[01 - Rental Details Local End Time], crid.total_minutes,
sn.start_staion_name, sn.end_staion_name
from clean_ride_id_data crid
join station_name sn
on crid.[01 - Rental Details Rental ID]= sn.[01 - Rental Details Rental ID]
),
number_of_Customers AS
(select COUNT([User Type]) as casual, start_staion_name
from final_table
where [User Type]='Customer'
group by start_staion_name
),
number_of_Subscribers AS
(
select COUNT([User Type]) as Member, start_staion_name
from final_table
where [User Type]='Subscriber'
group by start_staion_name
),
Depart_station AS
(
Select 
cs.start_staion_name ,cs.casual,sb.Member
from number_of_Customers cs
join number_of_Subscribers sb
on cs.start_staion_name = sb.start_staion_name
),
number_of_Customers_arrive AS
(select COUNT([User Type]) as casual, end_staion_name
from final_table
where [User Type]='Customer'
group by end_staion_name
),
number_of_Subscribers_arrive AS
(
select COUNT([User Type]) as Member, end_staion_name
from final_table
where [User Type]='Subscriber'
group by end_staion_name
),
Arrival_station AS
(
Select 
csa.end_staion_name ,csa.casual,sba.Member
from number_of_Customers_arrive csa
join number_of_Subscribers_arrive sba
on csa.end_staion_name = sba.end_staion_name
),
week_day_casual AS
(select COUNT([User Type]) as casual, Week_day
from final_table
where [User Type]='Customer'
group by Week_day),
week_day_member AS
( select COUNT([User Type]) as member, Week_day
from final_table
where [User Type]='Subscriber'
group by Week_day),
week_day_trips AS
( select wc.Week_day,wc.casual,wm.member
from week_day_casual wc
join week_day_member wm
on wc.Week_day = wm.Week_day),
avg_min_casual AS
( select AVG(total_minutes) as avg_casual
from final_table
where [User Type]= 'Customer'
),
avg_min_member AS
( select AVG(total_minutes) as avg_member
from final_table
where [User Type]= 'Subscriber'
),
total_trips_casual AS
( select date_of_year, COUNT([User Type]) as casual
from final_table
where [User Type]='Customer'
group by date_of_year),
total_trips_member AS
( select date_of_year, COUNT([User Type]) as member
from final_table
where [User Type]='Subscriber'
group by date_of_year),
total_trips AS
(select tc.casual,tc.date_of_year,tm.member
from total_trips_casual tc
join total_trips_member tm
on tc.date_of_year = tm.date_of_year
)
